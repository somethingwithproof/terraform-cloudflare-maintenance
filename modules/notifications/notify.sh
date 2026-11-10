#!/bin/sh
# Sends one maintenance notification. Run by the local-exec provisioner in
# main.tf. Every input arrives through the environment, so the target URL is
# never part of a command line, a plan or the state: curl reads it from its
# config on stdin and the body from a private temporary file.
set -eu

: "${NOTIFY_URL:?}" "${NOTIFY_STATUS:?}" "${NOTIFY_ACTION:?}" "${NOTIFY_DEDUP_KEY:?}"
schedule=${NOTIFY_SCHEDULE:-}
environment=${NOTIFY_ENVIRONMENT:-}
start=${NOTIFY_START:-}
end=${NOTIFY_END:-}

body=$(mktemp)
trap 'rm -f "$body"' EXIT

case "$NOTIFY_URL" in
slack://*)
  url="https://hooks.slack.com/services/${NOTIFY_URL#slack://}"
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
  ;;
pagerduty://*)
  url="https://events.pagerduty.com/v2/enqueue"
  jq -n --arg key "${NOTIFY_URL#pagerduty://}" --arg action "$NOTIFY_ACTION" \
    --arg dedup "$NOTIFY_DEDUP_KEY" --arg status "$NOTIFY_STATUS" \
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
  ;;
webhook://https://*)
  url="${NOTIFY_URL#webhook://}"
  jq -n --arg status "$NOTIFY_STATUS" --arg schedule "$schedule" \
    --arg environment "$environment" --arg start "$start" --arg end "$end" '{
      status: $status, schedule_name: $schedule, environment: $environment,
      maintenance_window: {start_time: $start, end_time: $end}
    }' >"$body"
  ;;
*)
  echo "notify.sh: unsupported notification URL scheme" >&2
  exit 1
  ;;
esac

printf 'url = "%s"\n' "$url" |
  curl --config - -fsS --max-time 10 --retry 2 -o /dev/null \
    -X POST -H 'Content-Type: application/json' --data-binary "@$body"
