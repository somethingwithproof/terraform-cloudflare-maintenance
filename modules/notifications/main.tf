# Sends a Slack, PagerDuty or generic webhook notification on each apply that
# changes the maintenance status or window.

terraform {
  required_version = ">= 1.6.0"
}

locals {
  # Target names are not secret and key the resources; the URLs they map to
  # are secret and only ever reach notify.sh through the environment.
  notification_names = nonsensitive(toset(keys(var.notification_urls)))

  window = coalesce(var.maintenance_window, { start_time = "", end_time = "" })

  # Everything below is non-secret and is stored in state as the replacement
  # trigger, so a notification is sent only when one of these values changes.
  event = {
    status        = var.maintenance_status
    action        = contains(local.resolving_statuses, var.maintenance_status) ? "resolve" : "trigger"
    schedule_name = var.schedule_name
    environment   = var.environment
    start_time    = local.window.start_time
    end_time      = local.window.end_time
  }

  # Statuses that end maintenance. PagerDuty receives a resolve event for them,
  # matched to the earlier trigger by dedup key.
  resolving_statuses = ["DISABLED", "COMPLETED"]
}

resource "terraform_data" "notification" {
  for_each = local.notification_names

  triggers_replace = local.event

  provisioner "local-exec" {
    interpreter = ["/bin/sh"]
    command     = "${path.module}/notify.sh"
    environment = {
      NOTIFY_URL         = var.notification_urls[each.key]
      NOTIFY_STATUS      = local.event.status
      NOTIFY_ACTION      = local.event.action
      NOTIFY_SCHEDULE    = local.event.schedule_name
      NOTIFY_ENVIRONMENT = local.event.environment
      NOTIFY_START       = local.event.start_time
      NOTIFY_END         = local.event.end_time
      NOTIFY_DEDUP_KEY   = "terraform-cloudflare-maintenance/${var.environment}/${var.schedule_name}"
    }
  }
}
