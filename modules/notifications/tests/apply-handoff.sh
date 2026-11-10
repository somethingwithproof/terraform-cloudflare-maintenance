#!/usr/bin/env bash
# Applies the notifications module for real, with a stub curl on PATH, and
# checks the PagerDuty events across a change of environment: the incident
# opened under the old dedup key must be resolved before the new one is
# triggered. This exercises the destroy-then-create handoff that a plan-only
# tofu test cannot reach. Then scripts/maintenance, with the module's
# environment and schedule name, must settle the apply's incident under the
# same key: off resolves it, on reopens it and schedule resolves it again.
# Nothing leaves the machine. Needs tofu and jq.
set -euo pipefail

module_dir=$(cd "$(dirname "$0")/.." && pwd)
toggle="$module_dir/../../scripts/maintenance"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/bin"
# scripts/maintenance's KV calls ask for the status with -w; answer 200 and
# record only the notification bodies.
cat >"$work/bin/curl" <<'STUB'
#!/bin/sh
for arg in "$@"; do
  [ "$arg" = -w ] && printf 200 && exit 0
done
prev=
for arg in "$@"; do
  [ "$prev" = "--data-binary" ] && jq -c '[.event_action, .dedup_key]' "${arg#@}" >>"$EVENTS"
  prev=$arg
done
STUB
chmod +x "$work/bin/curl"

cat >"$work/main.tf" <<EOF
variable "environment" { type = string }
variable "status" { type = string }
module "notify" {
  source             = "$module_dir"
  notification_urls  = { oncall = "pagerduty://test-routing-key" }
  maintenance_status = var.status
  schedule_name      = "weekly"
  environment        = var.environment
}
EOF

export EVENTS="$work/events" PATH="$work/bin:$PATH" TF_IN_AUTOMATION=1
apply() {
  tofu -chdir="$work" apply -auto-approve -input=false -no-color \
    -var "environment=$1" -var "status=$2" >/dev/null
}

tofu -chdir="$work" init -input=false -no-color >/dev/null
apply staging ENABLED
apply production ENABLED
apply production SCHEDULED
apply production ENABLED

maintenance() {
  CF_KV_API_TOKEN=test CF_ACCOUNT_ID=0123456789abcdef0123456789abcdef \
    KV_NAMESPACE_ID=fedcba9876543210fedcba9876543210 \
    NOTIFY_URL=pagerduty://test-routing-key NOTIFY_ENVIRONMENT=production \
    NOTIFY_SCHEDULE=weekly "$toggle" "$@" >/dev/null
}
maintenance off
maintenance on
maintenance schedule 2030-04-06T08:00:00Z 2030-04-06T10:00:00Z

expected='["trigger","terraform-cloudflare-maintenance/staging/weekly"]
["resolve","terraform-cloudflare-maintenance/staging/weekly"]
["trigger","terraform-cloudflare-maintenance/production/weekly"]
["resolve","terraform-cloudflare-maintenance/production/weekly"]
["trigger","terraform-cloudflare-maintenance/production/weekly"]
["resolve","terraform-cloudflare-maintenance/production/weekly"]
["trigger","terraform-cloudflare-maintenance/production/weekly"]
["resolve","terraform-cloudflare-maintenance/production/weekly"]'
actual=$(cat "$EVENTS")
if [[ "$actual" != "$expected" ]]; then
  printf 'unexpected PagerDuty events:\n%s\nexpected:\n%s\n' "$actual" "$expected" >&2
  exit 1
fi
echo "apply-handoff: 8 PagerDuty events as expected"
