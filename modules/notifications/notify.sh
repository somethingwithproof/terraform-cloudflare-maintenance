#!/bin/sh
# Sends one maintenance notification. Run by the local-exec provisioners in
# main.tf and by scripts/maintenance. Every input arrives through the
# environment, so the target URL is never part of a command line, a plan or
# the state: curl reads it from its config on stdin and the body from a
# private temporary file.
#
# NOTIFY_ACTION is the PagerDuty event action: trigger, resolve or none.
# none (a scheduled window that has not started) sends Slack and webhook
# targets an informational message and PagerDuty nothing.
#
# NOTIFY_STATE_FILE, when set, carries the PagerDuty incident across a
# replacement. With NOTIFY_MODE=record (the destroy-time provisioner) the
# script only writes the outgoing dedup key and action there. On the next
# send, a previously triggered incident is resolved under its old key when
# the key changed (new schedule name or environment) or nothing is
# triggered any more. The file holds no secrets.
set -eu

: "${NOTIFY_ACTION:?}" "${NOTIFY_DEDUP_KEY:?}"
state_file=${NOTIFY_STATE_FILE:-}

case "$NOTIFY_ACTION" in
trigger | resolve | none) ;;
*)
  echo "notify.sh: NOTIFY_ACTION must be trigger, resolve or none" >&2
  exit 1
  ;;
esac

if [ "${NOTIFY_MODE:-send}" = record ]; then
  [ -n "$state_file" ] || exit 0
  mkdir -p "$(dirname "$state_file")"
  jq -n --arg key "$NOTIFY_DEDUP_KEY" --arg action "$NOTIFY_ACTION" \
    '{dedup_key: $key, action: $action}' >"$state_file"
  exit 0
fi

: "${NOTIFY_URL:?}" "${NOTIFY_STATUS:?}"

# The URL ends up in a quoted curl config line (see post), where whitespace,
# a quote or a backslash could end the value or add options. The module's
# variable validation rejects them on the apply path; this check covers
# every caller, scripts/maintenance included.
case "$NOTIFY_URL" in
*[[:space:][:cntrl:]\"\\]*)
  echo "notify.sh: the notification URL must not contain whitespace, control characters, quotes or backslashes" >&2
  exit 1
  ;;
slack://?* | pagerduty://?* | webhook://https://?*) ;;
*)
  echo "notify.sh: unsupported notification URL scheme" >&2
  exit 1
  ;;
esac

schedule=${NOTIFY_SCHEDULE:-}
environment=${NOTIFY_ENVIRONMENT:-}
start=${NOTIFY_START:-}
end=${NOTIFY_END:-}

body=$(mktemp)
trap 'rm -f "$body"' EXIT

# post URL: sends $body to URL without putting URL on a command line.
post() {
  printf 'url = "%s"\n' "$1" |
    curl --config - -fsS --max-time 10 --retry 2 -o /dev/null \
      -X POST -H 'Content-Type: application/json' --data-binary "@$body"
}

# pagerduty_event ACTION DEDUP_KEY: writes a PagerDuty Events v2 body.
pagerduty_event() {
  jq -n --arg key "${NOTIFY_URL#pagerduty://}" --arg action "$1" \
    --arg dedup "$2" --arg status "$NOTIFY_STATUS" \
    --arg schedule "$schedule" --arg environment "$environment" \
    --arg start "$start" --arg end "$end" '
    {routing_key: $key, event_action: $action, dedup_key: $dedup}
    + if $action == "trigger" then {payload: {
        summary: "Maintenance \($status): \($schedule)",
        severity: "warning",
        source: "terraform-cloudflare-maintenance",
        custom_details: {status: $status, environment: $environment,
          schedule: $schedule, start_time: $start, end_time: $end}
      }} else {} end' >"$body"
}

case "$NOTIFY_URL" in
slack://*)
  jq -n --arg status "$NOTIFY_STATUS" --arg schedule "$schedule" \
    --arg environment "$environment" --arg window "$start - $end" '{
      text: "Maintenance \($status)",
      blocks: [
        {type: "header", text: {type: "plain_text", text: "Maintenance \($status): \($schedule)"}},
        {type: "section", fields: [
          {type: "mrkdwn", text: "*Status:*\n\($status)"},
          {type: "mrkdwn", text: "*Window:*\n\($window)"},
          {type: "mrkdwn", text: "*Environment:*\n\($environment)"},
          {type: "mrkdwn", text: "*Schedule:*\n\($schedule)"}
        ]}
      ]
    }' >"$body"
  post "https://hooks.slack.com/services/${NOTIFY_URL#slack://}"
  ;;
pagerduty://*)
  url="https://events.pagerduty.com/v2/enqueue"
  if [ -n "$state_file" ] && [ -f "$state_file" ]; then
    previous_key=$(jq -r '.dedup_key // ""' "$state_file")
    previous_action=$(jq -r '.action // ""' "$state_file")
    if [ "$previous_action" = trigger ] &&
      { [ "$previous_key" != "$NOTIFY_DEDUP_KEY" ] || [ "$NOTIFY_ACTION" = none ]; }; then
      pagerduty_event resolve "$previous_key"
      post "$url"
    fi
  fi
  if [ "$NOTIFY_ACTION" != none ]; then
    pagerduty_event "$NOTIFY_ACTION" "$NOTIFY_DEDUP_KEY"
    post "$url"
  fi
  ;;
webhook://https://*)
  jq -n --arg status "$NOTIFY_STATUS" --arg schedule "$schedule" \
    --arg environment "$environment" --arg start "$start" --arg end "$end" '{
      status: $status, schedule_name: $schedule, environment: $environment,
      maintenance_window: {start_time: $start, end_time: $end}
    }' >"$body"
  post "${NOTIFY_URL#webhook://}"
  ;;
esac

# Delivered: the previous incident, if any, is settled.
if [ -n "$state_file" ]; then
  rm -f "$state_file"
fi
