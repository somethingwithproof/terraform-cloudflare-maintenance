# Security configuration optimized for solo developer
# Automates security without getting in your way

# Enable GitHub Advanced Security features (if available on your plan)
resource "github_repository" "security_features" {
  for_each = local.repositories

  name = each.key

  # Security and analysis settings
  security_and_analysis {
    # Secret scanning - prevents accidental credential commits
    secret_scanning {
      status = "enabled"
    }

    # Push protection - blocks pushes with secrets
    secret_scanning_push_protection {
      status = "enabled"
    }

    # Advanced security (requires GitHub Advanced Security license)
    # advanced_security {
    #   status = "enabled"
    # }
  }

  lifecycle {
    ignore_changes = [name, description]
  }
}

# Note: Vulnerability alerts are already enabled in the repository resource
# via the vulnerability_alerts = true setting

# Create security policy for all repos
resource "github_repository_file" "security_policy" {
  for_each = local.repositories

  repository = github_repository.solo_repos[each.key].name
  branch     = github_repository.solo_repos[each.key].default_branch
  file       = "SECURITY.md"

  content = <<-EOT
    # Security Policy
    
    ## Supported Versions
    
    | Version | Supported          |
    | ------- | ------------------ |
    | latest  | :white_check_mark: |
    | < latest| :x:                |
    
    ## Reporting a Vulnerability
    
    As this is a personal project maintained by @${var.github_organization}, please report security vulnerabilities by:
    
    1. **DO NOT** create a public issue
    2. Send an email to: ${var.security_email}
    3. Or use GitHub's private vulnerability reporting (if enabled)
    
    You can expect a response within 48 hours.
    
    ## Security Updates
    
    - Dependencies are automatically updated via Dependabot
    - Security patches are auto-merged for minor/patch versions
    - Major version updates require manual review
    
    ## Automated Security
    
    This repository has the following security measures:
    - ✅ Dependabot security updates
    - ✅ Secret scanning
    - ✅ Vulnerability alerts
    - ✅ Automated dependency updates
  EOT

  commit_message      = "Add security policy"
  commit_author       = "Terraform"
  commit_email        = "terraform@localhost"
  overwrite_on_create = true
}

# Add .gitignore to prevent accidental commits
resource "github_repository_file" "gitignore" {
  for_each = var.add_gitignore ? local.repositories : {}

  repository = github_repository.solo_repos[each.key].name
  branch     = github_repository.solo_repos[each.key].default_branch
  file       = ".gitignore"

  content = <<-EOT
    # Environment variables
    .env
    .env.*
    !.env.example
    
    # Secrets and credentials
    *.pem
    *.key
    *.crt
    *.p12
    secrets/
    credentials/
    
    # IDE
    .vscode/
    .idea/
    *.swp
    *.swo
    .DS_Store
    
    # Dependencies
    node_modules/
    vendor/
    venv/
    __pycache__/
    *.pyc
    
    # Build outputs
    dist/
    build/
    target/
    *.egg-info/
    
    # Terraform
    *.tfstate
    *.tfstate.*
    .terraform/
    *.tfplan
    
    # Logs
    *.log
    logs/
    
    # Temporary files
    tmp/
    temp/
    *.tmp
    *.bak
    *.backup
    
    # Coverage
    coverage/
    *.coverage
    .nyc_output/
  EOT

  commit_message      = "Add comprehensive .gitignore"
  commit_author       = "Terraform"
  commit_email        = "terraform@localhost"
  overwrite_on_create = false # Don't overwrite existing .gitignore
}

# Create GitHub Actions workflow for security scanning
resource "github_repository_file" "security_scanning" {
  for_each = var.enable_security_scanning ? local.repositories : {}

  repository = github_repository.solo_repos[each.key].name
  branch     = github_repository.solo_repos[each.key].default_branch
  file       = ".github/workflows/security.yml"

  content = <<-EOT
    name: Security Scan
    
    on:
      push:
        branches: [main]
      pull_request:
        branches: [main]
      schedule:
        - cron: '0 0 * * 1'  # Weekly on Monday
    
    jobs:
      security:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          
          # Trivy security scanner
          - name: Run Trivy vulnerability scanner
            uses: aquasecurity/trivy-action@master
            with:
              scan-type: 'fs'
              scan-ref: '.'
              format: 'sarif'
              output: 'trivy-results.sarif'
          
          - name: Upload Trivy results to GitHub Security
            uses: github/codeql-action/upload-sarif@v3
            if: always()
            with:
              sarif_file: 'trivy-results.sarif'
          
          # GitLeaks secret scanning
          - name: gitleaks
            uses: gitleaks/gitleaks-action@v2
            env:
              GITHUB_TOKEN: ${"$"}{{ secrets.GITHUB_TOKEN }}
  EOT

  commit_message      = "Add security scanning workflow"
  commit_author       = "Terraform"
  commit_email        = "terraform@localhost"
  overwrite_on_create = true
}

# Solo developer notifications
resource "github_repository_webhook" "notifications" {
  for_each = var.enable_notifications ? local.repositories : {}

  repository = github_repository.solo_repos[each.key].name

  configuration {
    url          = var.webhook_url
    content_type = "json"
    insecure_ssl = false
  }

  active = true

  events = [
    "security_advisory",
    "vulnerability_alert",
    "secret_scanning_alert"
  ]
}

# Variables for solo security
variable "security_email" {
  description = "Email for security notifications"
  type        = string
  default     = "" # Set in terraform.tfvars
}

variable "add_gitignore" {
  description = "Add comprehensive .gitignore to all repos"
  type        = bool
  default     = true
}

variable "enable_security_scanning" {
  description = "Enable automated security scanning workflows"
  type        = bool
  default     = true
}

variable "enable_notifications" {
  description = "Enable webhook notifications for security events"
  type        = bool
  default     = false
}

variable "webhook_url" {
  description = "Webhook URL for notifications (e.g., Slack, Discord)"
  type        = string
  default     = ""
  sensitive   = true
}