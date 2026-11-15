# SPDX-FileCopyrightText: 2025-2026 Thomas Vincent <thomasvincent@gmail.com>
# SPDX-License-Identifier: MIT

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
