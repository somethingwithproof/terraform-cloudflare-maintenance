variable "cloudflare_api_token" {
  description = "Cloudflare API token with least privileges"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., production, staging, development)"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development."
  }
}

variable "office_ip_ranges" {
  description = "List of office IP ranges that can bypass maintenance mode"
  type        = list(string)
  default     = []
}

variable "monitoring_ips" {
  description = "List of monitoring service IPs that can bypass maintenance mode"
  type        = list(string)
  default     = []
}

variable "maintenance_start_time" {
  description = "Start time of the maintenance window in RFC3339 format"
  type        = string

  validation {
    condition     = can(formatdate("RFC3339", var.maintenance_start_time))
    error_message = "Maintenance start time must be in RFC3339 format (e.g., 2025-04-06T08:00:00Z)."
  }
}

variable "maintenance_end_time" {
  description = "End time of the maintenance window in RFC3339 format"
  type        = string

  validation {
    condition     = can(formatdate("RFC3339", var.maintenance_end_time))
    error_message = "Maintenance end time must be in RFC3339 format (e.g., 2025-04-06T10:00:00Z)."
  }
}

variable "monitoring_webhook_url" {
  description = "Webhook URL for notifying monitoring systems about maintenance"
  type        = string
  default     = ""
}
