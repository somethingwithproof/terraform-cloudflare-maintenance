# Scheduled Maintenance Example

This example demonstrates how to use the Terraform Cloudflare Maintenance module with scheduled maintenance windows and notifications.

## Features Demonstrated

- ✅ Time-based maintenance windows with RFC3339 timestamps
- ✅ Custom branding with CSS and logos
- ✅ IP and region-based bypass for testing
- ✅ Notification integrations (Slack, PagerDuty, webhooks)
- ✅ Cron-based scheduling configuration (for reference)
- ✅ Environment-aware configuration

## Prerequisites

- Cloudflare account with Workers enabled
- Cloudflare API token with appropriate permissions
- (Optional) Slack webhook URL for notifications
- (Optional) PagerDuty routing key for incident management

## Usage

1. Copy the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your values:

```hcl
cloudflare_api_token  = "your-api-token"
cloudflare_account_id = "your-account-id"
cloudflare_zone_id    = "your-zone-id"
environment           = "production"

# Optional: Enable notifications
enable_notifications  = true
slack_webhook_url     = "slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"
pagerduty_routing_key = "pagerduty://your-routing-key"
```

3. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

## Scheduled Maintenance Windows

The example includes a `schedules` variable that demonstrates cron-based scheduling:

```hcl
schedules = [
  {
    name     = "weekly-maintenance"
    cron     = "0 2 * * SUN"        # Every Sunday at 2 AM
    duration = "2h"                   # 2 hours duration
    timezone = "America/Los_Angeles"
    notify   = ["slack://webhook"]
  }
]
```

### Cron Expression Format

```
 ┌───────────── minute (0 - 59)
 │ ┌───────────── hour (0 - 23)
 │ │ ┌───────────── day of month (1 - 31)
 │ │ │ ┌───────────── month (1 - 12)
 │ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
 │ │ │ │ │
 * * * * *
```

### Common Cron Examples

- `0 2 * * SUN` - Every Sunday at 2 AM
- `0 3 1 * *` - First day of every month at 3 AM
- `0 0 * * 0,6` - Every Saturday and Sunday at midnight
- `30 4 * * 1-5` - Weekdays at 4:30 AM

## Notifications

The module supports multiple notification channels:

### Slack

```hcl
slack_webhook_url = "slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"
```

### PagerDuty

```hcl
pagerduty_routing_key = "pagerduty://your-routing-key"
```

### Generic Webhook

```hcl
notification_urls = ["webhook://https://example.com/webhook"]
```

## Testing

Test the maintenance page by:

1. Accessing your domain from a non-allowed IP
2. Checking the maintenance status page at `https://maintenance-status-{environment}.{domain}`
3. Verifying notifications are sent (if configured)

## Cleanup

```bash
terraform destroy
```

## Notes

- The `schedules` variable is for documentation and future automation
- Currently, maintenance windows are activated manually via the `enabled` variable
- For CI/CD integration, consider using Terraform Cloud run triggers
- Time-based windows use the `maintenance_window` variable with RFC3339 timestamps
