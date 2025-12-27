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