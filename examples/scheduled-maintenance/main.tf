provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Example: Scheduled maintenance with notifications
module "maintenance" {
  source = "../../"

  cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id

  # Environment configuration
  environment = var.environment

  # Worker route configuration
  worker_route = "example.com/*"

  # Enable maintenance mode
  enabled = true

  # Scheduled maintenance window
  maintenance_window = {
    start_time = "2025-04-06T08:00:00Z"
    end_time   = "2025-04-06T10:00:00Z"
  }

  # Custom maintenance page
  maintenance_title   = "Scheduled System Maintenance"
  maintenance_message = "We are performing scheduled maintenance to improve our services. We will be back shortly."
  contact_email       = "support@example.com"

  # Custom branding
  custom_css = <<-CSS
    body {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    .container {
      background: white;
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    }
  CSS

  logo_url = "https://example.com/logo.png"

  # Allow bypass for specific IPs and regions
  allowed_ips     = ["192.168.1.100", "10.0.0.1"]
  allowed_regions = ["US", "CA"]

  # Support for cron-based schedules (for documentation purposes)
  schedules = [
    {
      name     = "weekly-maintenance"
      cron     = "0 2 * * SUN"
      duration = "2h"
      timezone = "America/Los_Angeles"
      notify   = ["slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"]
    },
    {
      name     = "monthly-patching"
      cron     = "0 3 1 * *"
      duration = "4h"
      timezone = "UTC"
      notify   = ["pagerduty://your-routing-key", "webhook://https://example.com/webhook"]
    }
  ]
}

# Optional: Send notifications about the maintenance window
module "maintenance_notifications" {
  source = "../../modules/notifications"
  count  = var.enable_notifications ? 1 : 0

  # Filter out empty notification URLs
  notification_urls = compact([
    var.slack_webhook_url,
    var.pagerduty_routing_key,
  ])

  maintenance_status = module.maintenance.maintenance_status
  schedule_name      = "scheduled-maintenance"
  environment        = var.environment

  maintenance_window = {
    start_time = "2025-04-06T08:00:00Z"
    end_time   = "2025-04-06T10:00:00Z"
  }
}

# Output maintenance information
output "maintenance_status" {
  description = "Current maintenance status"
  value       = module.maintenance.maintenance_status
}

output "maintenance_page_url" {
  description = "URL to the maintenance status page"
  value       = module.maintenance.maintenance_page_url
}

output "worker_id" {
  description = "Cloudflare Worker ID"
  value       = module.maintenance.worker_id
}

output "notification_count" {
  description = "Number of configured notifications"
  value       = var.enable_notifications ? module.maintenance_notifications[0].notification_count : 0
}
