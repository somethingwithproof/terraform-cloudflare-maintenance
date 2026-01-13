output "notification_count" {
  description = "Number of notifications configured"
  value       = length(var.notification_urls)
}

output "notification_types" {
  description = "Types of notifications configured"
  value = [
    for url in var.notification_urls :
    startswith(url, "slack://") ? "slack" :
    startswith(url, "pagerduty://") ? "pagerduty" :
    startswith(url, "webhook://") ? "webhook" :
    "unknown"
  ]
}
