run "verify_staging_environment" {
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = true
    worker_route          = "*.staging.example.com/*"
    maintenance_title     = "Staging Maintenance"
    contact_email         = "dev@example.com"
    environment           = "staging"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
  }

  module {
    source = "../"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_script")]) > 0
    error_message = "Worker script should be created for staging environment"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_route")]) > 0
    error_message = "Worker route should be created for staging environment"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_ruleset")]) > 0
    error_message = "Ruleset should be created when maintenance is enabled with allowed IPs"
  }
}

run "verify_production_environment" {
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = true
    worker_route          = "*.production.example.com/*"
    maintenance_title     = "Production Maintenance"
    contact_email         = "support@example.com"
    environment           = "production"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
  }

  module {
    source = "../"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_script")]) > 0
    error_message = "Worker script should be created for production environment"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_route")]) > 0
    error_message = "Worker route should be created for production environment"
  }
}

run "verify_rfc3339_date_validation" {
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    environment           = "staging"
    maintenance_window    = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
  }
  
  module {
    source = "../"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_script")]) > 0
    error_message = "Worker script should be created with valid maintenance window"
  }
}

run "verify_ip_concatenation" {
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    environment           = "staging"
    allowed_ips           = ["192.168.1.1", "10.0.0.1", "172.16.0.1"]
  }
  
  module {
    source = "../"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_ruleset")]) > 0
    error_message = "Ruleset should be created with multiple IPs"
  }
}

