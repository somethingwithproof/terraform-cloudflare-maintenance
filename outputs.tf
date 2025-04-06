output "worker_script_name" {
  description = "Deployed Cloudflare Worker script name"
  value       = cloudflare_worker_script.maintenance.name
}

output "worker_route_pattern" {
  description = "Cloudflare route pattern for the maintenance page"
  value       = var.enabled ? cloudflare_worker_route.maintenance_route[0].pattern : "Maintenance mode disabled"
}

output "maintenance_status" {
  description = "Current status of the maintenance mode"
  value       = var.enabled ? "ENABLED" : "DISABLED"
}

output "maintenance_page_url" {
  description = "URL to access the maintenance page directly"
  value       = var.enabled ? "https://maintenance.${trimsuffix(trimprefix(var.worker_route, "*."), "/*")}" : "Maintenance mode disabled"
}

output "allowed_ips" {
  description = "IPs allowed to bypass the maintenance page"
  value       = var.allowed_ips
  sensitive   = true
}

output "maintenance_window" {
  description = "Scheduled maintenance window if configured"
  value       = var.maintenance_window
}

output "firewall_rule_id" {
  description = "ID of the firewall rule for IP allowlisting (if enabled)"
  value       = var.enabled && length(var.allowed_ips) > 0 ? cloudflare_firewall_rule.maintenance_bypass[0].id : "No firewall rule created"
}
