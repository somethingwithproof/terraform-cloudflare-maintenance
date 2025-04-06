output "worker_script_name" {
  description = "Deployed Cloudflare Worker script name"
  value       = module.maintenance.worker_script_name
}

output "maintenance_status" {
  description = "Current status of the maintenance mode"
  value       = module.maintenance.maintenance_status
}

output "maintenance_page_url" {
  description = "URL to access the maintenance page directly"
  value       = module.maintenance.maintenance_page_url
}
