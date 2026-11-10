output "worker_script_name" {
  description = "Deployed Cloudflare Worker script name"
  value       = module.maintenance.worker_script_name
}

output "maintenance_status" {
  description = "Current status of the maintenance mode"
  value       = module.maintenance.maintenance_status
}

output "maintenance_window" {
  description = "Configured maintenance window"
  value = {
    start_time = var.maintenance_start_time
    end_time   = var.maintenance_end_time
    duration   = "${formatdate("hh:mm", var.maintenance_end_time)} - ${formatdate("hh:mm", var.maintenance_start_time)}"
  }
}

output "allowed_ip_count" {
  description = "Number of IPs allowed to bypass maintenance"
  value       = length(concat(var.office_ip_ranges, var.monitoring_ips))
}
