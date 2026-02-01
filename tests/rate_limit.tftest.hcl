# Rate Limiting Tests for Cloudflare Maintenance Module

# Test case 1: Rate limiting enabled with default settings
run "verify_rate_limit_enabled_default" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    rate_limit = {
      enabled             = true
      requests_per_period = 100
      period              = 60
      action              = "block"
      mitigation_timeout  = 600
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "Rate limiting should be enabled"
  }

  assert {
    condition     = output.rate_limit_ruleset_id != null
    error_message = "Rate limit ruleset should be created"
  }
}

# Test case 2: Rate limiting with challenge action
run "verify_rate_limit_challenge_action" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    rate_limit = {
      enabled             = true
      requests_per_period = 50
      period              = 30
      action              = "challenge"
      mitigation_timeout  = 300
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "Rate limiting should be enabled with challenge action"
  }

  assert {
    condition     = output.rate_limit_ruleset_id != null
    error_message = "Rate limit ruleset should be created for challenge action"
  }
}

# Test case 3: Rate limiting with JS challenge action
run "verify_rate_limit_js_challenge_action" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    rate_limit = {
      enabled             = true
      requests_per_period = 200
      period              = 120
      action              = "js_challenge"
      mitigation_timeout  = 900
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "Rate limiting should be enabled with JS challenge action"
  }
}

# Test case 4: Rate limiting with managed challenge action
run "verify_rate_limit_managed_challenge_action" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    rate_limit = {
      enabled             = true
      requests_per_period = 100
      period              = 60
      action              = "managed_challenge"
      mitigation_timeout  = 600
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "Rate limiting should be enabled with managed challenge action"
  }
}

# Test case 5: Rate limiting with log action (audit mode)
run "verify_rate_limit_log_action" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    rate_limit = {
      enabled             = true
      requests_per_period = 100
      period              = 60
      action              = "log"
      mitigation_timeout  = 600
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "Rate limiting should be enabled with log action"
  }
}

# Test case 6: Rate limiting disabled
run "verify_rate_limit_disabled" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    rate_limit = {
      enabled = false
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == false
    error_message = "Rate limiting should be disabled"
  }

  assert {
    condition     = output.rate_limit_ruleset_id == null
    error_message = "Rate limit ruleset should not be created when disabled"
  }
}

# Test case 7: Rate limiting with high request threshold
run "verify_rate_limit_high_threshold" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    rate_limit = {
      enabled             = true
      requests_per_period = 1000
      period              = 60
      action              = "block"
      mitigation_timeout  = 600
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "Rate limiting should support high request thresholds"
  }
}

# Test case 8: Rate limiting with long period
run "verify_rate_limit_long_period" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    rate_limit = {
      enabled             = true
      requests_per_period = 500
      period              = 3600  # 1 hour
      action              = "block"
      mitigation_timeout  = 7200  # 2 hours
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "Rate limiting should support long periods"
  }
}

# Test case 9: Combined rate limiting with maintenance features
run "verify_rate_limit_with_maintenance_features" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "production"
    worker_route          = "example.com/*"
    allowed_ips           = ["192.168.1.1", "10.0.0.1"]
    allowed_regions       = ["US", "CA"]
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
    rate_limit = {
      enabled             = true
      requests_per_period = 100
      period              = 60
      action              = "block"
      mitigation_timeout  = 600
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "Rate limiting should work with other maintenance features"
  }

  assert {
    condition     = output.ruleset_id != "No ruleset created"
    error_message = "IP/Region bypass ruleset should be created"
  }

  assert {
    condition     = output.maintenance_window.start_time == "2025-04-06T08:00:00Z"
    error_message = "Maintenance window should be configured"
  }
}

# Test case 10: Rate limiting minimum period (boundary test)
run "verify_rate_limit_minimum_period" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    rate_limit = {
      enabled             = true
      requests_per_period = 10
      period              = 10  # Minimum allowed period
      action              = "block"
      mitigation_timeout  = 60  # Minimum allowed timeout
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "Rate limiting should work with minimum period"
  }
}

# Test case 11: Rate limiting maximum period (boundary test)
run "verify_rate_limit_maximum_period" {
  variables {
    cloudflare_account_id = "test-account-id"
    cloudflare_zone_id    = "test-zone-id"
    enabled               = true
    environment           = "test"
    worker_route          = "example.com/*"
    rate_limit = {
      enabled             = true
      requests_per_period = 10000
      period              = 86400  # Maximum allowed period (24 hours)
      action              = "block"
      mitigation_timeout  = 86400  # Maximum allowed timeout
    }
  }

  module {
    source = "../"
  }

  command = apply

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "Rate limiting should work with maximum period"
  }
}
