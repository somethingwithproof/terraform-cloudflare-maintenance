# Simplified GitHub configuration for solo developer
# Focuses on automation and security without team complexity

# Core settings for solo developer
locals {
  solo_dev_settings = {
    # Your GitHub username
    owner = var.github_organization

    # Enable all security features by default
    security_features = {
      vulnerability_alerts     = true
      automated_security_fixes = true
      secret_scanning          = true
      dependabot_enabled       = true
    }

    # Default branch protection (lighter for solo dev)
    branch_protection = {
      enforce_admins         = false # Allow yourself to push when needed
      require_signed_commits = false # Optional for solo dev
      dismiss_stale_reviews  = true
      required_approvals     = 0 # No approvals needed for solo
    }
  }
}

# Update all repositories with solo dev settings
resource "github_repository" "solo_repos" {
  for_each = local.repositories

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility

  # Security features - all enabled
  vulnerability_alerts = true
  has_issues           = true
  has_discussions      = false # Usually not needed for solo
  has_projects         = false # Can enable if you use project boards
  has_wiki             = false # Documentation in README instead

  # Merge settings optimized for solo work
  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true # Useful with Dependabot
  delete_branch_on_merge = true # Keep repo clean

  # Archive protection
  allow_update_branch = true

  # Enable GitHub Pages if needed
  # pages {
  #   source {
  #     branch = "main"
  #     path   = "/docs"
  #   }
  # }

  topics = try(each.value.topics, [])

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [description]
  }
}

# Simplified branch protection for solo developer
resource "github_branch_protection" "solo_protection" {
  for_each = var.enable_branch_protection ? local.repositories : {}

  repository_id = github_repository.solo_repos[each.key].node_id
  pattern       = "main"

  # Light protection - you can still force push if needed
  enforce_admins          = false
  allows_force_pushes     = false
  allows_deletions        = false
  require_signed_commits  = false
  required_linear_history = false

  # No PR reviews required for solo work
  # But you can still use PRs with Dependabot
  restrict_pushes {
    push_allowances = [data.github_user.current.node_id]
  }
}

# Get current user info
data "github_user" "current" {
  username = "" # Empty string returns authenticated user
}

# Variables for solo developer
variable "enable_branch_protection" {
  description = "Enable branch protection (can slow down solo development)"
  type        = bool
  default     = false
}

variable "enable_dependabot" {
  description = "Enable Dependabot for all repositories"
  type        = bool
  default     = true
}

variable "enable_github_pages" {
  description = "Repositories that should have GitHub Pages enabled"
  type        = list(string)
  default     = []
}