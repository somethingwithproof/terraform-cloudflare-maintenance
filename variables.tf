variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
  sensitive   = true
}

variable "enabled" {
  description = "Serve the maintenance page until disabled. Ignored while maintenance_window is set, which then decides when the page is served."
  type        = bool
  default     = false
}

variable "worker_route" {
  description = "URL pattern to trigger the maintenance worker"
  type        = string
  default     = "*.example.com/*"
}

variable "maintenance_title" {
  description = "Title for the maintenance page"
  type        = string
  default     = "Maintenance Mode"
}

variable "maintenance_message" {
  description = "Message to display on the maintenance page"
  type        = string
  default     = "We are currently performing scheduled maintenance. We will be back shortly."
}

variable "contact_email" {
  description = "Contact email to display on the maintenance page"
  type        = string
  default     = ""
}

variable "allowed_ips" {
  description = "IPv4 or IPv6 addresses and CIDR ranges whose clients bypass the maintenance page. The Worker matches them against CF-Connecting-IP."
  type        = list(string)
  default     = []

  # The same grammar the Worker's parseCidr accepts, so that nothing passes
  # plan only to be ignored at the edge. cidrhost() alone also accepts
  # leading zeros in IPv4 octets and IPv4-mapped IPv6 prefixes shorter than
  # 96, both of which the Worker rejects. tests/fixtures/allowed-ips.json
  # holds the cases both sides are tested against.
  validation {
    condition = alltrue([
      for ip in var.allowed_ips : (
        can(cidrhost(strcontains(ip, "/") ? ip : "${ip}/${strcontains(ip, ":") ? 128 : 32}", 0)) &&
        # No IPv4 octet, alone or embedded in IPv6, with a leading zero.
        !can(regex("(^|[.:])0[0-9]+[.]|[.]0[0-9]+([./]|$)", ip)) &&
        # cidrhost() writes an IPv4-mapped address without colons; such a
        # range must keep the 96-bit ::ffff: prefix. && does not short-
        # circuit, so try() absorbs the errors this raises for IPv4 entries
        # and plain addresses; the first check has judged those already.
        try(!(
          strcontains(ip, ":") &&
          !strcontains(cidrhost("${split("/", ip)[0]}/128", 0), ":") &&
          tonumber(split("/", ip)[1]) < 96
        ), true)
      )
    ])
    error_message = "Each allowed_ips entry must be an IPv4 or IPv6 address or CIDR range (e.g., 192.0.2.10, 198.51.100.0/24, 2001:db8::/32), with no leading zeros in IPv4 octets and a prefix of at least 96 for IPv4-mapped IPv6 ranges."
  }
}

variable "script_name" {
  description = "Name of the Worker script: 1-63 lowercase letters, digits or dashes, starting and ending with a letter or digit. Defaults to maintenance-page-<environment>. Must be unique per account: two module instances with the same name overwrite each other's Worker."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  default     = "production"
}

variable "maintenance_window" {
  description = "Scheduled maintenance window with RFC3339 start and end times. When set, the Worker route is deployed and the page is served only from start_time (inclusive) to end_time (exclusive), whether or not enabled is true."
  type = object({
    start_time = string
    end_time   = string
  })
  default = null

  validation {
    condition = var.maintenance_window == null || (
      can(timeadd(var.maintenance_window.start_time, "0s")) &&
      can(timeadd(var.maintenance_window.end_time, "0s"))
    )
    error_message = "Maintenance window times must be in valid RFC3339 format (e.g., 2025-04-06T08:00:00Z)"
  }
  validation {
    # try() also covers a null window, where the attribute access fails.
    condition     = try(timecmp(var.maintenance_window.start_time, var.maintenance_window.end_time) < 0, var.maintenance_window == null)
    error_message = "Maintenance window end_time must be after start_time."
  }
}

variable "custom_css" {
  description = "Custom CSS to apply to the maintenance page"
  type        = string
  default     = ""
}

variable "logo_url" {
  description = "URL to the logo to display on the maintenance page"
  type        = string
  default     = ""
}

variable "retry_after_seconds" {
  description = "Retry-After the maintenance page sends outside a scheduled window, in seconds. Inside a window it is the time left until end_time."
  type        = number
  default     = 3600

  validation {
    condition     = var.retry_after_seconds >= 1 && var.retry_after_seconds <= 86400 && floor(var.retry_after_seconds) == var.retry_after_seconds
    error_message = "retry_after_seconds must be a whole number of seconds from 1 to 86400."
  }
}

variable "runtime_toggle" {
  description = "Lets scripts/maintenance (or the Toggle maintenance workflow) switch maintenance on and off, set a window or change the text within about a minute, without an apply. Creates a Workers KV namespace the Worker reads on each request (cached at each edge location for cache_ttl_seconds), and keeps the route deployed while enabled. failure_mode decides what happens if KV cannot be read or holds a malformed value: \"open\" falls back to the Terraform settings (enabled and maintenance_window), \"closed\" serves the maintenance page."
  type = object({
    enabled           = optional(bool, false)
    failure_mode      = optional(string, "open")
    cache_ttl_seconds = optional(number, 60)
  })
  default  = {}
  nullable = false

  validation {
    condition     = contains(["open", "closed"], var.runtime_toggle.failure_mode)
    error_message = "runtime_toggle.failure_mode must be \"open\" or \"closed\"."
  }

  validation {
    condition     = var.runtime_toggle.cache_ttl_seconds >= 30 && var.runtime_toggle.cache_ttl_seconds <= 3600 && floor(var.runtime_toggle.cache_ttl_seconds) == var.runtime_toggle.cache_ttl_seconds
    error_message = "runtime_toggle.cache_ttl_seconds must be a whole number from 30 (the Workers KV minimum) to 3600."
  }
}

variable "status_path" {
  description = "Path of the JSON status endpoint the Worker answers on every routed hostname, for everyone and without contacting the origin: {maintenance, window, retry_after_seconds}. It holds no allowlist or contact data. Empty disables it."
  type        = string
  default     = "/__maintenance/status"

  validation {
    condition     = var.status_path == "" || can(regex("^/[A-Za-z0-9._~!$&'()*+,;=:@/-]*$", var.status_path))
    error_message = "status_path must be empty or a URL path starting with \"/\", without a query or fragment."
  }
}

variable "pages" {
  description = "Page text for particular hostnames or paths, overriding maintenance_title and maintenance_message. The most specific entry wins: one with a matching host beats one without, then the longest path_prefix. path_prefix matches whole segments, so \"/api\" covers \"/api/v1\" but not \"/apis\"."
  type = list(object({
    host        = optional(string)
    path_prefix = optional(string, "/")
    title       = optional(string)
    message     = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for page in var.pages :
      startswith(page.path_prefix, "/") &&
      (page.host == null || can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?([.][a-z0-9]([a-z0-9-]*[a-z0-9])?)*$", page.host))) &&
      (page.title != null || page.message != null)
    ])
    error_message = "Each page needs a path_prefix starting with \"/\", a lowercase hostname or no host, and a title or a message."
  }

  validation {
    condition     = length(distinct([for page in var.pages : "${coalesce(page.host, "*")}${page.path_prefix}"])) == length(var.pages)
    error_message = "Two pages have the same host and path_prefix."
  }
}

variable "allowed_regions" {
  description = "List of country codes (ISO 3166-1 alpha-2) that can bypass the maintenance page"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for region in var.allowed_regions :
      can(regex("^[A-Z]{2}$", region))
    ])
    error_message = "Region codes must be valid ISO 3166-1 alpha-2 country codes (e.g., US, CA, GB)"
  }
}

variable "rate_limit" {
  description = "Zone-wide rate limiting rule. Enabling it makes this module own the zone's http_ratelimit entry-point ruleset; disabling it deletes that ruleset. Leave it disabled on zones whose rate limiting rules are managed elsewhere."
  type = object({
    enabled             = optional(bool, false)
    requests_per_period = optional(number, 100)
    period              = optional(number, 60)
    action              = optional(string, "block")
    mitigation_timeout  = optional(number, 600)
    counting_expression = optional(string, null)
    requests_to_origin  = optional(bool, false)
  })
  default = {
    enabled             = false
    requests_per_period = 100
    period              = 60
    action              = "block"
    mitigation_timeout  = 600
    counting_expression = null
    requests_to_origin  = false
  }

  validation {
    condition     = var.rate_limit.period >= 10 && var.rate_limit.period <= 86400
    error_message = "Rate limit period must be between 10 and 86400 seconds."
  }

  validation {
    condition     = contains(["block", "challenge", "js_challenge", "managed_challenge", "log"], var.rate_limit.action)
    error_message = "Rate limit action must be one of: block, challenge, js_challenge, managed_challenge, log."
  }

  validation {
    condition     = var.rate_limit.mitigation_timeout >= 60 && var.rate_limit.mitigation_timeout <= 86400
    error_message = "Mitigation timeout must be between 60 and 86400 seconds."
  }
}
