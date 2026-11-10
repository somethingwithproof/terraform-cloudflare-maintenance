# Core resources: the Worker script is always deployed; the route whenever
# maintenance is enabled or a maintenance window is set. Plans run against a mocked provider, so no test
# ever calls the Cloudflare API.

mock_provider "cloudflare" {}

variables {
  cloudflare_account_id = "0123456789abcdef0123456789abcdef"
  cloudflare_zone_id    = "fedcba9876543210fedcba9876543210"
  worker_route          = "example.com/*"
  environment           = "test"
}

run "enabled_deploys_script_and_route" {
  command = plan

  variables {
    enabled = true
  }

  assert {
    condition     = cloudflare_workers_script.maintenance.script_name == "maintenance-page-worker"
    error_message = "Worker script should be named maintenance-page-worker"
  }

  assert {
    condition     = cloudflare_workers_script.maintenance.account_id == var.cloudflare_account_id
    error_message = "Worker script should be deployed to the configured account"
  }

  assert {
    condition     = cloudflare_workers_script.maintenance.content == file("${path.module}/worker.js")
    error_message = "Worker script content should be worker.js"
  }

  assert {
    condition     = length(cloudflare_workers_route.maintenance) == 1
    error_message = "Exactly one Worker route should be planned when enabled"
  }

  assert {
    condition     = cloudflare_workers_route.maintenance[0].pattern == "example.com/*"
    error_message = "Worker route should use worker_route as its pattern"
  }

  assert {
    condition     = cloudflare_workers_route.maintenance[0].script == "maintenance-page-worker"
    error_message = "Worker route should point at the maintenance Worker"
  }

  assert {
    condition     = cloudflare_workers_route.maintenance[0].zone_id == var.cloudflare_zone_id
    error_message = "Worker route should be created in the configured zone"
  }

  assert {
    condition     = output.maintenance_status == "ENABLED" && output.worker_route_pattern == "example.com/*"
    error_message = "Outputs should report the enabled route"
  }
}

run "disabled_deploys_script_without_route" {
  command = plan

  variables {
    enabled = false
  }

  assert {
    condition     = cloudflare_workers_script.maintenance.script_name == "maintenance-page-worker"
    error_message = "Worker script should still be deployed when disabled"
  }

  assert {
    condition     = length(cloudflare_workers_route.maintenance) == 0
    error_message = "No Worker route should be planned when disabled"
  }

  assert {
    condition     = output.maintenance_status == "DISABLED" && output.worker_route_pattern == "Maintenance mode disabled"
    error_message = "Outputs should report maintenance as disabled"
  }
}

run "no_zone_rulesets_by_default" {
  command = plan

  variables {
    enabled         = true
    allowed_ips     = ["192.0.2.1"]
    allowed_regions = ["US"]
  }

  assert {
    condition     = length(cloudflare_ruleset.rate_limit) == 0
    error_message = "Bypass lists must not create zone rulesets"
  }
}

run "window_without_enabled_deploys_route" {
  command = plan

  variables {
    enabled = false
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
  }

  assert {
    condition     = length(cloudflare_workers_route.maintenance) == 1
    error_message = "A scheduled window should deploy the route even when enabled is false"
  }

  assert {
    condition     = cloudflare_workers_route.maintenance[0].pattern == "example.com/*"
    error_message = "Scheduled route should use worker_route as its pattern"
  }

  assert {
    condition     = output.maintenance_status == "SCHEDULED" && output.worker_route_pattern == "example.com/*"
    error_message = "Outputs should report the scheduled route"
  }
}

run "window_with_enabled_deploys_one_route" {
  command = plan

  variables {
    enabled = true
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
  }

  assert {
    condition     = length(cloudflare_workers_route.maintenance) == 1
    error_message = "Exactly one route should be planned when enabled with a window"
  }

  assert {
    condition     = output.maintenance_status == "SCHEDULED"
    error_message = "A window should take precedence over enabled in maintenance_status"
  }
}

run "reject_window_ending_before_it_starts" {
  command = plan

  variables {
    maintenance_window = {
      start_time = "2025-04-06T10:00:00Z"
      end_time   = "2025-04-06T08:00:00Z"
    }
  }

  expect_failures = [var.maintenance_window]
}

run "reject_empty_window" {
  command = plan

  variables {
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T08:00:00Z"
    }
  }

  expect_failures = [var.maintenance_window]
}
