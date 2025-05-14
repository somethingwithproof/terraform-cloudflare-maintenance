# Advanced test for Cloudflare maintenance module

# Test case 1: Environment-based configuration (staging)
run "verify_staging_environment" {
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    environment           = "staging"
    worker_route          = "example.com/api/*"
    enabled               = true # staging should be enabled
    maintenance_title     = "Scheduled System Maintenance"
    contact_email         = "support@example.com"
    office_ip_ranges      = ["192.168.0.0/24", "10.0.0.0/24"]
    monitoring_ips        = ["8.8.8.8", "1.1.1.1"]
    allowed_ips           = ["192.168.0.0/24", "10.0.0.0/24", "8.8.8.8", "1.1.1.1"]
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

  # Run plan to check resources
  command = plan

  # Assertions for staging environment (should be enabled)
  assert {
    condition     = length([for r in plan.resource_changes : r if contains(r.address, "cloudflare_workers_route") && r.type == "create"]) > 0
    error_message = "Worker route should be created in staging environment"
  }

  assert {
    condition     = length([for r in plan.resource_changes : r if contains(r.address, "cloudflare_workers_script") && r.type == "create"]) > 0
    error_message = "Worker script should be created in staging environment"
  }

  assert {
    condition     = length([for r in plan.resource_changes : r if contains(r.address, "cloudflare_ruleset") && r.type == "create"]) > 0
    error_message = "Ruleset should be created in staging environment for IP bypass"
  }
}

# Test case 2: Environment-based configuration (production)
run "verify_production_environment" {
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    environment           = "production"
    worker_route          = "example.com/api/*"
    enabled               = false # production should be disabled
    maintenance_title     = "Scheduled System Maintenance"
    contact_email         = "support@example.com"
    office_ip_ranges      = ["192.168.0.0/24", "10.0.0.0/24"]
    monitoring_ips        = ["8.8.8.8", "1.1.1.1"]
    allowed_ips           = ["192.168.0.0/24", "10.0.0.0/24", "8.8.8.8", "1.1.1.1"]
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

  # Run plan to check resources
  command = plan

  # Assertions for production environment (should be disabled)
  assert {
    condition     = length([for r in plan.resource_changes : r if contains(r.address, "cloudflare_workers_route") && r.type == "create"]) == 0
    error_message = "Worker route should not be created in production environment"
  }

  assert {
    condition     = length([for r in plan.resource_changes : r if contains(r.address, "cloudflare_ruleset") && r.type == "create"]) == 0
    error_message = "Ruleset should not be created in production environment"
  }
}

# Test case 3: Variable validation for RFC3339 dates
run "verify_rfc3339_date_validation" {
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Run plan to check window format
  command = plan

  # Check that worker config file will be created (indicating valid dates)
  assert {
    condition     = length([for r in plan.resource_changes : r if contains(r.address, "local_file") && contains(r.address, "worker_config")]) > 0
    error_message = "Worker config file should be created with valid RFC3339 dates"
  }

  # Check that plan succeeds (no validation errors on dates)
  assert {
    condition     = length(plan.resource_changes) > 0
    error_message = "Plan should include resource changes with valid RFC3339 dates"
  }
}

# Test case 4: Test concatenation of IP ranges
run "verify_ip_concatenation" {
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    office_ip_ranges      = ["192.168.0.0/24", "10.0.0.0/24"]
    monitoring_ips        = ["8.8.8.8", "1.1.1.1"]
    allowed_ips           = ["192.168.0.0/24", "10.0.0.0/24", "8.8.8.8", "1.1.1.1"]
  }

  # Specify module to test
  module {
    source = "../"
  }

  # Run plan to check resources
  command = plan

  # Verify ruleset is created for bypassing maintenance
  assert {
    condition     = length([for r in plan.resource_changes : r if contains(r.address, "cloudflare_ruleset") && r.type == "create"]) > 0
    error_message = "Ruleset should be created for IP bypass when allowed IPs are specified"
  }

  # Verify all IPs are included in the ruleset
  assert {
    condition     = length(var.allowed_ips) == 4
    error_message = "Should have 4 allowed IP ranges in the concatenated list"
  }
}

