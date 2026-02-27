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
    environment = {
      WEBHOOK_URL = local.resolved_urls[each.key]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # Categorize notification URLs by type
  slack_urls     = [for url in var.notification_urls : url if startswith(url, "slack://")]
  pagerduty_urls = [for url in var.notification_urls : url if startswith(url, "pagerduty://")]
  webhook_urls   = [for url in var.notification_urls : url if startswith(url, "webhook://")]

  # Resolve protocol-prefixed URLs to actual endpoint URLs
  resolved_urls = {
    for idx, url in var.notification_urls :
    idx => contains(local.slack_urls, url) ? replace(url, "slack://", "https://hooks.slack.com/services/") :
    contains(local.pagerduty_urls, url) ? replace(url, "pagerduty://", "") :
    contains(local.webhook_urls, url) ? replace(url, "webhook://", "") :
    url
  }

  # Create notification commands for each URL with proper type detection
  # URLs are passed via WEBHOOK_URL environment variable to prevent command injection
  notification_commands = {
    for idx, url in var.notification_urls :
    idx => contains(local.slack_urls, url) ? local.slack_notification_template :
    contains(local.pagerduty_urls, url) ? local.pagerduty_notification_template :
    contains(local.webhook_urls, url) ? local.webhook_notification_template :
    "echo 'Unknown notification type'"
  }

  # Slack notification template
  slack_notification_template = <<-EOT
    curl -X POST "$WEBHOOK_URL" \
      -H 'Content-Type: application/json' \
      -d '{
        "text": "Maintenance ${replace(var.maintenance_status, "'", "")}",
        "blocks": [
          {
            "type": "header",
            "text": {
              "type": "plain_text",
              "text": "Maintenance ${replace(var.maintenance_status, "'", "")}: ${replace(var.schedule_name, "'", "")}"
            }
          },
          {
            "type": "section",
            "fields": [
              {
                "type": "mrkdwn",
                "text": "*Status:*\n${replace(var.maintenance_status, "'", "")}"
              },
              {
                "type": "mrkdwn",
                "text": "*Window:*\n${replace(var.maintenance_window.start_time, "'", "")} - ${replace(var.maintenance_window.end_time, "'", "")}"
              },
              {
                "type": "mrkdwn",
                "text": "*Environment:*\n${replace(var.environment, "'", "")}"
              },
              {
                "type": "mrkdwn",
                "text": "*Schedule:*\n${replace(var.schedule_name, "'", "")}"
              }
            ]
          }
        ]
      }'
  EOT

  # PagerDuty notification template
  # WEBHOOK_URL contains the routing key, passed via environment variable
  pagerduty_notification_template = <<-EOT
    curl -X POST 'https://events.pagerduty.com/v2/enqueue' \
      -H 'Content-Type: application/json' \
      -d "$(jq -n --arg key "$WEBHOOK_URL" '{
        "routing_key": $key,
        "event_action": "trigger",
        "payload": {
          "summary": "Maintenance ${replace(var.maintenance_status, "'", "")}: ${replace(var.schedule_name, "'", "")}",
          "severity": "warning",
          "source": "terraform-cloudflare-maintenance",
          "custom_details": {
            "status": "${replace(var.maintenance_status, "'", "")}",
            "environment": "${replace(var.environment, "'", "")}",
            "schedule": "${replace(var.schedule_name, "'", "")}",
            "start_time": "${replace(var.maintenance_window.start_time, "'", "")}",
            "end_time": "${replace(var.maintenance_window.end_time, "'", "")}"
          }
        }
      }')"
  EOT

  # Generic webhook notification template
  webhook_notification_template = <<-EOT
    curl -X POST "$WEBHOOK_URL" \
      -H 'Content-Type: application/json' \
      -d '{
        "status": "${replace(var.maintenance_status, "'", "")}",
        "schedule_name": "${replace(var.schedule_name, "'", "")}",
        "environment": "${replace(var.environment, "'", "")}",
        "maintenance_window": {
          "start_time": "${replace(var.maintenance_window.start_time, "'", "")}",
          "end_time": "${replace(var.maintenance_window.end_time, "'", "")}"
        }
      }'
  EOT
}
