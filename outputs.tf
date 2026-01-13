output "worker_id" {
  description = "The ID of the deployed worker script"
  value       = cloudflare_workers_script.maintenance.id
}

output "worker_name" {
  description = "The name of the deployed worker script"
  value       = cloudflare_workers_script.maintenance.name
}

output "worker_script_name" {
  description = "The name of the deployed worker script (alias for compatibility)"
  value       = cloudflare_workers_script.maintenance.name
}

output "worker_route" {
  description = "The route pattern for the maintenance worker"
  value       = var.enabled ? var.worker_route : "Not enabled"
}

output "worker_route_pattern" {
  description = "The route pattern for the maintenance worker (alias for compatibility)"
  value       = var.enabled ? var.worker_route : "Maintenance mode disabled"
}

output "maintenance_enabled" {
  description = "Whether maintenance mode is currently enabled"
  value       = var.enabled
}

output "maintenance_status" {
  description = "Current status of the maintenance mode"
  value       = var.enabled ? "ENABLED" : "DISABLED"
}

output "maintenance_page_url" {
  description = "URL to access the maintenance page directly"
  value       = var.enabled ? local.maintenance_status_url : "Maintenance mode disabled"
}

locals {
  # Extract clean domain from worker_route pattern (e.g., "*.example.com/*" -> "example.com")
  clean_domain = trim(replace(replace(var.worker_route, "*.", ""), "/*", ""), "/")
  
  # Construct maintenance status page URL
  maintenance_status_url = format("https://maintenance-status-%s.%s", var.environment, local.clean_domain)
}

output "dns_record_id" {
  description = "ID of the DNS record for the maintenance status page"
  value       = var.enabled && length(cloudflare_record.maintenance_status) > 0 ? cloudflare_record.maintenance_status[0].id : "No DNS record created"
}

output "ruleset_id" {
  description = "ID of the firewall ruleset for IP/region allowlisting"
  value       = var.enabled && length(cloudflare_ruleset.maintenance_bypass) > 0 ? cloudflare_ruleset.maintenance_bypass[0].id : "No ruleset created"
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
