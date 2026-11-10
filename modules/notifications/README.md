# Notification Module

Sends a maintenance notification to Slack, PagerDuty or a generic HTTPS
webhook from a `local-exec` provisioner. A notification goes out when an apply
creates the module or changes the status, schedule name, environment or window;
an apply that changes none of them sends nothing.

The machine running `tofu apply` needs `/bin/sh`, `curl` and `jq`.

## Usage

```hcl
module "maintenance_notifications" {
  source = "github.com/somethingwithproof/terraform-cloudflare-maintenance//modules/notifications"

  # Keys are non-secret names; values are secrets.
  notification_urls = {
    ops_slack = var.slack_webhook_url     # slack://T000/B000/XXXX
    oncall    = var.pagerduty_routing_key # pagerduty://<routing key>
  }

  maintenance_status = module.maintenance.maintenance_status
  schedule_name      = "weekly-maintenance"
  environment        = "production"
  maintenance_window = module.maintenance.maintenance_window
}
```

## Secrets

`notification_urls` is sensitive. Its keys key the `terraform_data` resources
and appear in plans and state, so keep them non-secret. The URLs and routing
keys never reach the state, the plan or a command line: the provisioner passes
them to `notify.sh` in its environment, and curl reads the target URL from a
config on stdin and the body from a private temporary file. Because the
provisioner's environment is sensitive, OpenTofu suppresses its output; a
failed delivery still fails the apply.

## Notification URL Formats

| Type | Format | Sent to |
|------|--------|---------|
| Slack | `slack://T000/B000/XXXX` | `https://hooks.slack.com/services/T000/B000/XXXX` |
| PagerDuty | `pagerduty://<routing key>` | PagerDuty Events API v2 |
| Webhook | `webhook://https://example.com/hook` | that URL; HTTPS only |

Requests use `curl -fsS --max-time 10 --retry 2`, so an HTTP error or timeout
fails the apply.

## PagerDuty incidents

| Status | PagerDuty | Slack and webhooks |
|--------|-----------|--------------------|
| `ENABLED`, `STARTING`, `ACTIVE`, `ENDING` | `trigger` | message |
| `DISABLED`, `COMPLETED` | `resolve` | message |
| `SCHEDULED` | nothing | message |

Events use the dedup key
`terraform-cloudflare-maintenance/<environment>/<schedule_name>` (the
`dedup_key` output), so ending maintenance resolves the incident that starting
it opened. A window that has not started pages nobody.

When `schedule_name` or `environment` changes while an incident is open, or
the status changes from a triggering one to `SCHEDULED`, the old incident is
resolved under its old key before anything new is sent. Each notification
keeps the key it announced in its `terraform_data` input; when an apply
replaces it, the destroy-time provisioner writes that key to
`.terraform/maintenance-notifications/` in the root module, and the
replacement resolves it once it has delivered. The file holds no secrets and
is removed after a successful delivery; a failed delivery keeps it, so the
retry still resolves. Removing a target or destroying the module while an
incident is open leaves that incident open: set the status to `DISABLED` and
apply first.

Notifications only go out on apply. Nothing applies when a scheduled window
opens or closes, so the module cannot trigger at the start of a window or
resolve at its end. To page for a window, set the status to `ACTIVE` (or
`ENABLED`) and apply when it starts, and `COMPLETED` when it ends, or use the
runtime toggle in `scripts/maintenance`, which sends the same events under the
same key.

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| notification_urls | Map of non-secret name to secret notification URL | `map(string)` (sensitive) | no |
| maintenance_status | ENABLED, SCHEDULED, STARTING, ACTIVE, ENDING, COMPLETED or DISABLED | `string` | yes |
| schedule_name | Name of the maintenance schedule | `string` | yes |
| environment | Environment name | `string` | yes |
| maintenance_window | Start and end times, or `null` | `object({start_time=string, end_time=string})` | no |

## Outputs

| Name | Description |
|------|-------------|
| notification_count | Number of notification targets configured |
| notification_types | Map of target name to slack, pagerduty or webhook |
| event_action | PagerDuty event action for the status: trigger, resolve or none |
| dedup_key | PagerDuty dedup key for the environment and schedule |

## Testing

```bash
tofu init -backend=false && tofu test   # in this directory; plans only
cd ../../tests && npx vitest run unit/notify.test.js   # runs notify.sh with a stub curl
tests/apply-handoff.sh   # real applies with a stub curl; checks the incident handoff
```
