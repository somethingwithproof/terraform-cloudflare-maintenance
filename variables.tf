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