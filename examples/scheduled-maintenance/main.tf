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

  # The window alone schedules maintenance: the route is deployed now and the
  # Worker serves the page only between start_time and end_time.
  enabled            = false
  maintenance_window = var.maintenance_window

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
}

# Optional: Send notifications about the maintenance window
module "maintenance_notifications" {
  source = "../../modules/notifications"
  count  = var.enable_notifications ? 1 : 0

  # Keys are non-secret names; empty URLs are left out.
  notification_urls = {
    for name, url in {
      slack     = var.slack_webhook_url
      pagerduty = var.pagerduty_routing_key
    } : name => url if url != ""
  }

  maintenance_status = module.maintenance.maintenance_status
  schedule_name      = "scheduled-maintenance"
  environment        = var.environment
  maintenance_window = module.maintenance.maintenance_window
}

# Output maintenance information
output "maintenance_status" {
  description = "Current maintenance status"
  value       = module.maintenance.maintenance_status
}

output "worker_id" {
  description = "Cloudflare Worker ID"
  value       = module.maintenance.worker_id
}

output "notification_count" {
  description = "Number of configured notifications"
  value       = var.enable_notifications ? module.maintenance_notifications[0].notification_count : 0
}
