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

variable "environment" {
  description = "Environment name: dev, staging or production"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging or production."
  }
}

variable "worker_route" {
  description = "Route pattern the maintenance Worker serves, for example example.com/*"
  type        = string
}

variable "enabled" {
  description = "Serve the maintenance page until disabled"
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "Scheduled maintenance window with RFC3339 start and end times, or null"
  type = object({
    start_time = string
    end_time   = string
  })
  default = null
}

variable "allowed_ips" {
  description = "IPv4/IPv6 addresses or CIDR ranges that bypass the maintenance page"
  type        = list(string)
  default     = []
  # From environment secrets; keeps the list out of plan output.
  sensitive = true
}

variable "allowed_regions" {
  description = "ISO 3166-1 alpha-2 country codes that bypass the maintenance page"
  type        = list(string)
  default     = []
  # From environment secrets; keeps the list out of plan output.
  sensitive = true
}

variable "contact_email" {
  description = "Contact email shown on the maintenance page"
  type        = string
  default     = ""
}

variable "runtime_toggle" {
  description = "Create the runtime toggle's KV namespace so the Toggle maintenance workflow can switch maintenance without a deploy"
  type        = bool
  default     = false
}
