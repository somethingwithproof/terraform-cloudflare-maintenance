#!/usr/bin/env bash
# Turns a GitHub environment's deploy settings into TF_VAR_ lines in
# GITHUB_ENV for the deploy/ root, failing on anything missing or malformed
# before tofu init, so a run can never fall back to local state or apply
# half its settings. Used by cd.yml (deploy) and drift.yml (plan).
#
# Required: TF_CLOUD_ORGANIZATION, TF_TOKEN_app_terraform_io,
#   CLOUDFLARE_API_TOKEN, TF_VAR_cloudflare_account_id,
#   TF_VAR_cloudflare_zone_id, TF_VAR_worker_route.
# Environment variables: ENV_ENABLED, ENV_WINDOW (JSON), ENV_ALLOWED_IPS and
#   ENV_ALLOWED_REGIONS (JSON arrays), ENV_CONTACT_EMAIL, ENV_RUNTIME_TOGGLE.
# One-run overrides (cd.yml dispatch): INPUT_ENABLED (environment, true or
#   false), INPUT_WINDOW_START and INPUT_WINDOW_END, INPUT_CLEAR_WINDOW.
# DEPLOY_SETTINGS_MODE=plan reports missing required settings as a notice
#   and ready=false in GITHUB_OUTPUT instead of failing.
set -euo pipefail

missing=()
for name in TF_CLOUD_ORGANIZATION TF_TOKEN_app_terraform_io \
  CLOUDFLARE_API_TOKEN TF_VAR_cloudflare_account_id \
  TF_VAR_cloudflare_zone_id TF_VAR_worker_route; do
  [[ -n "${!name:-}" ]] || missing+=("$name")
done
if (( ${#missing[@]} )); then
  if [[ "${DEPLOY_SETTINGS_MODE:-deploy}" == plan ]]; then
    echo "::notice::Skipped: not configured for HCP Terraform; missing: ${missing[*]}."
    echo "ready=false" >> "$GITHUB_OUTPUT"
    exit 0
  fi
  echo "::error::Not configured for HCP Terraform deploys; missing: ${missing[*]}. Set the variables and environment secrets described in the README."
  exit 1
fi

fail() { echo "::error::$1"; exit 1; }
# setvar NAME VALUE: exports a TF_VAR_ for the plan. jq -c makes
# it one line, so nothing else can be written to GITHUB_ENV.
setvar() { printf 'TF_VAR_%s=%s\n' "$1" "$2" >> "$GITHUB_ENV"; }

enabled=${ENV_ENABLED:-false}
[[ "${INPUT_ENABLED:-environment}" == environment ]] || enabled=$INPUT_ENABLED
[[ "$enabled" == true || "$enabled" == false ]] ||
  fail "MAINTENANCE_ENABLED must be true or false."
setvar enabled "$enabled"

rfc3339='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})$'
window=${ENV_WINDOW:-}
INPUT_WINDOW_START=${INPUT_WINDOW_START:-} INPUT_WINDOW_END=${INPUT_WINDOW_END:-}
if [[ "${INPUT_CLEAR_WINDOW:-false}" == true ]]; then
  window=
elif [[ -n "$INPUT_WINDOW_START" || -n "$INPUT_WINDOW_END" ]]; then
  [[ "$INPUT_WINDOW_START" =~ $rfc3339 && "$INPUT_WINDOW_END" =~ $rfc3339 ]] ||
    fail "Set both window_start and window_end as RFC3339 times, or neither."
  window=$(jq -cn --arg s "$INPUT_WINDOW_START" --arg e "$INPUT_WINDOW_END" '{start_time: $s, end_time: $e}')
fi
if [[ -n "$window" ]]; then
  window=$(jq -ce 'select(type == "object" and (.start_time | type) == "string" and (.end_time | type) == "string") | {start_time, end_time}' <<<"$window") ||
    fail 'MAINTENANCE_WINDOW must be a JSON object {"start_time": "...", "end_time": "..."}.'
  setvar maintenance_window "$window"
fi

# setlist TFVAR NAME VALUE: a JSON array of strings, if set.
setlist() {
  [[ -n "$3" ]] || return 0
  local list
  list=$(jq -ce 'select(type == "array" and all(.[]; type == "string"))' <<<"$3") ||
    fail "$2 must be a JSON array of strings."
  setvar "$1" "$list"
}
setlist allowed_ips ALLOWED_IPS "${ENV_ALLOWED_IPS:-}"
setlist allowed_regions ALLOWED_REGIONS "${ENV_ALLOWED_REGIONS:-}"

runtime_toggle=${ENV_RUNTIME_TOGGLE:-false}
[[ "$runtime_toggle" == true || "$runtime_toggle" == false ]] ||
  fail "RUNTIME_TOGGLE must be true or false."
setvar runtime_toggle "$runtime_toggle"

if [[ -n "${ENV_CONTACT_EMAIL:-}" ]]; then
  [[ "$ENV_CONTACT_EMAIL" != *$'\n'* ]] || fail "CONTACT_EMAIL must be one line."
  setvar contact_email "$ENV_CONTACT_EMAIL"
fi

echo "ready=true" >> "$GITHUB_OUTPUT"
