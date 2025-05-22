# Worker tests for Cloudflare maintenance module

run "verify_worker_script_configuration" {
  # Define variables for module under test
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "Worker Script Test"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "./"
  }

  # Apply the configuration to test outputs
  command = apply

  # Verify worker script is created
  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created"
  }

  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Maintenance status should be ENABLED"
  }

  assert {
    condition     = output.worker_route_pattern != "Maintenance mode disabled"
    error_message = "Worker route should be configured when enabled"
  }
}

run "verify_worker_config_with_customization" {
  # Define variables for module under test
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "Config File Test"
    contact_email         = "support@example.com"
    environment           = "staging"
    custom_css            = "body { background-color: #f5f5f5; }"
    logo_url              = "https://example.com/logo.png"
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
  }

  module {
    source = "./"
  }

  # Apply the configuration to test outputs
  command = apply

  # Verify worker configuration with custom settings
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
}

run "verify_worker_secret_binding" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "Secret Binding Test"
    contact_email         = "support@example.com"
    environment           = "staging"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
  }

  module {
    source = "./"
  }

  # Apply the configuration to test outputs
  command = apply

  # Verify worker script with bindings is created
  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script with bindings should be created"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "Ruleset should be created when allowed IPs are specified"
  }
}

run "verify_worker_analytics_binding" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "Analytics Binding Test"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "./"
  }

  # Apply the configuration to test outputs
  command = apply

  # Verify worker script with analytics binding is created
  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script with analytics binding should be created"
  }

  assert {
    condition     = output.api_endpoint != "Maintenance mode disabled"
    error_message = "API endpoint should be configured when maintenance is enabled"
  }
}

run "verify_kv_namespace" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "KV Namespace Test"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "./"
  }

  # Apply the configuration to test outputs
  command = apply

  # Verify KV namespace functionality through maintenance status
  assert {
    condition     = output.maintenance_status == "ENABLED"
    error_message = "Worker KV namespace should be created when maintenance is enabled"
  }

  assert {
    condition     = output.worker_script_name != null && output.worker_script_name != ""
    error_message = "Worker script should be created for KV namespace functionality"
  }
}

run "verify_disabled_worker_configuration" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = false
    worker_route          = "*.example.com/*"
    maintenance_title     = "Disabled Worker Test"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "./"
  }

  # Apply the configuration to test outputs
  command = apply

  # Verify worker configuration when disabled
  assert {
    condition     = output.maintenance_status == "DISABLED"
    error_message = "Maintenance status should be DISABLED"
  }

  assert {
    condition     = output.worker_route_pattern == "Maintenance mode disabled"
    error_message = "Worker route should not be created when maintenance is disabled"
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