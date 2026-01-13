provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Local variables for IP and region bypass expressions
locals {
  # Format IP addresses for Cloudflare firewall expression
  ip_bypass_expression = length(var.allowed_ips) > 0 ? format(
    "ip.src in {%s}",
    join(" ", [for ip in var.allowed_ips : format("\"%s\"", ip)])
  ) : ""

  # Format country codes for Cloudflare firewall expression
  region_bypass_expression = length(var.allowed_regions) > 0 ? format(
    "ip.geoip.country in {%s}",
    join(" ", [for region in var.allowed_regions : format("\"%s\"", region)])
  ) : ""
}

# Deploy the maintenance worker
resource "cloudflare_workers_script" "maintenance" {
  account_id = var.cloudflare_account_id
  name       = "maintenance-page-worker"
  content    = file("${path.module}/worker.js")

  # Environment variables for the worker
  plain_text_binding {
    name = "MAINTENANCE_ENABLED"
    text = tostring(var.enabled)
  }

  plain_text_binding {
    name = "MAINTENANCE_TITLE"
    text = var.maintenance_title
  }

  plain_text_binding {
    name = "MAINTENANCE_MESSAGE"
    text = var.maintenance_message
  }

  plain_text_binding {
    name = "CONTACT_EMAIL"
    text = var.contact_email
  }

  plain_text_binding {
    name = "CUSTOM_CSS"
    text = var.custom_css
  }

  plain_text_binding {
    name = "LOGO_URL"
    text = var.logo_url
  }

  plain_text_binding {
    name = "MAINTENANCE_WINDOW_START"
    text = var.maintenance_window != null ? var.maintenance_window.start_time : ""
  }

  plain_text_binding {
    name = "MAINTENANCE_WINDOW_END"
    text = var.maintenance_window != null ? var.maintenance_window.end_time : ""
  }

  secret_text_binding {
    name = "ALLOWED_IPS"
    text = jsonencode(var.allowed_ips)
  }

  secret_text_binding {
    name = "ALLOWED_REGIONS"
    text = jsonencode(var.allowed_regions)
  }
}

# Create the worker route when enabled
resource "cloudflare_workers_route" "maintenance" {
  count       = var.enabled ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  pattern     = var.worker_route
  script_name = cloudflare_workers_script.maintenance.name
}

# Create a DNS record for maintenance status page
resource "cloudflare_record" "maintenance_status" {
  count   = var.enabled ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "maintenance-status-${var.environment}"
  content = "100::"
  type    = "AAAA"
  proxied = true
  ttl     = 1
  comment = "Maintenance status page for ${var.environment} environment"
}

# Create a ruleset for IP and region-based bypass
resource "cloudflare_ruleset" "maintenance_bypass" {
  count   = var.enabled && (length(var.allowed_ips) > 0 || length(var.allowed_regions) > 0) ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "maintenance-bypass-${var.environment}"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules {
    action = "skip"
    action_parameters {
      phases = ["http_request_firewall_managed", "http_ratelimit", "http_request_firewall_custom"]
    }
    expression  = join(" or ", compact([local.ip_bypass_expression, local.region_bypass_expression]))
    description = "Allow bypass for maintenance mode from specific IPs and regions"
    enabled     = true
  }
}

# Rate limiting using modern Cloudflare Ruleset API (replaces deprecated cloudflare_rate_limit)
resource "cloudflare_ruleset" "rate_limit" {
  count       = var.rate_limit.enabled ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  name        = "Rate Limiting Rules"
  description = "Rate limiting for maintenance page protection"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules {
    action = var.rate_limit.action
    ratelimit {
      characteristics     = ["cf.colo.id", "ip.src"]
      period              = var.rate_limit.period
      requests_per_period = var.rate_limit.requests_per_period
      mitigation_timeout  = var.rate_limit.mitigation_timeout
      requests_to_origin  = var.rate_limit.requests_to_origin
      counting_expression = var.rate_limit.counting_expression
    }
    expression  = "(http.request.uri.path matches \".*\")"
    description = "Rate limit all requests"
    enabled     = true
  }
}
