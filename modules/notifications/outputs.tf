output "notification_count" {
  description = "Number of notification targets configured"
  value       = length(local.notification_names)
}

output "notification_types" {
  description = "Notification type (slack, pagerduty or webhook) for each target name"
  # The URL scheme is not secret, so it is safe to expose.
  value = { for name in local.notification_names : name => nonsensitive(split("://", var.notification_urls[name])[0]) }
}

output "event_action" {
  description = "PagerDuty event action this status sends: trigger or resolve"
  value       = local.event.action
}
