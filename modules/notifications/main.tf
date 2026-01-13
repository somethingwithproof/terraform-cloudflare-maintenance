# Notification module for maintenance windows
# Supports Slack, PagerDuty, and generic webhook notifications

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2, < 4.0"
    }
  }
}

# Parse notification URLs and send notifications
resource "null_resource" "notification" {
  for_each = { for idx, url in var.notification_urls : idx => url if url != "" }

  triggers = {
    maintenance_status = var.maintenance_status
    schedule_name      = var.schedule_name
    timestamp          = timestamp()
    notification_url   = each.value
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${local.notification_commands[each.key]}
    EOT
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # Categorize notification URLs by type
  slack_urls      = [for url in var.notification_urls : url if startswith(url, "slack://")]
  pagerduty_urls  = [for url in var.notification_urls : url if startswith(url, "pagerduty://")]
  webhook_urls    = [for url in var.notification_urls : url if startswith(url, "webhook://")]

  # Create notification commands for each URL with proper type detection
  notification_commands = {
    for idx, url in var.notification_urls :
    idx => contains(local.slack_urls, url) ? replace(local.slack_notification_template, "{{URL}}", replace(url, "slack://", "https://hooks.slack.com/services/")) :
    contains(local.pagerduty_urls, url) ? replace(local.pagerduty_notification_template, "{{KEY}}", replace(url, "pagerduty://", "")) :
    contains(local.webhook_urls, url) ? replace(local.webhook_notification_template, "{{URL}}", replace(url, "webhook://", "")) :
    "echo 'Unknown notification type: ${url}'"
  }

  # Slack notification template
  slack_notification_template = <<-EOT
    curl -X POST '{{URL}}' \
      -H 'Content-Type: application/json' \
      -d '{
        "text": "🔧 Maintenance ${var.maintenance_status}",
        "blocks": [
          {
            "type": "header",
            "text": {
              "type": "plain_text",
              "text": "Maintenance ${var.maintenance_status}: ${var.schedule_name}"
            }
          },
          {
            "type": "section",
            "fields": [
              {
                "type": "mrkdwn",
                "text": "*Status:*\n${var.maintenance_status}"
              },
              {
                "type": "mrkdwn",
                "text": "*Window:*\n${var.maintenance_window.start_time} - ${var.maintenance_window.end_time}"
              },
              {
                "type": "mrkdwn",
                "text": "*Environment:*\n${var.environment}"
              },
              {
                "type": "mrkdwn",
                "text": "*Schedule:*\n${var.schedule_name}"
              }
            ]
          }
        ]
      }'
  EOT

  # PagerDuty notification template
  pagerduty_notification_template = <<-EOT
    curl -X POST 'https://events.pagerduty.com/v2/enqueue' \
      -H 'Content-Type: application/json' \
      -d '{
        "routing_key": "{{KEY}}",
        "event_action": "trigger",
        "payload": {
          "summary": "Maintenance ${var.maintenance_status}: ${var.schedule_name}",
          "severity": "warning",
          "source": "terraform-cloudflare-maintenance",
          "custom_details": {
            "status": "${var.maintenance_status}",
            "environment": "${var.environment}",
            "schedule": "${var.schedule_name}",
            "start_time": "${var.maintenance_window.start_time}",
            "end_time": "${var.maintenance_window.end_time}"
          }
        }
      }'
  EOT

  # Generic webhook notification template
  webhook_notification_template = <<-EOT
    curl -X POST '{{URL}}' \
      -H 'Content-Type: application/json' \
      -d '{
        "status": "${var.maintenance_status}",
        "schedule_name": "${var.schedule_name}",
        "environment": "${var.environment}",
        "maintenance_window": {
          "start_time": "${var.maintenance_window.start_time}",
          "end_time": "${var.maintenance_window.end_time}"
        }
      }'
  EOT
}
