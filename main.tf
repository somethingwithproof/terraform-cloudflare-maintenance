# Main Terraform configuration for Cloudflare maintenance mode

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "random_password" "api_key" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  worker_vars = {
    enabled           = var.enabled
    maintenance_title = var.maintenance_title
    contact_email     = var.contact_email
    allowed_ips       = jsonencode(var.allowed_ips)
    environment       = var.environment
    maintenance_language = var.maintenance_language
    maintenance_window = var.maintenance_window != null ? jsonencode({
      start_time = var.maintenance_window.start_time
      end_time   = var.maintenance_window.end_time
    }) : "null"
    custom_css = var.custom_css
    logo_url   = var.logo_url
    api_key    = var.api_key != "" ? var.api_key : random_password.api_key.result
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

resource "cloudflare_workers_script" "maintenance" {
  script_name = "maintenance-page-worker"
  account_id  = var.cloudflare_account_id
  content     = data.external.bundle_worker.result["script"]

  # Define bindings as a list attribute
  bindings = concat(
    var.enabled ? [{
      name         = "MAINTENANCE_CONFIG"
      namespace_id = cloudflare_workers_kv_namespace.maintenance_config[0].id
      type         = "kv_namespace"
    }] : [],
    [
      {
        name = "ALLOWED_IPS"
        text = jsonencode(var.allowed_ips)
        type = "secret_text"
      },
      {
        name = "API_KEY"
        text = local.worker_vars.api_key
        type = "secret_text"
      },
      {
        name    = "MAINTENANCE_ANALYTICS"
        dataset = "maintenance_events"
        type    = "analytics_engine"
      }
    ]
  )
}

resource "cloudflare_workers_route" "maintenance_route" {
  count   = var.enabled ? 1 : 0
  zone_id = var.cloudflare_zone_id
  pattern = var.worker_route
  script  = cloudflare_workers_script.maintenance.script_name
}

# Optional: Create a KV namespace for configuration
resource "cloudflare_workers_kv_namespace" "maintenance_config" {
  count      = var.enabled ? 1 : 0
  account_id = var.cloudflare_account_id
  title      = "maintenance_config"
}

# Optional: Create a custom hostname for the maintenance page
resource "cloudflare_dns_record" "maintenance" {
  count    = var.enabled ? 1 : 0
  zone_id  = var.cloudflare_zone_id
  name     = "maintenance"
  content  = "100::"  # IPv6 placeholder for Worker routes
  type     = "AAAA"
  proxied  = true
  ttl      = 1        # Auto
  comment  = "Maintenance page DNS record"
}

# Create zone ruleset for IP and region-based bypass
resource "cloudflare_ruleset" "maintenance_bypass" {
  count       = var.enabled && (length(var.allowed_ips) > 0 || length(var.allowed_ip_ranges) > 0 || length(var.allowed_regions) > 0) ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  name        = "Maintenance Bypass Rules"
  description = "Allow specific IPs, IP ranges, and regions to bypass maintenance"
  kind        = "zone"
  phase       = "http_request_firewall_managed"

  rules = [
    {
      action      = "skip"
      description = "Allow specific IPs, IP ranges, and regions to bypass maintenance"
      enabled     = true
      expression  = join(" or ", concat(
        # Individual IPs
        [for ip in var.allowed_ips : "(ip.src eq ${ip})"],
        # IP Ranges in CIDR notation
        [for cidr in var.allowed_ip_ranges : "(ip.src in ${cidr})"],
        # Geographical regions
        [for region in var.allowed_regions : "(ip.geoip.continent eq \"${region}\")"]
      ))
      action_parameters = {
        ruleset = "current"
      }
    }
  ]
}

# Optional: Add rate limiting for maintenance page to prevent abuse
resource "cloudflare_rate_limit" "maintenance_rate_limit" {
  count       = var.enabled && var.rate_limit.enabled ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  threshold   = var.rate_limit.threshold
  period      = var.rate_limit.period
  
  match = {
    request = {
      url_pattern = "maintenance.${trimsuffix(trimprefix(var.worker_route, "*."), "/*")}/*"
      schemes     = ["HTTP", "HTTPS"]
      methods     = ["GET"]
    }
  }
  
  action = {
    mode    = var.rate_limit.action
    timeout = 300
  }
}
