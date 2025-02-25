terraform {
  backend "remote" {
    organization = "your-org"
    workspaces {
      name = "cloudflare-maintenance"
    }
  }
}
