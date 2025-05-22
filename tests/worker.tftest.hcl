# Worker tests for Cloudflare maintenance module

# Test case 1: Basic worker script configuration
run "verify_worker_script_configuration" {
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

  # Test assertions for worker script configuration
  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created with the correct name"
  }

  assert {
    condition     = output.worker_route_pattern != "Maintenance mode disabled"
    error_message = "Worker route should be created when maintenance is enabled"
  }

  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Maintenance status should be ENABLED"
  }

  assert {
    condition     = output.api_endpoint != "Maintenance mode disabled"
    error_message = "API endpoint should be configured when maintenance is enabled"
  }
}

# Test case 2: Test worker configuration with custom settings
run "verify_worker_config_with_customization" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    maintenance_title     = "Planned System Maintenance"
    contact_email         = "help@example.com"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
    custom_css            = "body { background-color: #f0f8ff; }"
    logo_url              = "https://example.com/logo.png"
    environment           = "test"
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Apply command to test actual resource creation
  command = apply

  # Verify the worker configuration with custom settings
  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created with custom configuration"
  }

  assert {
    condition     = output.maintenance_window.start_time == "2025-04-06T08:00:00Z"
    error_message = "Maintenance window should be properly configured"
  }

  assert {
    condition     = output.maintenance_window.end_time == "2025-04-06T10:00:00Z"
    error_message = "Maintenance window end time should be properly configured"
  }

  assert {
    condition     = output.maintenance_page_url != "Maintenance mode disabled"
    error_message = "Maintenance page URL should be configured with custom settings"
  }
}

# Test case 3: Test worker with allowed IPs configuration
run "verify_worker_with_allowed_ips" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    allowed_ips           = ["192.168.1.1", "10.0.0.1", "172.16.0.5"]
    environment           = "test"
    worker_route          = "example.com/*"
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Apply command to test actual resource creation
  command = apply

  # Check the worker configuration with allowed IPs
  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created with IP bypass configuration"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "Ruleset should be created for IP bypass when allowed IPs are specified"
  }

  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Maintenance should be enabled when allowed IPs are configured"
  }
}

# Test case 4: Test worker with IP ranges configuration
run "verify_worker_with_ip_ranges" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    allowed_ip_ranges     = ["192.168.0.0/24", "10.0.0.0/16"]
    environment           = "test"
    worker_route          = "example.com/*"
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Apply command to test actual resource creation
  command = apply

  # Check the worker configuration with IP ranges
  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created with IP range bypass configuration"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "Ruleset should be created for IP range bypass"
  }

  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Maintenance should be enabled when IP ranges are configured"
  }
}

# Test case 5: Test worker with regional bypass
run "verify_worker_with_regional_bypass" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    allowed_regions       = ["US", "CA", "GB"]
    environment           = "test"
    worker_route          = "example.com/*"
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Apply command to test actual resource creation
  command = apply

  # Verify regional bypass configuration
  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created with regional bypass configuration"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "Ruleset should be created for regional bypass"
  }

  assert {
    condition     = length(output.allowed_regions) == 3
    error_message = "Should have 3 allowed regions configured"
  }

  assert {
    condition     = contains(output.allowed_regions, "US") && contains(output.allowed_regions, "CA") && contains(output.allowed_regions, "GB")
    error_message = "All specified regions should be configured"
  }
}

# Test case 6: Test disabled worker configuration
run "verify_disabled_worker_configuration" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = false
    environment           = "test"
    worker_route          = "example.com/*"
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Apply command to test actual resource creation
  command = apply

  # Verify worker configuration when disabled
  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should still be created even when maintenance is disabled"
  }

  assert {
    condition     = output.maintenance_status == "DISABLED"
    error_message = "Maintenance status should be DISABLED"
  }

  assert {
    condition     = output.worker_route_pattern == "Maintenance mode disabled"
    error_message = "Worker route should not be configured when maintenance is disabled"
  }

  assert {
    condition     = output.dns_record_id == "No DNS record created"
    error_message = "DNS record should not be created when maintenance is disabled"
  }

  assert {
    condition     = output.ruleset_id == "No ruleset created"
    error_message = "Ruleset should not be created when maintenance is disabled"
  }

  assert {
    condition     = output.api_endpoint == "Maintenance mode disabled"
    error_message = "API endpoint should be disabled when maintenance is disabled"
  }
}