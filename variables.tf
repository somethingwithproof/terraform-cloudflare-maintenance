variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "enabled" {
  description = "Enable or disable maintenance mode"
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
  description = "List of IP addresses that can bypass the maintenance page"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  default     = "production"
}

variable "maintenance_window" {
  description = "Scheduled maintenance window with start and end times in RFC3339 format"
  type = object({
    start_time = string
    end_time   = string
  })
  default = null

  validation {
    condition = var.maintenance_window == null || (
      can(formatdate("RFC3339", var.maintenance_window.start_time)) &&
      can(formatdate("RFC3339", var.maintenance_window.end_time))
    )
    error_message = "Maintenance window times must be in valid RFC3339 format (e.g., 2025-04-06T08:00:00Z)"
  }
}

variable "schedules" {
  description = "List of cron-based scheduled maintenance windows"
  type = list(object({
    name     = string
    cron     = string
    duration = string
    timezone = string
    notify   = optional(list(string), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for schedule in var.schedules :
      can(regex("^([0-9*,/-]+|\\*) ([0-9*,/-]+|\\*) ([0-9*,/-]+|\\*) ([0-9*,/-]+|\\*) ([0-9*,/-]+|[A-Z]{3}|\\*)$", schedule.cron)) &&
      length(split(" ", schedule.cron)) == 5
    ])
    error_message = "Cron expressions must be in valid 5-field format: 'minute hour day month weekday' (e.g., '0 2 * * SUN', '*/15 * * * *')"
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
  description = "Rate limiting configuration using Cloudflare Ruleset API"
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
