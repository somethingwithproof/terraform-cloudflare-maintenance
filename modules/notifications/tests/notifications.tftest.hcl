# Plans only: provisioners never run, so nothing is sent.

variables {
  notification_urls = {
    ops_slack = "slack://T000/B000/XXXXXXXX"
    oncall    = "pagerduty://routing-key-123"
    audit     = "webhook://https://hooks.example.com/maintenance"
  }
  maintenance_status = "SCHEDULED"
  schedule_name      = "weekly"
  environment        = "production"
  maintenance_window = {
    start_time = "2030-04-06T08:00:00Z"
    end_time   = "2030-04-06T10:00:00Z"
  }
}

run "sensitive_urls_key_one_notification_per_name" {
  command = plan

  assert {
    condition     = toset(keys(terraform_data.notification)) == toset(["ops_slack", "oncall", "audit"])
    error_message = "One notification should be planned per target name"
  }

  assert {
    condition     = output.notification_types == { ops_slack = "slack", oncall = "pagerduty", audit = "webhook" }
    error_message = "Types should be derived from the URL schemes"
  }

  assert {
    condition     = output.notification_count == 3
    error_message = "Count should match the number of targets"
  }
}

run "triggers_hold_only_status_and_window" {
  command = plan

  assert {
    condition = terraform_data.notification["oncall"].triggers_replace == {
      status        = "SCHEDULED"
      action        = "trigger"
      schedule_name = "weekly"
      environment   = "production"
      start_time    = "2030-04-06T08:00:00Z"
      end_time      = "2030-04-06T10:00:00Z"
    }
    error_message = "Triggers should hold the status and window and nothing else"
  }

  assert {
    condition = alltrue([
      for name, n in terraform_data.notification : !anytrue([
        for v in values(n.triggers_replace) : strcontains(v, "routing-key") || strcontains(v, "XXXXXXXX") || strcontains(v, "hooks.example.com")
      ])
    ])
    error_message = "No notification URL or key may appear in the triggers"
  }
}

run "ending_maintenance_resolves" {
  command = plan

  variables {
    maintenance_status = "DISABLED"
    maintenance_window = null
  }

  assert {
    condition     = output.event_action == "resolve"
    error_message = "DISABLED should send a resolve event"
  }

  assert {
    condition     = terraform_data.notification["oncall"].triggers_replace.start_time == ""
    error_message = "A null window should be sent as empty times"
  }
}

run "no_targets_plans_nothing" {
  command = plan

  variables {
    notification_urls = {}
  }

  assert {
    condition     = length(terraform_data.notification) == 0 && output.notification_count == 0
    error_message = "No notifications should be planned without targets"
  }
}

run "reject_unknown_scheme" {
  command = plan

  variables {
    notification_urls = { bad = "smtp://ops@example.com" }
  }

  expect_failures = [var.notification_urls]
}

run "reject_plain_http_webhook" {
  command = plan

  variables {
    notification_urls = { bad = "webhook://http://hooks.example.com/x" }
  }

  expect_failures = [var.notification_urls]
}

run "reject_unknown_status" {
  command = plan

  variables {
    maintenance_status = "PAUSED"
  }

  expect_failures = [var.maintenance_status]
}
