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

output "status_page_url" {
  description = "URL to the dedicated status page"
  value       = "https://status.${trimsuffix(cloudflare_record.maintenance_status.zone_name, "/*")}"
}

output "firewall_rule_id" {
  description = "ID of the firewall rule for IP allowlisting (if enabled)"
  value       = module.maintenance.firewall_rule_id
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
