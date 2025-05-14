run "verify_worker_script_configuration" {
  # Define variables for module under test
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "Worker Script Test"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "../"
  }

  # Apply the configuration
  command = apply

  # Verify worker script is created
  assert {
    condition     = module.cloudflare_workers_script["maintenance_worker"].name != ""
    error_message = "Worker script should be created"
  }
}

run "verify_worker_config_file" {
  # Define variables for module under test
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "Config File Test"
    contact_email         = "support@example.com"
    environment           = "staging"
    custom_css            = "body { background-color: #f5f5f5; }"
  }

  module {
    source = "../"
  }

  # Apply the configuration
  command = apply

  # Verify worker config file is created
  assert {
    condition     = module.local_file["worker_config"].filename != ""
    error_message = "Worker config file should be created"
  }
}

run "verify_worker_secret_binding" {
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "Secret Binding Test"
    contact_email         = "support@example.com"
    environment           = "staging"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
  }

  module {
    source = "../"
  }

  # Apply the configuration
  command = apply

  # Verify worker script with bindings is created
  assert {
    condition     = module.cloudflare_workers_script["maintenance_worker"].name != ""
    error_message = "Worker script with bindings should be created"
  }
}

run "verify_worker_analytics_binding" {
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "Analytics Binding Test"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "../"
  }

  # Apply the configuration
  command = apply

  # Verify worker script with analytics binding is created
  assert {
    condition     = module.cloudflare_workers_script["maintenance_worker"].name != ""
    error_message = "Worker script with analytics binding should be created"
  }
}

run "verify_kv_namespace" {
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = true
    worker_route          = "*.example.com/*"
    maintenance_title     = "KV Namespace Test"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "../"
  }

  # Apply the configuration
  command = apply

  # Verify KV namespace is created
  assert {
    condition     = module.cloudflare_workers_kv_namespace["maintenance_kv"][0].title != ""
    error_message = "Worker KV namespace should be created when maintenance is enabled"
  }
}

run "verify_disabled_worker_configuration" {
  variables {
    cloudflare_api_token  = "00000000000000000000000000000000000000aa"
    cloudflare_account_id = "0000000000000000000000000000000000000000"
    cloudflare_zone_id    = "0000000000000000000000000000000000000000"
    enabled               = false
    worker_route          = "*.example.com/*"
    maintenance_title     = "Disabled Worker Test"
    contact_email         = "support@example.com"
    environment           = "staging"
  }

  module {
    source = "../"
  }

  # Apply the configuration
  command = apply

  # Verify worker route is not created when disabled
  assert {
    condition     = length(module.cloudflare_workers_route) == 0
    error_message = "Worker route should not be created when maintenance is disabled"
  }

  # Verify KV namespace is not created when disabled
  assert {
    condition     = length(module.cloudflare_workers_kv_namespace) == 0
    error_message = "Worker KV namespace should not be created when maintenance is disabled"
  }
}

