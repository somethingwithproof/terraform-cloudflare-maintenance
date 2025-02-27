output "worker_script_name" {
  description = "Deployed Cloudflare Worker script name"
  value       = cloudflare_worker_script.maintenance.name
}

output "worker_route_pattern" {
  description = "Cloudflare route pattern for the maintenance page"
  value       = cloudflare_worker_route.maintenance_route.pattern
}
