#!/usr/bin/env bash
# Applies the notifications module for real, with a stub curl on PATH, and
# checks the PagerDuty events across a change of environment: the incident
# opened under the old dedup key must be resolved before the new one is
# triggered. This exercises the destroy-then-create handoff that a plan-only
# tofu test cannot reach. Nothing leaves the machine. Needs tofu and jq.
set -euo pipefail

module_dir=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/bin"
cat >"$work/bin/curl" <<'STUB'
#!/bin/sh
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

expected='["trigger","terraform-cloudflare-maintenance/staging/weekly"]
["resolve","terraform-cloudflare-maintenance/staging/weekly"]
["trigger","terraform-cloudflare-maintenance/production/weekly"]
["resolve","terraform-cloudflare-maintenance/production/weekly"]'
actual=$(cat "$EVENTS")
if [[ "$actual" != "$expected" ]]; then
  printf 'unexpected PagerDuty events:\n%s\nexpected:\n%s\n' "$actual" "$expected" >&2
  exit 1
fi
echo "apply-handoff: 4 PagerDuty events as expected"
