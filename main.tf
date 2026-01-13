provider "cloudflare" {
  api_token = var.cloudflare_api_token
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

  secret_text_binding {
    name = "ALLOWED_IPS"
    text = jsonencode(var.allowed_ips)
  }
}

# Create the worker route when enabled
resource "cloudflare_workers_route" "maintenance" {
  count       = var.enabled ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  pattern     = var.worker_route
  script_name = cloudflare_workers_script.maintenance.name
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