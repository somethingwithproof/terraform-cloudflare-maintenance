terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.1"
    }
  }
  required_version = ">= 1.0"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "external" "bundle_worker" {
  program = ["${path.module}/worker/build.sh"]
}

resource "cloudflare_worker_script" "maintenance" {
  name       = "maintenance-page-worker"
  account_id = var.cloudflare_account_id
  content    = data.external.bundle_worker.result["script"]
}

resource "cloudflare_worker_route" "maintenance_route" {
  zone_id     = var.cloudflare_zone_id
  pattern     = var.worker_route
  script_name = cloudflare_worker_script.maintenance.name
}
