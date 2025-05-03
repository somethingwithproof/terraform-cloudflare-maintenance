terraform {
  backend "remote" {
    organization = "example-org"
    workspaces {
      name = "cloudflare-maintenance"
    }
  }
}
