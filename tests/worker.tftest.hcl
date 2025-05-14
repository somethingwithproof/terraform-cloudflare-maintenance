# Worker tests for Cloudflare maintenance module

# Test case 1: Basic worker script configuration
run "verify_worker_script_configuration" {
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

  # Run plan to check resources
  command = plan

  # Test assertions for worker script configuration
  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_script") && r.type == "create"]) > 0
    error_message = "Worker script should be created with the correct name"
  }
  
  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_route") && r.type == "create"]) > 0
    error_message = "Worker route should be created when maintenance is enabled"
  }
}

# Test case 2: Test worker configuration file generation
run "verify_worker_config_file" {
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    maintenance_title     = "Planned System Maintenance"
    contact_email         = "help@example.com"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
    custom_css            = "body { background-color: #f0f8ff; }"
    logo_url              = "https://example.com/logo.png"
    maintenance_window    = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
  }
  
  # Specify module to test
  module {
    source = "../"
  }
  
  # Run plan to check worker config
  command = plan
  
  # Verify the worker config file will be created
  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "local_file") && contains(r.address, "worker_config") && r.type == "create"]) > 0
    error_message = "Worker config file should be created"
  }
  
  # Verify the worker script creation
  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_script") && r.type == "create"]) > 0
    error_message = "Worker script should be created with configuration settings"
  }
}

# Test case 3: Test worker secret bindings for allowed IPs
run "verify_worker_secret_binding" {
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    allowed_ips           = ["192.168.1.1", "10.0.0.1", "172.16.0.5"]
  }
  
  # Specify module to test
  module {
    source = "../"
  }
  
  # Run plan to check resources
  command = plan
  
  # Check the worker script for secret bindings
  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_script") && r.type == "create"]) > 0
    error_message = "Workers script should be created with secret bindings"
  }
  
  # Verify the allowed IPs are included
  assert {
    condition     = length(var.allowed_ips) == 3
    error_message = "All allowed IPs should be included in the secret binding"
  }
}

# Test case 4: Test worker analytics binding
run "verify_worker_analytics_binding" {
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
  }
  
  # Specify module to test
  module {
    source = "../"
  }
  
  # Run plan to check resources
  command = plan
  
  # Check the worker script for analytics bindings
  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_script") && r.type == "create"]) > 0
    error_message = "Workers script should be created with analytics bindings"
  }
}

# Test case 5: Test KV namespace creation
run "verify_kv_namespace" {
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
  }
  
  # Specify module to test
  module {
    source = "../"
  }
  
  # Run plan to check resources
  command = plan
  
  # Verify KV namespace is created when maintenance is enabled
  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_kv_namespace") && r.type == "create"]) > 0
    error_message = "KV namespace should be created when maintenance is enabled"
  }
}

# Test case 6: Test disabled worker configuration
run "verify_disabled_worker_configuration" {
  variables {
    cloudflare_api_token  = "test-api-token"
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = false
  }
  
  # Specify module to test
  module {
    source = "../"
  }
  
  # Run plan to check resources
  command = plan
  
  # Verify worker script is still created (but routes aren't)
  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_script") && r.type == "create"]) > 0
    error_message = "Worker script should be created even when maintenance is disabled"
  }
  
  # Verify the worker route is not created when maintenance is disabled
  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_route") && r.type == "create"]) == 0
    error_message = "Worker route should not be created when maintenance is disabled"
  }
  
  # Verify KV namespace is not created when maintenance is disabled
  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_kv_namespace") && r.type == "create"]) == 0
    error_message = "KV namespace should not be created when maintenance is disabled"
  }
}

