output "worker_id" {
  description = "The ID of the deployed worker script"
  value       = cloudflare_workers_script.maintenance.id
}

output "worker_name" {
  description = "The name of the deployed worker script"
  value       = cloudflare_workers_script.maintenance.name
}

output "worker_route" {
  description = "The route pattern for the maintenance worker"
  value       = var.enabled ? var.worker_route : "Not enabled"
}

output "maintenance_enabled" {
  description = "Whether maintenance mode is currently enabled"
  value       = var.enabled
}

output "rate_limit_ruleset_id" {
  description = "The ID of the rate limiting ruleset"
  value       = var.rate_limit.enabled ? cloudflare_ruleset.rate_limit[0].id : null
}

output "rate_limit_enabled" {
  description = "Whether rate limiting is currently enabled"
  value       = var.rate_limit.enabled
}