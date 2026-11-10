output "maintenance_status" {
  description = "SCHEDULED, ENABLED or DISABLED"
  value       = module.maintenance.maintenance_status
}

output "worker_route_pattern" {
  description = "Route the Worker is deployed on, if any"
  value       = module.maintenance.worker_route_pattern
}

output "worker_name" {
  description = "Name of this environment's Worker script"
  value       = module.maintenance.worker_name
}
