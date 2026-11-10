terraform {
  required_version = ">= 1.6.0"
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      # 5.19 is the first v5 release with the automatic v4 state upgraders.
      version = ">= 5.19, < 6.0"
    }
  }
}
