# SPDX-FileCopyrightText: 2025-2026 Thomas Vincent <thomasvincent@gmail.com>
# SPDX-License-Identifier: MIT

output "worker_script_name" {
  description = "Deployed Cloudflare Worker script name"
  value       = module.maintenance.worker_script_name
}

output "maintenance_status" {
  description = "Current status of the maintenance mode"
  value       = module.maintenance.maintenance_status
}
