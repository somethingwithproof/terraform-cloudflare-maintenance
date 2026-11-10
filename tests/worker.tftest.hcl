# Worker bindings and input validation.

mock_provider "cloudflare" {}

variables {
  cloudflare_account_id = "0123456789abcdef0123456789abcdef"
  cloudflare_zone_id    = "fedcba9876543210fedcba9876543210"
  worker_route          = "example.com/*"
  environment           = "test"
  enabled               = true
}

run "bindings_carry_page_settings" {
  command = plan

  variables {
    maintenance_title   = "Planned System Maintenance"
    maintenance_message = "Back soon."
    contact_email       = "help@example.com"
    custom_css          = "body { background-color: #f0f8ff; }"
    logo_url            = "https://example.com/logo.png"
    allowed_ips         = ["192.0.2.1", "198.51.100.0/24"]
    allowed_regions     = ["US", "CA"]
  }

  assert {
    condition = {
      for b in cloudflare_workers_script.maintenance.bindings : b.name => b.text
      } == {
      MAINTENANCE_ENABLED      = "true"
      MAINTENANCE_TITLE        = "Planned System Maintenance"
      MAINTENANCE_MESSAGE      = "Back soon."
      CONTACT_EMAIL            = "help@example.com"
      CUSTOM_CSS               = "body { background-color: #f0f8ff; }"
      LOGO_URL                 = "https://example.com/logo.png"
      MAINTENANCE_WINDOW_START = ""
      MAINTENANCE_WINDOW_END   = ""
      ALLOWED_IPS              = jsonencode(["192.0.2.1", "198.51.100.0/24"])
      ALLOWED_REGIONS          = jsonencode(["US", "CA"])
    }
    error_message = "Worker bindings should carry every page setting"
  }

  assert {
    condition = {
      for b in cloudflare_workers_script.maintenance.bindings : b.name => b.type
      if contains(["ALLOWED_IPS", "ALLOWED_REGIONS"], b.name)
      } == {
      ALLOWED_IPS     = "secret_text"
      ALLOWED_REGIONS = "secret_text"
    }
    error_message = "Allowlists should be bound as secrets"
  }
}

run "bindings_carry_maintenance_window" {
  command = plan

  variables {
    maintenance_window = {
      start_time = "2025-04-06T08:00:00Z"
      end_time   = "2025-04-06T10:00:00Z"
    }
  }

  assert {
    condition = {
      for b in cloudflare_workers_script.maintenance.bindings : b.name => b.text
      if startswith(b.name, "MAINTENANCE_WINDOW_")
      } == {
      MAINTENANCE_WINDOW_START = "2025-04-06T08:00:00Z"
      MAINTENANCE_WINDOW_END   = "2025-04-06T10:00:00Z"
    }
    error_message = "Worker bindings should carry the maintenance window"
  }

  assert {
    condition     = output.maintenance_window == var.maintenance_window
    error_message = "maintenance_window output should echo the input"
  }
}

run "reject_non_rfc3339_window" {
  command = plan

  variables {
    maintenance_window = {
      start_time = "2025-04-06 08:00"
      end_time   = "2025-04-06T10:00:00Z"
    }
  }

  expect_failures = [var.maintenance_window]
}

run "reject_malformed_allowed_ip" {
  command = plan

  variables {
    allowed_ips = ["192.0.2.1", "198.51.100.0/33"]
  }

  expect_failures = [var.allowed_ips]
}

run "accept_ipv4_ipv6_and_cidr_allowed_ips" {
  command = plan

  variables {
    allowed_ips = ["192.0.2.1", "198.51.100.0/24", "2001:db8::1", "2001:db8::/32", "::ffff:192.0.2.1"]
  }

  assert {
    condition     = one([for b in cloudflare_workers_script.maintenance.bindings : b.text if b.name == "ALLOWED_IPS"]) == jsonencode(var.allowed_ips)
    error_message = "ALLOWED_IPS binding should carry the allowlist as JSON"
  }
}

run "reject_lowercase_region" {
  command = plan

  variables {
    allowed_regions = ["us"]
  }

  expect_failures = [var.allowed_regions]
}
