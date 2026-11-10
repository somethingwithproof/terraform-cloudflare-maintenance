# Deploy the maintenance worker
resource "cloudflare_workers_script" "maintenance" {
  account_id  = var.cloudflare_account_id
  script_name = "maintenance-page-worker"
  content     = file("${path.module}/worker.js")

  # Environment variables for the worker
  bindings = [
    {
      name = "MAINTENANCE_ENABLED"
      type = "plain_text"
      text = tostring(var.enabled)
    },
    {
      name = "MAINTENANCE_TITLE"
      type = "plain_text"
      text = var.maintenance_title
    },
    {
      name = "MAINTENANCE_MESSAGE"
      type = "plain_text"
      text = var.maintenance_message
    },
    {
      name = "CONTACT_EMAIL"
      type = "plain_text"
      text = var.contact_email
    },
    {
      name = "CUSTOM_CSS"
      type = "plain_text"
      text = var.custom_css
    },
    {
      name = "LOGO_URL"
      type = "plain_text"
      text = var.logo_url
    },
    {
      name = "MAINTENANCE_WINDOW_START"
      type = "plain_text"
      text = var.maintenance_window != null ? var.maintenance_window.start_time : ""
    },
    {
      name = "MAINTENANCE_WINDOW_END"
      type = "plain_text"
      text = var.maintenance_window != null ? var.maintenance_window.end_time : ""
    },
    {
      name = "RETRY_AFTER"
      type = "plain_text"
      text = tostring(var.retry_after_seconds)
    },
    {
      name = "ALLOWED_IPS"
      type = "secret_text"
      text = jsonencode(var.allowed_ips)
    },
    {
      name = "ALLOWED_REGIONS"
      type = "secret_text"
      text = jsonencode(var.allowed_regions)
    },
  ]
}

locals {
  # The route is needed whenever the Worker may serve the page: while enabled,
  # or for a scheduled window. With a window the Worker checks the time on
  # each request and passes traffic through outside it.
  route_enabled = var.enabled || var.maintenance_window != null
}

resource "cloudflare_workers_route" "maintenance" {
  count   = local.route_enabled ? 1 : 0
  zone_id = var.cloudflare_zone_id
  pattern = var.worker_route
  script  = cloudflare_workers_script.maintenance.script_name
}

# Optional rate limiting. This creates the zone's http_ratelimit entry-point
# ruleset, so the module then owns every rate limiting rule on the zone: a
# zone that already has one cannot create a second, and disabling rate_limit
# deletes the entry-point ruleset. Only enable it on zones whose rate limiting
# rules are managed nowhere else.
resource "cloudflare_ruleset" "rate_limit" {
  count       = var.rate_limit.enabled ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  name        = "Rate Limiting Rules"
  description = "Rate limiting for maintenance page protection"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules = [
    {
      action = var.rate_limit.action
      ratelimit = {
        characteristics     = ["cf.colo.id", "ip.src"]
        period              = var.rate_limit.period
        requests_per_period = var.rate_limit.requests_per_period
        mitigation_timeout  = var.rate_limit.mitigation_timeout
        requests_to_origin  = var.rate_limit.requests_to_origin
        counting_expression = var.rate_limit.counting_expression
      }
      expression  = "true"
      description = "Rate limit all requests"
      enabled     = true
    },
  ]
}
