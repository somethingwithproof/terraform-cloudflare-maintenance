# Main Terraform configuration for Cloudflare maintenance mode

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  worker_vars = {
    enabled           = var.enabled
    maintenance_title = var.maintenance_title
    contact_email     = var.contact_email
    allowed_ips       = jsonencode(var.allowed_ips)
    maintenance_window = var.maintenance_window != null ? jsonencode({
      start_time = var.maintenance_window.start_time
      end_time   = var.maintenance_window.end_time
    }) : "null"
    custom_css = var.custom_css
    logo_url   = var.logo_url
  }
}

data "external" "bundle_worker" {
  program = ["${path.module}/worker/build.sh"]

  # Trigger rebuild when worker source changes
  depends_on = [
    local_file.worker_config
  ]
}

resource "local_file" "worker_config" {
  filename = "${path.module}/worker/src/config.json"
  content  = jsonencode(local.worker_vars)
}

resource "cloudflare_worker_script" "maintenance" {
  name       = "maintenance-page-worker"
  account_id = var.cloudflare_account_id
  content    = data.external.bundle_worker.result["script"]

  # Add KV namespace binding if needed
  # kv_namespace_binding {
  #   name         = "MAINTENANCE_CONFIG"
  #   namespace_id = cloudflare_workers_kv_namespace.maintenance_config[0].id
  # }

  # Add secret variables
  secret_text_binding {
    name = "ALLOWED_IPS"
    text = jsonencode(var.allowed_ips)
  }

  # Add analytics
  analytics_engine_binding {
    name    = "MAINTENANCE_ANALYTICS"
    dataset = "maintenance_events"
  }
}

resource "cloudflare_worker_route" "maintenance_route" {
  count       = var.enabled ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  pattern     = var.worker_route
  script_name = cloudflare_worker_script.maintenance.name
}

# Optional: Create a KV namespace for configuration
resource "cloudflare_workers_kv_namespace" "maintenance_config" {
  count      = var.enabled ? 1 : 0
  account_id = var.cloudflare_account_id
  title      = "maintenance_config"
}

# Optional: Create a custom hostname for the maintenance page
resource "cloudflare_record" "maintenance" {
  count   = var.enabled ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "maintenance"
  value   = "100::" # IPv6 placeholder for Worker routes
  type    = "AAAA"
  proxied = true
  ttl     = 1 # Auto
  comment = "Maintenance page DNS record"
}

# Optional: Create a firewall rule to bypass maintenance for allowed IPs
resource "cloudflare_filter" "maintenance_bypass" {
  count       = var.enabled && length(var.allowed_ips) > 0 ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  description = "Filter for IPs allowed to bypass maintenance"
  expression  = join(" or ", [for ip in var.allowed_ips : "(ip.src eq ${ip})"])
}

resource "cloudflare_firewall_rule" "maintenance_bypass" {
  count       = var.enabled && length(var.allowed_ips) > 0 ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  description = "Allow specific IPs to bypass maintenance"
  filter_id   = cloudflare_filter.maintenance_bypass[0].id
  action      = "bypass"
  priority    = 1
}
