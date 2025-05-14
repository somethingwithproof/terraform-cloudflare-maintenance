run "test_enabled_maintenance" {
  # Define variables for module under test 
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

  # Run apply to create resources
  command = apply

  # Check expected resources after apply
  assert {
    condition     = module.cloudflare_workers_script["maintenance_worker"] != null
    error_message = "Worker script should be created when maintenance is enabled"
  }

  assert {
    condition     = module.cloudflare_workers_route["maintenance_route"][0] != null
    error_message = "Worker route should be created when maintenance is enabled"
  }
}

run "test_disabled_maintenance" {
  # Define variables for module under test
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

  # Apply with maintenance disabled
  command = apply

  # Verify results are as expected
  assert {
    condition     = length(module.cloudflare_workers_route) == 0
    error_message = "Worker route should not be created when maintenance is disabled"
  }
}

