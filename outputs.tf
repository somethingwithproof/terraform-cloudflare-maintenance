output "worker_script_name" {
  description = "Deployed Cloudflare Worker script name"
  value       = cloudflare_workers_script.maintenance.script_name
}

output "worker_route_pattern" {
  description = "Cloudflare route pattern for the maintenance page"
  value       = var.enabled ? cloudflare_workers_route.maintenance_route[0].pattern : "Maintenance mode disabled"
}

output "maintenance_status" {
  description = "Current status of the maintenance mode"
  value       = var.enabled ? "ENABLED" : "DISABLED"
}

output "maintenance_page_url" {
  description = "URL to access the maintenance page directly"
  value       = var.enabled ? "https://maintenance.${trimsuffix(trimprefix(var.worker_route, "*."), "/*")}" : "Maintenance mode disabled"
}

output "dns_record_id" {
  description = "ID of the maintenance page DNS record (if enabled)"
  value       = var.enabled ? cloudflare_dns_record.maintenance[0].id : "No DNS record created"
}

output "allowed_ips" {
  description = "IPs allowed to bypass the maintenance page"
  value       = var.allowed_ips
  sensitive   = true
}

output "allowed_ip_ranges" {
  description = "IP ranges allowed to bypass the maintenance page"
  value       = var.allowed_ip_ranges
  sensitive   = true
}

output "allowed_regions" {
  description = "Geographical regions allowed to bypass the maintenance page"
  value       = var.allowed_regions
}

output "maintenance_window" {
  description = "Scheduled maintenance window if configured"
  value       = var.maintenance_window
}

output "environment" {
  description = "Current deployment environment"
  value       = var.environment
}

output "ruleset_id" {
  description = "ID of the ruleset for bypass configuration (if enabled)"
  value       = var.enabled && (length(var.allowed_ips) > 0 || length(var.allowed_ip_ranges) > 0 || length(var.allowed_regions) > 0) ? cloudflare_ruleset.maintenance_bypass[0].id : "No ruleset created"
}

output "rate_limit_id" {
  description = "ID of the rate limit rule (if enabled) - temporarily disabled"
  value       = "Rate limiting temporarily disabled pending provider update"
}

output "api_endpoint" {
  description = "API endpoint for managing maintenance mode"
  value       = var.enabled ? "https://${trimsuffix(trimprefix(var.worker_route, "*."), "/*")}/api/" : "Maintenance mode disabled"
}

output "api_key" {
  description = "API key for managing maintenance mode"
  value       = local.worker_vars.api_key
  sensitive   = true
}
