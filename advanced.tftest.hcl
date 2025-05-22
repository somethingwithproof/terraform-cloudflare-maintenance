# Advanced test for Cloudflare maintenance module

run "verify_staging_environment" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    worker_route          = "*.staging.example.com/*"
    maintenance_title     = "Staging Maintenance"
    contact_email         = "dev@example.com"
    environment           = "staging"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
  }

  module {
    source = "./"
  }

  # Apply to test actual resource creation and outputs
  command = apply

  # Verify staging environment outputs
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
    error_message = "Worker script should be created for staging environment"
  }

  assert {
    condition     = output.worker_route_pattern != "Maintenance mode disabled"
    error_message = "Worker route should be created for staging environment"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "Ruleset should be created when maintenance is enabled with allowed IPs"
  }
}

run "verify_production_environment" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    worker_route          = "*.production.example.com/*"
    maintenance_title     = "Production Maintenance"
    contact_email         = "support@example.com"
    environment           = "production"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
  }

  module {
    source = "./"
  }

  # Apply to test actual resource creation and outputs
  command = apply

  # Verify production environment outputs
  assert {
    condition     = output.environment == "production"
    error_message = "Environment should be set to production"
  }

  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Maintenance should be enabled in production environment"
  }

  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created for production environment"
  }

  assert {
    condition     = output.worker_route_pattern != "Maintenance mode disabled"
    error_message = "Worker route should be created for production environment"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "Ruleset should be created when allowed IPs are specified"
  }
}

run "verify_rfc3339_date_validation" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    environment           = "staging"
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
  }

  module {
    source = "./"
  }

  # Apply to test with RFC3339 dates
  command = apply

  # Verify RFC3339 date configuration
  assert {
    condition     = output.maintenance_window.start_time == "2025-04-06T08:00:00Z"
    error_message = "Maintenance window start time should be valid RFC3339 format"
  }

  assert {
    condition     = output.maintenance_window.end_time == "2025-04-06T10:00:00Z"
    error_message = "Maintenance window end time should be valid RFC3339 format"
  }

  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created with valid maintenance window"
  }
}

run "verify_ip_concatenation" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "System Maintenance"
    contact_email         = "support@example.com"
    environment           = "staging"
    allowed_ips           = ["192.168.1.1", "10.0.0.1", "172.16.0.1"]
  }

  module {
    source = "./"
  }

  # Apply to test IP configuration
  command = apply

  # Verify IP configuration
  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Maintenance should be enabled with IP configuration"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "Ruleset should be created with multiple IPs"
  }

  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created with IP bypass configuration"
  }
}