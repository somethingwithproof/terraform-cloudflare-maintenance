# Security configurations for GitHub repositories

# Branch protection for main branches
resource "github_branch_protection" "main_protection" {
  for_each = local.repositories

  repository_id = github_repository.repos[each.key].node_id
  pattern       = "main"

  # Core security settings
  enforce_admins         = false
  require_signed_commits = var.require_signed_commits

  # PR review requirements
  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = var.require_code_owners
    required_approving_review_count = var.required_approvals
  }

  # Status checks (add your CI/CD checks)
  required_status_checks {
    strict   = true
    contexts = lookup(var.status_checks, each.key, [])
  }
}

# Security-focused teams
resource "github_team" "security_teams" {
  for_each = {
    "admins" = {
      description = "Organization administrators"
      privacy     = "closed"
    }
    "security" = {
      description = "Security team with audit access"
      privacy     = "closed"
    }
  }

  name        = each.key
  description = each.value.description
  privacy     = each.value.privacy
}

# Team repository access
resource "github_team_repository" "admin_access" {
  for_each = local.repositories

  team_id    = github_team.security_teams["admins"].id
  repository = github_repository.repos[each.key].name
  permission = "admin"
}

resource "github_team_repository" "security_access" {
  for_each = local.repositories

  team_id    = github_team.security_teams["security"].id
  repository = github_repository.repos[each.key].name
  permission = "pull"
}

# Security variables
variable "require_signed_commits" {
  description = "Require signed commits on protected branches"
  type        = bool
  default     = false
}

variable "require_code_owners" {
  description = "Require code owner reviews"
  type        = bool
  default     = false
}

variable "required_approvals" {
  description = "Number of required PR approvals"
  type        = number
  default     = 1
}

variable "status_checks" {
  description = "Required status checks per repository"
  type        = map(list(string))
  default     = {}
}