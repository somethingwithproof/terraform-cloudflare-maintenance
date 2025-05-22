# Basic test for Cloudflare maintenance functionality

run "test_enabled_maintenance" {
  # Define variables for module under test 
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "./"
  }

  # Apply to create resources and test outputs
  command = apply

  # Check expected outputs after apply
  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created when maintenance is enabled"
  }

  assert {
    condition     = output.worker_route_pattern != "Maintenance mode disabled"
    error_message = "Worker route should be created when maintenance is enabled"
  }

  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Maintenance status should be ENABLED when enabled=true"
  }

  assert {
    condition     = output.environment == "staging"
    error_message = "Environment output should match input variable"
  }
}

run "test_disabled_maintenance" {
  # Define variables for module under test
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = false
    worker_route          = "*.example.com/*"
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "./"
  }

  # Apply with maintenance disabled
  command = apply

  # Verify results are as expected
  assert {
    condition     = output.maintenance_status == "DISABLED"
    error_message = "Maintenance should be disabled"
  }

  assert {
    condition     = output.worker_route_pattern == "Maintenance mode disabled"
    error_message = "Worker route should indicate disabled when maintenance is disabled"
  }

  assert {
    condition     = output.maintenance_page_url == "Maintenance mode disabled"
    error_message = "Maintenance page URL should indicate disabled when maintenance is disabled"
  }

  assert {
    condition     = output.dns_record_id == "No DNS record created"
    error_message = "DNS record should not be created when maintenance is disabled"
  }
}