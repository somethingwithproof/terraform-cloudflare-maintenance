# Scheduled Maintenance Example

This example demonstrates how to use the Terraform Cloudflare Maintenance module with scheduled maintenance windows and notifications.

## Features Demonstrated

- ✅ Time-based maintenance windows with RFC3339 timestamps
- ✅ Custom branding with CSS and logos
- ✅ IP and region-based bypass for testing
- ✅ Notification integrations (Slack, PagerDuty, webhooks)
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

maintenance_window = {
  start_time = "2030-04-06T08:00:00Z"
  end_time   = "2030-04-06T10:00:00Z"
}

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

`maintenance_window` schedules a single window. With a window set, the module
deploys the Worker route on the next apply even though `enabled` is `false`.
The Worker then checks the time on every request: it serves the maintenance
page from `start_time` (inclusive) to `end_time` (exclusive) and passes all
other traffic to the origin. Clients in `allowed_ips` or `allowed_regions`
reach the origin throughout.

After the window ends, remove `maintenance_window` (or set it to `null`) and
apply again to delete the route. Until then the Worker passes every request
through. For recurring maintenance, have a scheduler (for example a CI job)
set the next window and apply.

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

1. Accessing your domain from a non-allowed IP during the window
2. Verifying notifications are sent (if configured)

## Cleanup

```bash
terraform destroy
```

## Notes

- Set `enabled = true` without a window to serve the page immediately until you
  disable it again.
- Notifications are sent when `tofu apply` runs, not when the window starts or
  ends.
