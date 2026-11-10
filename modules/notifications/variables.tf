variable "notification_urls" {
  description = "Notification targets keyed by a non-secret name, for example { ops_slack = \"slack://T000/B000/XXXX\" }. Values use slack://<webhook path>, pagerduty://<routing key> or webhook://https://<url>. Names appear in plans and state; URLs never do."
  type        = map(string)
  default     = {}
  sensitive   = true

  validation {
    condition = alltrue([
      for url in values(var.notification_urls) :
      can(regex("^(slack://[^\\s\"]+|pagerduty://[^\\s\"]+|webhook://https://[^\\s\"]+)$", url))
    ])
    error_message = "Each notification URL must be slack://<webhook path>, pagerduty://<routing key> or webhook://https://<url>, with no spaces or quotes."
  }
}

variable "maintenance_status" {
  description = "Maintenance status to announce. DISABLED and COMPLETED end maintenance and resolve the PagerDuty incident; the others trigger it."
  type        = string

  validation {
    condition     = contains(["ENABLED", "SCHEDULED", "STARTING", "ACTIVE", "ENDING", "COMPLETED", "DISABLED"], var.maintenance_status)
    error_message = "maintenance_status must be one of ENABLED, SCHEDULED, STARTING, ACTIVE, ENDING, COMPLETED or DISABLED."
  }
}

variable "schedule_name" {
  description = "Name of the maintenance schedule. Together with environment it forms the PagerDuty dedup key."
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "maintenance_window" {
  description = "Maintenance window with start and end times, or null when maintenance is not scheduled"
  type = object({
    start_time = string
    end_time   = string
  })
  default = null
}
