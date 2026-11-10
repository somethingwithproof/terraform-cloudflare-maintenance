output "worker_script_name" {
  description = "Deployed Cloudflare Worker script name"
  value       = module.maintenance.worker_script_name
}

output "maintenance_status" {
  description = "Current status of the maintenance mode"
  value       = module.maintenance.maintenance_status
}
