# Role-Based Access Control (RBAC) Team Configuration

# Define permission levels
locals {
  permission_levels = {
    read     = "pull"
    triage   = "triage"
    write    = "push"
    maintain = "maintain"
    admin    = "admin"
  }

  # Security groups with strict access controls
  security_teams = {
    "security-admins" = {
      description = "Security administrators with full access to security configurations"
      privacy     = "secret"
      members     = var.security_admin_users
      permission  = "admin"
      repos       = ["all"]
    }

    "security-auditors" = {
      description = "Security auditors with read-only access for compliance"
      privacy     = "closed"
      members     = var.security_auditor_users
      permission  = "pull"
      repos       = ["all"]
    }

    "infrastructure-team" = {
      description = "Infrastructure team with maintain access to infra repos"
      privacy     = "closed"
      members     = var.infrastructure_users
      permission  = "maintain"
      repos = [
        "terraform-cloudflare-maintenance",
        "terraform-aws-dedicated-host",
        "aws-ssm-automation-scripts",
        "ansible-role-mariadb"
      ]
    }

    "developers" = {
      description = "Development team with write access to application repos"
      privacy     = "closed"
      members     = var.developer_users
      permission  = "push"
      repos = [
        "wordpress-gmail-cli",
        "commitkit-rust",
        "rust-findagrave-citation-parser",
        "python-network-discovery-tool",
        "yieldmax-dashboard"
      ]
    }

    "devops-engineers" = {
      description = "DevOps engineers with maintain access to CI/CD and automation"
      privacy     = "closed"
      members     = var.devops_users
      permission  = "maintain"
      repos = [
        "jenkins-script-library",
        "chef-cookbook-template",
        "chef-nginx-cookbook",
        "chef-httpd-cookbook",
        "chef-r-language-cookbook",
        "chef-tcp-wrappers"
      ]
    }

    "contractors" = {
      description = "External contractors with limited read access"
      privacy     = "secret"
      members     = var.contractor_users
      permission  = "pull"
      repos       = var.contractor_accessible_repos
    }
  }

  # Compliance teams for regulatory requirements
  compliance_teams = {
    "compliance-officers" = {
      description = "Compliance officers with audit access"
      privacy     = "secret"
      members     = var.compliance_users
      permission  = "pull"
      repos       = ["all"]
      audit_log   = true
    }

    "data-protection" = {
      description = "Data protection team for GDPR/CCPA compliance"
      privacy     = "secret"
      members     = var.data_protection_users
      permission  = "triage"
      repos = [
        "rust-findagrave-citation-parser",
        "oracle-inventory-management-tool"
      ]
    }
  }
}

# Create security teams
resource "github_team" "security_teams" {
  for_each = local.security_teams

  name                      = each.key
  description               = each.value.description
  privacy                   = each.value.privacy
  create_default_maintainer = false

  lifecycle {
    prevent_destroy = true
  }
}

# Create compliance teams
resource "github_team" "compliance_teams" {
  for_each = local.compliance_teams

  name                      = each.key
  description               = each.value.description
  privacy                   = each.value.privacy
  create_default_maintainer = false

  lifecycle {
    prevent_destroy = true
  }
}

# Team membership management with role validation
resource "github_team_membership" "security_members" {
  for_each = merge([
    for team_name, team in local.security_teams : {
      for member in team.members :
      "${team_name}-${member}" => {
        team_id  = github_team.security_teams[team_name].id
        username = member
        role     = contains(var.team_maintainers, member) ? "maintainer" : "member"
      }
    }
  ]...)

  team_id  = each.value.team_id
  username = each.value.username
  role     = each.value.role
}

resource "github_team_membership" "compliance_members" {
  for_each = merge([
    for team_name, team in local.compliance_teams : {
      for member in team.members :
      "${team_name}-${member}" => {
        team_id  = github_team.compliance_teams[team_name].id
        username = member
        role     = "member"
      }
    }
  ]...)

  team_id  = each.value.team_id
  username = each.value.username
  role     = each.value.role
}

# Repository access control
resource "github_team_repository" "security_repos" {
  for_each = merge([
    for team_name, team in local.security_teams : {
      for repo_name in(team.repos[0] == "all" ? keys(local.repositories) : team.repos) :
      "${team_name}-${repo_name}" => {
        team_id    = github_team.security_teams[team_name].id
        repository = github_repository.repos[repo_name].name
        permission = team.permission
      }
    }
  ]...)

  team_id    = each.value.team_id
  repository = each.value.repository
  permission = each.value.permission
}

resource "github_team_repository" "compliance_repos" {
  for_each = merge([
    for team_name, team in local.compliance_teams : {
      for repo_name in(team.repos[0] == "all" ? keys(local.repositories) : team.repos) :
      "${team_name}-${repo_name}" => {
        team_id    = github_team.compliance_teams[team_name].id
        repository = github_repository.repos[repo_name].name
        permission = team.permission
      }
    }
  ]...)

  team_id    = each.value.team_id
  repository = each.value.repository
  permission = each.value.permission
}

# Team sync with external identity provider (Optional)
resource "github_team_sync_group_mapping" "security_teams" {
  for_each = var.enable_team_sync ? local.security_teams : {}

  team_slug = each.key

  dynamic "group" {
    for_each = var.team_sync_groups[each.key] != null ? var.team_sync_groups[each.key] : []
    content {
      group_id          = group.value.group_id
      group_name        = group.value.group_name
      group_description = group.value.group_description
    }
  }
}

# CODEOWNERS file management
resource "github_repository_file" "codeowners" {
  for_each = var.enable_codeowners ? local.repositories : {}

  repository          = github_repository.repos[each.key].name
  branch              = github_repository.repos[each.key].default_branch
  file                = ".github/CODEOWNERS"
  commit_message      = "Update CODEOWNERS file"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true

  content = templatefile("${path.module}/templates/CODEOWNERS.tpl", {
    repository = each.key
    teams      = local.security_teams
    owners     = var.codeowners_mapping[each.key]
  })
}

# Security policy file
resource "github_repository_file" "security_policy" {
  for_each = local.repositories

  repository          = github_repository.repos[each.key].name
  branch              = github_repository.repos[each.key].default_branch
  file                = ".github/SECURITY.md"
  commit_message      = "Add security policy"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true

  content = templatefile("${path.module}/templates/SECURITY.md.tpl", {
    repository               = each.key
    security_contacts        = var.security_contacts
    vulnerability_disclosure = var.vulnerability_disclosure_url
  })
}

# Variables for RBAC configuration
variable "security_admin_users" {
  description = "List of security administrator usernames"
  type        = list(string)
  default     = []
}

variable "security_auditor_users" {
  description = "List of security auditor usernames"
  type        = list(string)
  default     = []
}

variable "infrastructure_users" {
  description = "List of infrastructure team usernames"
  type        = list(string)
  default     = []
}

variable "developer_users" {
  description = "List of developer usernames"
  type        = list(string)
  default     = []
}

variable "devops_users" {
  description = "List of DevOps engineer usernames"
  type        = list(string)
  default     = []
}

variable "contractor_users" {
  description = "List of contractor usernames"
  type        = list(string)
  default     = []
}

variable "contractor_accessible_repos" {
  description = "List of repositories accessible to contractors"
  type        = list(string)
  default     = []
}

variable "compliance_users" {
  description = "List of compliance officer usernames"
  type        = list(string)
  default     = []
}

variable "data_protection_users" {
  description = "List of data protection team usernames"
  type        = list(string)
  default     = []
}

variable "team_maintainers" {
  description = "List of users who should be team maintainers"
  type        = list(string)
  default     = []
}

variable "enable_team_sync" {
  description = "Enable team synchronization with external identity provider"
  type        = bool
  default     = false
}

variable "team_sync_groups" {
  description = "Mapping of teams to external identity provider groups"
  type = map(list(object({
    group_id          = string
    group_name        = string
    group_description = string
  })))
  default = {}
}

variable "enable_codeowners" {
  description = "Enable CODEOWNERS file creation"
  type        = bool
  default     = true
}

variable "codeowners_mapping" {
  description = "Mapping of repositories to code owners"
  type        = map(map(list(string)))
  default     = {}
}

variable "security_contacts" {
  description = "Security contact information"
  type        = list(string)
  default     = ["security@example.com"]
}

variable "vulnerability_disclosure_url" {
  description = "URL for vulnerability disclosure policy"
  type        = string
  default     = "https://example.com/security/disclosure"
}