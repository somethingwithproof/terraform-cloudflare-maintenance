# Test basic Cloudflare maintenance functionality

run "test_enabled_maintenance" {
  # Define variables for this test
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    worker_route          = "example.com/*"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
    environment           = "test"
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Apply command to test actual resource creation
  command = apply

  # Assertions for enabled maintenance using outputs
  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Maintenance status should be ENABLED when enabled=true"
  }

  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script name should be set when maintenance is enabled"
  }

  assert {
    condition     = output.worker_route_pattern != "Maintenance mode disabled"
    error_message = "Worker route pattern should be configured when maintenance is enabled"
  }

  assert {
    condition     = output.maintenance_page_url != "Maintenance mode disabled"
    error_message = "Maintenance page URL should be configured when maintenance is enabled"
  }

  assert {
    condition     = output.dns_record_id != "No DNS record created"
    error_message = "DNS record should be created when maintenance is enabled"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "Ruleset should be created when allowed IPs are specified"
  }

  assert {
    condition     = output.environment == "test"
    error_message = "Environment output should match input variable"
  }
}

run "test_disabled_maintenance" {
  # Define variables for this test
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = false
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    worker_route          = "example.com/*"
    environment           = "test"
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Apply command to test actual resource creation
  command = apply

  # Assertions for disabled maintenance using outputs
  assert {
    condition     = output.maintenance_status == "DISABLED"
    error_message = "Maintenance status should be DISABLED when enabled=false"
  }

  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should still be created even when disabled"
  }

  assert {
    condition     = output.worker_route_pattern == "Maintenance mode disabled"
    error_message = "Worker route should not be configured when maintenance is disabled"
  }

  assert {
    condition     = output.maintenance_page_url == "Maintenance mode disabled"
    error_message = "Maintenance page URL should indicate disabled when maintenance is disabled"
  }

  assert {
    condition     = output.dns_record_id == "No DNS record created"
    error_message = "DNS record should not be created when maintenance is disabled"
  }

  assert {
    condition     = output.ruleset_id == "No ruleset created"
    error_message = "Ruleset should not be created when maintenance is disabled"
  }
}