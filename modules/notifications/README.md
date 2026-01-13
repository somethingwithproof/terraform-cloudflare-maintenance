# Notification Module

This module provides notification capabilities for scheduled maintenance windows.

## Supported Notification Types

- **Slack**: Send notifications to Slack channels via webhooks
- **PagerDuty**: Create incidents or events in PagerDuty
- **Generic Webhooks**: Send JSON payloads to any webhook endpoint

## Usage

```hcl
module "maintenance_notifications" {
  source = "./modules/notifications"

  notification_urls = [
    "slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX",
    "pagerduty://your-integration-key",
    "webhook://https://example.com/webhook"
  ]

  maintenance_status = "STARTING"
  schedule_name      = "weekly-maintenance"
  environment        = "production"
  
  maintenance_window = {
    start_time = "2025-04-06T08:00:00Z"
    end_time   = "2025-04-06T10:00:00Z"
  }
}
```

## Notification URL Formats

### Slack
Format: `slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX`

The URL is converted to: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX`

### PagerDuty
Format: `pagerduty://your-routing-key`

Uses the PagerDuty Events API v2 to trigger incidents.

### Generic Webhook
Format: `webhook://https://example.com/webhook`

Sends a JSON payload with maintenance details.

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| notification_urls | List of notification URLs | list(string) | yes |
| maintenance_status | Current maintenance status | string | yes |
| schedule_name | Name of the maintenance schedule | string | yes |
| environment | Environment name | string | yes |
| maintenance_window | Maintenance window with start and end times | object | yes |

## Outputs

| Name | Description |
|------|-------------|
| notification_count | Number of notifications configured |
| notification_types | Types of notifications configured |
