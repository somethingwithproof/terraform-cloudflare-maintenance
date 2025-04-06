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

variable "worker_route" {
  description = "URL pattern to trigger the maintenance worker"
  type        = string
  default     = "*.example.com/*"
}

variable "enabled" {
  description = "Toggle maintenance mode on/off"
  type        = bool
  default     = false
}

variable "maintenance_title" {
  description = "Title for the maintenance page"
  type        = string
  default     = "System Maintenance in Progress"
}

variable "contact_email" {
  description = "Contact email to display on the maintenance page"
  type        = string
  default     = "support@example.com"
}

variable "allowed_ips" {
  description = "List of IP addresses that can bypass the maintenance page"
  type        = list(string)
  default     = []
}

variable "maintenance_window" {
  description = "Scheduled maintenance window in RFC3339 format"
  type = object({
    start_time = string
    end_time   = string
  })
  default = null
}

variable "custom_css" {
  description = "Custom CSS for the maintenance page"
  type        = string
  default     = ""
}

variable "logo_url" {
  description = "URL to the logo to display on the maintenance page"
  type        = string
  default     = ""
}
