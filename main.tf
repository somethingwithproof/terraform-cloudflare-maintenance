locals {
  # One Worker per module instance. Two instances in one account with the same
  # name would overwrite each other's code and bindings, and destroying one
  # would delete the Worker the other routes to.
  # Not coalesce(): an empty script_name must fail the name check below
  # rather than silently fall back to the default.
  script_name = (
    var.script_name != null ? var.script_name :
    "maintenance-page-${trim(replace(lower(var.environment), "/[^a-z0-9]+/", "-"), "-")}"
  )

  # The bundle built from worker/src by `npm run build` and committed, so the
  # module deploys without Node. wrangler.json is the one source of the
  # runtime compatibility date for local runs, tests and this deploy.
  worker_bundle      = "${path.module}/worker/dist/index.js"
  compatibility_date = jsondecode(file("${path.module}/worker/wrangler.json")).compatibility_date
}

# The runtime toggle's state. scripts/maintenance writes the "state" key;
# Terraform never manages the key, so an apply does not undo a toggle.
resource "cloudflare_workers_kv_namespace" "toggle" {
  count      = var.runtime_toggle.enabled ? 1 : 0
  account_id = var.cloudflare_account_id
  title      = "${local.script_name}-toggle"
}

# Deploy the maintenance worker
resource "cloudflare_workers_script" "maintenance" {
  account_id  = var.cloudflare_account_id
  script_name = local.script_name
  # A module Worker: the bundle exports a fetch handler.
  content_file       = local.worker_bundle
  content_sha256     = filesha256(local.worker_bundle)
  main_module        = "index.js"
  compatibility_date = local.compatibility_date

  lifecycle {
    # Renaming replaces the Worker. Create the new one first so the route can
    # move to it before the old one is deleted, instead of pointing at a
    # deleted Worker in between.
    create_before_destroy = true

    precondition {
      # Checked here rather than in a variable validation so that the name
      # derived from environment is checked by the same rule.
      condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", local.script_name))
      error_message = "The Worker script name must be 1-63 lowercase letters, digits or dashes, starting and ending with a letter or digit. Set script_name, or use an environment that yields such a name."
    }
  }

  # Environment variables for the worker
  bindings = concat([
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
      name = "STATUS_PATH"
      type = "plain_text"
      text = var.status_path
    },
    {
      name = "PAGES"
      type = "plain_text"
      text = jsonencode(var.pages)
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
    {
      name = "KV_FAILURE_MODE"
      type = "plain_text"
      text = var.runtime_toggle.failure_mode
    },
    {
      name = "KV_CACHE_TTL"
      type = "plain_text"
      text = tostring(var.runtime_toggle.cache_ttl_seconds)
    },
    ], [
    for namespace in cloudflare_workers_kv_namespace.toggle : {
      name         = "MAINTENANCE_KV"
      type         = "kv_namespace"
      namespace_id = namespace.id
    }
  ])
}

locals {
  # The route is needed whenever the Worker may serve the page: while enabled,
  # for a scheduled window, or while the runtime toggle can turn it on. With a
  # window or the toggle the Worker decides on each request and passes
  # traffic through when maintenance is off.
  route_enabled = var.enabled || var.maintenance_window != null || var.runtime_toggle.enabled
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
