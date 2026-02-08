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

variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
  default     = "production"
}

variable "enable_notifications" {
  description = "Enable notifications for maintenance windows"
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Slack webhook URL in format slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_routing_key" {
  description = "PagerDuty routing key in format pagerduty://your-routing-key"
  type        = string
  default     = ""
  sensitive   = true
}
