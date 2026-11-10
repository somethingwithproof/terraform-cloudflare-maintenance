# Optional zone rate limiting rule.

mock_provider "cloudflare" {}

variables {
  cloudflare_api_token  = "test-api-token"
  cloudflare_account_id = "0123456789abcdef0123456789abcdef"
  cloudflare_zone_id    = "fedcba9876543210fedcba9876543210"
  worker_route          = "example.com/*"
}

run "disabled_by_default" {
  command = plan

  assert {
    condition     = length(cloudflare_ruleset.rate_limit) == 0
    error_message = "No rate limiting ruleset should be planned by default"
  }

  assert {
    condition     = output.rate_limit_enabled == false && output.rate_limit_ruleset_id == null
    error_message = "Outputs should report rate limiting as disabled"
  }
}

run "enabled_plans_one_ratelimit_rule" {
  command = plan

  variables {
    rate_limit = {
      enabled             = true
      requests_per_period = 50
      period              = 30
      action              = "managed_challenge"
      mitigation_timeout  = 300
    }
  }

  assert {
    condition     = length(cloudflare_ruleset.rate_limit) == 1
    error_message = "One rate limiting ruleset should be planned"
  }

  assert {
    condition = (
      cloudflare_ruleset.rate_limit[0].kind == "zone" &&
      cloudflare_ruleset.rate_limit[0].phase == "http_ratelimit" &&
      cloudflare_ruleset.rate_limit[0].zone_id == var.cloudflare_zone_id
    )
    error_message = "Ruleset should be the zone's http_ratelimit entry point"
  }

  assert {
    condition     = length(cloudflare_ruleset.rate_limit[0].rules) == 1
    error_message = "Ruleset should hold exactly one rule"
  }

  assert {
    condition = (
      cloudflare_ruleset.rate_limit[0].rules[0].action == "managed_challenge" &&
      cloudflare_ruleset.rate_limit[0].rules[0].expression == "true" &&
      cloudflare_ruleset.rate_limit[0].rules[0].enabled
    )
    error_message = "Rule should apply the configured action to every request"
  }

  assert {
    condition = (
      cloudflare_ruleset.rate_limit[0].rules[0].ratelimit.period == 30 &&
      cloudflare_ruleset.rate_limit[0].rules[0].ratelimit.requests_per_period == 50 &&
      cloudflare_ruleset.rate_limit[0].rules[0].ratelimit.mitigation_timeout == 300 &&
      cloudflare_ruleset.rate_limit[0].rules[0].ratelimit.requests_to_origin == false &&
      toset(cloudflare_ruleset.rate_limit[0].rules[0].ratelimit.characteristics) == toset(["cf.colo.id", "ip.src"])
    )
    error_message = "Rule should carry the configured rate limit"
  }

  assert {
    condition     = output.rate_limit_enabled == true
    error_message = "rate_limit_enabled output should be true"
  }
}

run "boundary_values_are_accepted" {
  command = plan

  variables {
    rate_limit = {
      enabled            = true
      period             = 86400
      mitigation_timeout = 60
    }
  }

  assert {
    condition = (
      cloudflare_ruleset.rate_limit[0].rules[0].ratelimit.period == 86400 &&
      cloudflare_ruleset.rate_limit[0].rules[0].ratelimit.mitigation_timeout == 60 &&
      cloudflare_ruleset.rate_limit[0].rules[0].action == "block"
    )
    error_message = "Boundary values and the default action should be planned"
  }
}

run "reject_period_below_minimum" {
  command = plan

  variables {
    rate_limit = { enabled = true, period = 9 }
  }

  expect_failures = [var.rate_limit]
}

run "reject_unknown_action" {
  command = plan

  variables {
    rate_limit = { enabled = true, action = "drop" }
  }

  expect_failures = [var.rate_limit]
}

run "reject_mitigation_timeout_above_maximum" {
  command = plan

  variables {
    rate_limit = { enabled = true, mitigation_timeout = 86401 }
  }

  expect_failures = [var.rate_limit]
}
