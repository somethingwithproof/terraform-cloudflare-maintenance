terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Module configuration for testing
module "maintenance" {
  source = "../"

  cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  enabled               = var.enabled
  maintenance_title     = var.maintenance_title
  contact_email         = var.contact_email
  worker_route          = var.worker_route
  allowed_ips           = var.allowed_ips
  maintenance_window    = var.maintenance_window
  custom_css            = var.custom_css
  logo_url              = var.logo_url
}

# Variables for testing
variable "cloudflare_api_token" {
  description = "Cloudflare API token with least privileges"
  type        = string
  default     = "test-api-token"
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  default     = "test-account-id"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
  default     = "test-zone-id"
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

variable "worker_route" {
  description = "URL pattern to trigger the maintenance worker"
  type        = string
  default     = "*.example.com/*"
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

# Additional variables for advanced tests
variable "environment" {
  description = "Environment (staging or production)"
  type        = string
  default     = "staging"
}

variable "office_ip_ranges" {
  description = "Office IP ranges"
  type        = list(string)
  default     = ["192.168.0.0/24", "10.0.0.0/24"]
}

variable "monitoring_ips" {
  description = "Monitoring service IPs"
  type        = list(string)
  default     = ["8.8.8.8", "1.1.1.1"]
}

variable "monitoring_webhook_url" {
  description = "URL for monitoring webhook"
  type        = string
  default     = "https://monitoring.example.com/webhook"
}

