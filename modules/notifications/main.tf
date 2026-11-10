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

  dedup_key = "terraform-cloudflare-maintenance/${var.environment}/${var.schedule_name}"

  # Everything below is non-secret and is stored in state as the replacement
  # trigger, so a notification is sent only when one of these values changes.
  event = {
    status = var.maintenance_status
    action = (
      contains(local.resolving_statuses, var.maintenance_status) ? "resolve" :
      contains(local.silent_statuses, var.maintenance_status) ? "none" : "trigger"
    )
    schedule_name = var.schedule_name
    environment   = var.environment
    start_time    = local.window.start_time
    end_time      = local.window.end_time
  }

  # Statuses that end maintenance. PagerDuty receives a resolve event for them,
  # matched to the earlier trigger by dedup key.
  resolving_statuses = ["DISABLED", "COMPLETED"]

  # A window that has not started yet pages nobody: PagerDuty gets no event,
  # Slack and webhooks get an informational message. An apply cannot see
  # the window open or close, so it never triggers or resolves at those
  # moments; see the README.
  silent_statuses = ["SCHEDULED"]

  # Where the outgoing incident key is handed to a replacement (see
  # notify.sh). Under .terraform so it stays out of version control.
  state_dir = "${path.root}/.terraform/maintenance-notifications"
}

resource "terraform_data" "notification" {
  for_each = local.notification_names

  triggers_replace = local.event

  # Not secret. When the event changes, this instance is replaced: its
  # destroy-time provisioner records the incident it announced, and the
  # replacement resolves that incident if the key changed or nothing is
  # triggered any more.
  input = {
    dedup_key  = local.dedup_key
    action     = local.event.action
    state_file = "${local.state_dir}/${sha1(each.key)}.json"
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/sh"]
    command     = "${path.module}/notify.sh"
    environment = {
      NOTIFY_MODE = "record"
      # Destroy-time provisioners can only read self. try(): instances
      # created before input existed have none, and record nothing.
      NOTIFY_STATE_FILE = try(self.input.state_file, "")
      NOTIFY_DEDUP_KEY  = try(self.input.dedup_key, "none")
      NOTIFY_ACTION     = try(self.input.action, "none")
    }
  }

  provisioner "local-exec" {
    interpreter = ["/bin/sh"]
    command     = "${path.module}/notify.sh"
    environment = {
      NOTIFY_STATE_FILE  = self.input.state_file
      NOTIFY_URL         = var.notification_urls[each.key]
      NOTIFY_STATUS      = local.event.status
      NOTIFY_ACTION      = local.event.action
      NOTIFY_SCHEDULE    = local.event.schedule_name
      NOTIFY_ENVIRONMENT = local.event.environment
      NOTIFY_START       = local.event.start_time
      NOTIFY_END         = local.event.end_time
      NOTIFY_DEDUP_KEY   = local.dedup_key
    }
  }
}
