# Test basic Cloudflare maintenance functionality

# Mock the Cloudflare provider so tests never call the real Cloudflare API.
mock_provider "cloudflare" {}

variables {
  cloudflare_api_token = "test-api-token"
}

run "test_enabled_maintenance" {
  # Define variables for this test
  variables {
    cloudflare_account_id = "0123456789abcdef0123456789abcdef"
    cloudflare_zone_id    = "fedcba9876543210fedcba9876543210"
    enabled               = true
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    worker_route          = "example.com/*"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
    environment           = "test"
  }

  # Specify module to test

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
    condition     = output.environment == "test"
    error_message = "Environment output should match input variable"
  }
}

run "test_disabled_maintenance" {
  # Define variables for this test
  variables {
    cloudflare_account_id = "0123456789abcdef0123456789abcdef"
    cloudflare_zone_id    = "fedcba9876543210fedcba9876543210"
    enabled               = false
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    worker_route          = "example.com/*"
    environment           = "test"
  }

  # Specify module to test

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



}