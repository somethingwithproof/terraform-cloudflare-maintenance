variable "github_organization" {
  description = "The GitHub organization or username to manage"
  type        = string
  default     = "thomasvincent"
}

variable "default_branch" {
  description = "Default branch for repositories"
  type        = string
  default     = "main"
}

variable "enable_issues" {
  description = "Enable issues for repositories by default"
  type        = bool
  default     = true
}

variable "enable_projects" {
  description = "Enable projects for repositories by default"
  type        = bool
  default     = false
}

variable "enable_wiki" {
  description = "Enable wiki for repositories by default"
  type        = bool
  default     = false
}

variable "enable_discussions" {
  description = "Enable discussions for repositories by default"
  type        = bool
  default     = false
}

variable "delete_branch_on_merge" {
  description = "Automatically delete branches after merge"
  type        = bool
  default     = true
}

variable "allow_squash_merge" {
  description = "Allow squash merging pull requests"
  type        = bool
  default     = true
}

variable "allow_merge_commit" {
  description = "Allow merge commits"
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "Allow rebase merging pull requests"
  type        = bool
  default     = true
}

variable "vulnerability_alerts" {
  description = "Enable vulnerability alerts for repositories"
  type        = bool
  default     = true
}

variable "team_members" {
  description = "Map of team names to member lists"
  type = map(object({
    description = string
    privacy     = string
    members     = list(string)
  }))
  default = {}
}

variable "branch_protection_rules" {
  description = "Branch protection rules for repositories"
  type = map(object({
    pattern                         = string
    enforce_admins                  = bool
    require_signed_commits          = bool
    required_status_checks          = list(string)
    dismiss_stale_reviews           = bool
    require_code_owner_reviews      = bool
    required_approving_review_count = number
  }))
  default = {}
}