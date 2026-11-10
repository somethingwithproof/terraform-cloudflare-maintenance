provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "maintenance" {
  source = "../../"

  cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id

  # Enable maintenance mode only for specific paths
  worker_route = "example.com/api/*"

  # Toggle maintenance mode based on environment
  enabled = var.environment == "production" ? false : true

  # Custom maintenance page content
  maintenance_title = "Scheduled System Maintenance"
  contact_email     = "support@example.com"

  # Allow internal IPs and monitoring services to bypass maintenance
  allowed_ips = concat(var.office_ip_ranges, var.monitoring_ips)

  # Schedule maintenance window
  maintenance_window = {
    start_time = var.maintenance_start_time
    end_time   = var.maintenance_end_time
  }

  # Custom styling
  custom_css = file("${path.module}/custom-styles.css")
  logo_url   = "https://example.com/logo-large.png"
}

# Notify the monitoring system whenever the maintenance status or window changes
module "maintenance_notifications" {
  source = "../../modules/notifications"

  notification_urls = var.monitoring_webhook_url == "" ? {} : {
    monitoring = "webhook://${var.monitoring_webhook_url}"
  }

  maintenance_status = module.maintenance.maintenance_status
  schedule_name      = "advanced-config"
  environment        = var.environment
  maintenance_window = module.maintenance.maintenance_window
}
