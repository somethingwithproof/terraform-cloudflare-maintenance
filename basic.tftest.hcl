run "test_enabled_maintenance" {
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "../"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_script")]) > 0
    error_message = "Worker script should be created when maintenance is enabled"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_route")]) > 0
    error_message = "Worker route should be created when maintenance is enabled"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_dns_record")]) > 0
    error_message = "DNS record should be created when maintenance is enabled"
  }
}

run "test_disabled_maintenance" {
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = false
    worker_route          = "*.example.com/*"
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "../"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_route") && r.type == "create"]) == 0
    error_message = "Worker route should not be created when maintenance is disabled"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_dns_record") && r.type == "create"]) == 0
    error_message = "DNS record should not be created when maintenance is disabled"
  }
}

