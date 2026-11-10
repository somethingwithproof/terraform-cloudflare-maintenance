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
