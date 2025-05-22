# Advanced test for Cloudflare maintenance module

# Test case 1: Environment-based configuration (staging)
run "verify_staging_environment" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    environment           = "staging"
    worker_route          = "example.com/api/*"
    enabled               = true
    maintenance_title     = "Scheduled System Maintenance"
    contact_email         = "support@example.com"
    allowed_ips           = ["192.168.0.1", "10.0.0.1", "8.8.8.8", "1.1.1.1"]
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
    custom_css = "body { background-color: #f0f8ff; }"
    logo_url   = "https://example.com/logo-large.png"
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Apply command to test actual resource creation
  command = apply

  # Assertions for staging environment outputs
  assert {
    condition     = output.environment == "staging"
    error_message = "Environment should be set to staging"
  }

  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Maintenance should be enabled in staging environment"
  }

  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created in staging environment"
  }

  assert {
    condition     = output.worker_route_pattern != "Maintenance mode disabled"
    error_message = "Worker route should be configured in staging environment"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "Ruleset should be created for IP bypass in staging environment"
  }

  assert {
    condition     = output.maintenance_window.start_time == "2025-04-06T08:00:00Z"
    error_message = "Maintenance window start time should match input"
  }

  assert {
    condition     = output.maintenance_window.end_time == "2025-04-06T10:00:00Z"
    error_message = "Maintenance window end time should match input"
  }
}

# Test case 2: Environment-based configuration (production)
run "verify_production_environment" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    environment           = "production"
    worker_route          = "example.com/api/*"
    enabled               = false
    maintenance_title     = "Scheduled System Maintenance"
    contact_email         = "support@example.com"
    allowed_ips           = ["192.168.0.1", "10.0.0.1", "8.8.8.8", "1.1.1.1"]
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
    custom_css = "body { background-color: #f0f8ff; }"
    logo_url   = "https://example.com/logo-large.png"
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Apply command to test actual resource creation
  command = apply

  # Assertions for production environment outputs
  assert {
    condition     = output.environment == "production"
    error_message = "Environment should be set to production"
  }

  assert {
    condition     = output.maintenance_status == "DISABLED"
    error_message = "Maintenance should be disabled in production environment"
  }

  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should still be created in production environment"
  }

  assert {
    condition     = output.worker_route_pattern == "Maintenance mode disabled"
    error_message = "Worker route should not be configured in production environment when disabled"
  }

  assert {
    condition     = output.ruleset_id == "No ruleset created"
    error_message = "Ruleset should not be created in production environment when disabled"
  }
}

# Test case 3: Variable validation for RFC3339 dates
run "verify_rfc3339_date_validation" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
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

  # Check that maintenance window is properly configured with valid RFC3339 dates
  assert {
    condition     = output.maintenance_window.start_time == "2025-04-06T08:00:00Z"
    error_message = "Maintenance window start time should be valid RFC3339 format"
  }

  assert {
    condition     = output.maintenance_window.end_time == "2025-04-06T10:00:00Z"
    error_message = "Maintenance window end time should be valid RFC3339 format"
  }

  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Configuration should succeed with valid RFC3339 dates"
  }
}

# Test case 4: Test allowed IP configuration
run "verify_ip_configuration" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    allowed_ips           = ["192.168.0.1", "10.0.0.1", "8.8.8.8", "1.1.1.1"]
    allowed_regions       = ["US", "CA"]
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Apply command to test actual resource creation
  command = apply

  # Verify allowed IPs and regions are configured correctly
  assert {
    condition     = length(output.allowed_regions) == 2
    error_message = "Should have 2 allowed regions configured"
  }

  assert {
    condition     = contains(output.allowed_regions, "US")
    error_message = "Should include US in allowed regions"
  }

  assert {
    condition     = contains(output.allowed_regions, "CA")
    error_message = "Should include CA in allowed regions"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "Ruleset should be created when allowed IPs and regions are specified"
  }
}