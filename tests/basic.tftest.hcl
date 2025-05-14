# Test basic Cloudflare maintenance functionality

run "test_enabled_maintenance" {
  # Define variables for this test
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    worker_route          = "example.com/*"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Plan command
  command = plan

  # Assertions for enabled maintenance
  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_route") && r.type == "create"]) > 0
    error_message = "Worker route should be created when maintenance is enabled"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_script") && r.type == "create"]) > 0
    error_message = "Worker script should be created when maintenance is enabled"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_record") && r.type == "create"]) > 0
    error_message = "DNS record should be created when maintenance is enabled"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_ruleset") && r.type == "create"]) > 0
    error_message = "Ruleset should be created for IP bypass when maintenance is enabled"
  }
}

run "test_disabled_maintenance" {
  # Define variables for this test
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = false
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    worker_route          = "example.com/*"
  }

  # Specify module to test
  module {
    source = "../"
  }
  
  # Plan command
  command = plan
  
  # Assertions for disabled maintenance
  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_workers_route") && r.type == "create"]) == 0
    error_message = "Worker route should not be created when maintenance is disabled"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_record") && r.type == "create"]) == 0
    error_message = "DNS record should not be created when maintenance is disabled"
  }

  assert {
    condition     = length([for r in terraform.plan.resource_changes : r if contains(r.address, "cloudflare_ruleset") && r.type == "create"]) == 0
    error_message = "Ruleset should not be created when maintenance is disabled"
  }
}

