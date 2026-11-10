# Root configuration that the CD workflow applies, one HCP Terraform workspace
# per environment. The module at the repository root stays backend-free so it
# can be reused; only this root stores state.

terraform {
  required_version = ">= 1.8.0"

  # Organization, workspace and token come from TF_CLOUD_ORGANIZATION,
  # TF_WORKSPACE and TF_TOKEN_app_terraform_io. The workspaces must use the
  # Local execution mode: runs happen in GitHub Actions, HCP stores state.
  cloud {}

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.19, < 6.0"
    }
  }
}

# Reads CLOUDFLARE_API_TOKEN from the environment.
provider "cloudflare" {}

module "maintenance" {
  source = "../"

  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  environment           = var.environment
  worker_route          = var.worker_route
  enabled               = var.enabled
  maintenance_window    = var.maintenance_window
  allowed_ips           = var.allowed_ips
  allowed_regions       = var.allowed_regions
  contact_email         = var.contact_email
}
