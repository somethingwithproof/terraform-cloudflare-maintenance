terraform {
  required_version = ">= 1.7.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.2, < 6.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3, < 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4, < 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2, < 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 4.0"
    }
  }
}

# Module version
# v3.0.0 - Major update with multi-language support, IP range features, and security enhancements
# Follows semantic versioning (MAJOR.MINOR.PATCH):
# - MAJOR: Breaking changes
# - MINOR: New features, non-breaking
# - PATCH: Bug fixes, non-breaking
#
# See CHANGELOG.md for detailed version history
