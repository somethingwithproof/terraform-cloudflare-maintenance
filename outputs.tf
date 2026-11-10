output "worker_id" {
  description = "The ID of the deployed worker script"
  value       = cloudflare_workers_script.maintenance.id
}

output "worker_name" {
  description = "The name of the deployed worker script"
  value       = cloudflare_workers_script.maintenance.script_name
}

output "worker_script_name" {
  description = "The name of the deployed worker script (alias for compatibility)"
  value       = cloudflare_workers_script.maintenance.script_name
}

output "worker_route" {
  description = "The route pattern for the maintenance worker"
  value       = local.route_enabled ? var.worker_route : "Not enabled"
}

output "worker_route_pattern" {
  description = "The route pattern for the maintenance worker (alias for compatibility)"
  value       = local.route_enabled ? var.worker_route : "Maintenance mode disabled"
}

output "maintenance_enabled" {
  description = "Whether maintenance mode is currently enabled"
  value       = var.enabled
}

output "maintenance_status" {
  description = "SCHEDULED when a maintenance window is set, otherwise ENABLED or DISABLED"
  value       = var.maintenance_window != null ? "SCHEDULED" : var.enabled ? "ENABLED" : "DISABLED"
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "maintenance_window" {
  description = "Scheduled maintenance window if configured"
  value       = var.maintenance_window != null ? var.maintenance_window : { start_time = "", end_time = "" }
}

output "allowed_regions" {
  description = "List of allowed regions that can bypass maintenance"
  value       = var.allowed_regions
}

output "rate_limit_ruleset_id" {
  description = "The ID of the rate limiting ruleset"
  value       = var.rate_limit.enabled ? cloudflare_ruleset.rate_limit[0].id : null
}

output "rate_limit_enabled" {
  description = "Whether rate limiting is currently enabled"
  value       = var.rate_limit.enabled
}
