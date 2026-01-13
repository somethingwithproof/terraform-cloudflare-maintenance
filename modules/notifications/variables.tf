variable "notification_urls" {
  description = "List of notification URLs (slack://, pagerduty://, webhook://)"
  type        = list(string)
  default     = []
}

variable "maintenance_status" {
  description = "Current maintenance status (STARTING, ACTIVE, ENDING, COMPLETED)"
  type        = string
}

variable "schedule_name" {
  description = "Name of the maintenance schedule"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "maintenance_window" {
  description = "Maintenance window with start and end times"
  type = object({
    start_time = string
    end_time   = string
  })
}
