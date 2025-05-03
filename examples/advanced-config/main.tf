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

# Create a DNS record for direct access to maintenance page
resource "cloudflare_record" "maintenance_status" {
  zone_id = var.cloudflare_zone_id
  name    = "status"
  value   = "100::" # IPv6 placeholder for Worker routes
  type    = "AAAA"
  proxied = true
  ttl     = 1
}

# Create a Page Rule to bypass cache during maintenance
resource "cloudflare_page_rule" "maintenance_bypass_cache" {
  zone_id  = var.cloudflare_zone_id
  target   = "example.com/*"
  priority = 1

  actions {
    cache_level = "bypass"
  }

  status = module.maintenance.maintenance_status == "ENABLED" ? "active" : "disabled"
}

# Notify monitoring system about maintenance window
resource "null_resource" "maintenance_notification" {
  count = var.environment == "production" && module.maintenance.maintenance_status == "ENABLED" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST \
        -H "Content-Type: application/json" \
        -d '{"status": "maintenance", "start_time": "${var.maintenance_start_time}", "end_time": "${var.maintenance_end_time}"}' \
        ${var.monitoring_webhook_url}
    EOT
  }
}
