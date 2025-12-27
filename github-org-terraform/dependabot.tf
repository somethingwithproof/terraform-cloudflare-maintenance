# Dependabot configuration for all repositories
# Automatically creates PRs for dependency updates

# Dependabot configuration template
locals {
  # Define ecosystem-specific update schedules
  # MONTHLY updates for regular dependencies (security updates are still immediate)
  dependabot_ecosystems = {
    # JavaScript/Node.js
    npm = {
      directory = "/"
      schedule  = "monthly"
      day       = "monday" # First Monday of month
      time      = "04:00"
      groups = {
        production-dependencies = {
          dependency_type = "production"
        }
        development-dependencies = {
          dependency_type = "development"
        }
      }
    }

    # Python
    pip = {
      directory = "/"
      schedule  = "monthly"
      day       = "monday"
      time      = "04:00"
    }

    # Go
    gomod = {
      directory = "/"
      schedule  = "monthly"
      day       = "monday"
      time      = "04:00"
    }

    # Rust
    cargo = {
      directory = "/"
      schedule  = "monthly"
      day       = "monday"
      time      = "04:00"
    }

    # Docker
    docker = {
      directory = "/"
      schedule  = "monthly"
      day       = "monday"
      time      = "04:00"
    }

    # Terraform
    terraform = {
      directory = "/"
      schedule  = "monthly"
      day       = "monday"
      time      = "04:00"
    }

    # GitHub Actions
    github-actions = {
      directory = "/"
      schedule  = "monthly"
      day       = "monday"
      time      = "04:00"
    }

    # Ruby/Bundler
    bundler = {
      directory = "/"
      schedule  = "monthly"
      day       = "monday"
      time      = "04:00"
    }
  }

  # Map repositories to their ecosystems
  repo_ecosystems = {
    "chef-r-language-cookbook"         = ["bundler"]
    "wordpress-gmail-cli"              = ["npm", "docker"]
    "utility-scripts-collection"       = ["github-actions"]
    "cloudflare-ufw-sync"              = ["pip", "github-actions"]
    "jenkins-script-library"           = ["npm", "docker"]
    "chef-nginx-cookbook"              = ["bundler"]
    "commitkit-rust"                   = ["cargo", "github-actions"]
    "terraform-cloudflare-maintenance" = ["terraform", "npm", "github-actions"]
    "rust-findagrave-citation-parser"  = ["cargo", "github-actions"]
    "mantl"                            = ["terraform", "docker"]
    "oracle-inventory-management-tool" = ["pip"]
    "ansible-role-mariadb"             = ["pip", "github-actions"]
    "aws-ssm-automation-scripts"       = ["pip", "terraform"]
    "python-network-discovery-tool"    = ["pip"]
    "chef-cookbook-template"           = ["bundler"]
    "chef-httpd-cookbook"              = ["bundler"]
    "yieldmax-dashboard"               = ["npm", "docker"]
    "chef-tcp-wrappers"                = ["bundler"]
    "dotfiles"                         = ["github-actions"]
    "terraform-aws-dedicated-host"     = ["terraform", "github-actions"]
  }
}

# Create Dependabot configuration file for each repository
resource "github_repository_file" "dependabot_config" {
  for_each = var.enable_dependabot ? local.repo_ecosystems : {}

  repository = github_repository.solo_repos[each.key].name
  branch     = github_repository.solo_repos[each.key].default_branch
  file       = ".github/dependabot.yml"

  content = templatefile("${path.module}/templates/dependabot.yml.tpl", {
    ecosystems = [for ecosystem in each.value : merge(
      local.dependabot_ecosystems[ecosystem],
      { package_ecosystem = ecosystem }
    )]

    # Solo developer optimizations
    open_pull_requests_limit = 5 # Lower limit for monthly batches
    labels                   = ["dependencies", "automated"]
    assignees                = [var.github_organization]
    reviewers                = [] # No reviewers needed for solo

    # Auto-merge settings (security only)
    auto_merge_security = var.enable_auto_merge
  })

  commit_message      = "Add Dependabot configuration"
  commit_author       = "Terraform"
  commit_email        = "terraform@localhost"
  overwrite_on_create = true
}

# Dependabot secrets (for private registries if needed)
resource "github_dependabot_secret" "registry_tokens" {
  for_each = var.dependabot_secrets

  repository      = each.key
  secret_name     = each.value.name
  plaintext_value = each.value.value

  lifecycle {
    ignore_changes = [plaintext_value]
  }
}

# Enable Dependabot security updates
resource "github_repository_dependabot_security_updates" "security_updates" {
  for_each = var.enable_dependabot ? local.repositories : {}

  repository = github_repository.solo_repos[each.key].name
  enabled    = true
}

# Create GitHub Actions workflow for auto-merge
resource "github_repository_file" "auto_merge_workflow" {
  for_each = var.enable_auto_merge ? local.repositories : {}

  repository = github_repository.solo_repos[each.key].name
  branch     = github_repository.solo_repos[each.key].default_branch
  file       = ".github/workflows/dependabot-auto-merge.yml"

  content = file("${path.module}/templates/dependabot-auto-merge.yml")

  commit_message      = "Add Dependabot auto-merge workflow"
  commit_author       = "Terraform"
  commit_email        = "terraform@localhost"
  overwrite_on_create = true
}

# Variables for Dependabot configuration
variable "enable_auto_merge" {
  description = "Enable auto-merge for Dependabot security updates only"
  type        = bool
  default     = true
}

variable "dependabot_secrets" {
  description = "Secrets for private package registries"
  type = map(object({
    name  = string
    value = string
  }))
  default = {}
  # Remove sensitive flag to allow for_each
}

# Output Dependabot status
output "dependabot_status" {
  value = {
    enabled_repos = var.enable_dependabot ? keys(local.repo_ecosystems) : []
    total_repos   = length(local.repositories)
    coverage      = var.enable_dependabot ? "${length(local.repo_ecosystems)} / ${length(local.repositories)}" : "Disabled"
  }
}