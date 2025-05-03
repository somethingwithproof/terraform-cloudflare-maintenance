terraform {
  required_version = ">= 1.7.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}
