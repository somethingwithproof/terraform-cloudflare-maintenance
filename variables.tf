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