# Exposes the shared fixtures to OpenTofu tests, whose variables blocks
# cannot call functions. Used only from tests/*.tftest.hcl.

terraform {
  required_version = ">= 1.6.0"

  # Not used, but declaring it lets the test files' mock_provider
  # "cloudflare" resolve to the same source here as in the module.
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

locals {
  allowed_ips = jsondecode(file("${path.module}/allowed-ips.json"))
}

output "valid_allowed_ips" {
  description = "allowed_ips entries both the module and the Worker accept"
  value       = local.allowed_ips.valid
}

output "invalid_allowed_ips" {
  description = "allowed_ips entries both the module and the Worker reject"
  value       = local.allowed_ips.invalid
}
