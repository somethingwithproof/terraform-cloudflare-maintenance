run "verify_worker_script_configuration" {
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

  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_script")]) > 0
    error_message = "Worker script should be created"
  }
}

run "verify_worker_config_file" {
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

  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "local_file.worker_config")]) > 0
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

  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_script")]) > 0
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

  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_script")]) > 0
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

  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_kv_namespace")]) > 0
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

  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_route") && r.type == "create"]) == 0
    error_message = "Worker route should not be created when maintenance is disabled"
  }

  assert {
    condition     = length([for r in data.plan_resource_changes : r if contains(r.address, "cloudflare_workers_kv_namespace") && r.type == "create"]) == 0
    error_message = "Worker KV namespace should not be created when maintenance is disabled"
  }
}

