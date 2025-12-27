# Additional Best Practices for GitHub Terraform Management

## 1. 🔒 Security Enhancements

### A. Repository Security Policies
```hcl
# security-policies.tf
resource "github_repository_file" "security_policy" {
  for_each = local.repositories
  
  repository = github_repository.repos[each.key].name
  file       = "SECURITY.md"
  content    = templatefile("${path.module}/templates/SECURITY.md", {
    security_email = var.security_contact_email
  })
}

resource "github_repository_file" "codeowners" {
  for_each = local.repositories
  
  repository = github_repository.repos[each.key].name
  file       = ".github/CODEOWNERS"
  content    = templatefile("${path.module}/templates/CODEOWNERS", {
    owners = var.codeowners[each.key]
  })
}
```

### B. Automated Security Scanning
```hcl
# Enable Dependabot and security scanning
resource "github_repository" "repos" {
  # ... existing config ...
  
  vulnerability_alerts                = true
  has_vulnerability_alerts_enabled    = true
  
  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }
}
```

### C. Secret Rotation Schedule
```hcl
# secret-rotation.tf
resource "time_rotating" "secret_rotation" {
  rotation_days = 90
}

resource "time_static" "secret_rotated" {
  triggers = {
    rotation = time_rotating.secret_rotation.id
  }
}

output "next_rotation_date" {
  value = time_rotating.secret_rotation.rotation_rfc3339
}
```

## 2. 📊 Governance & Compliance

### A. Tagging Strategy
```hcl
# tags.tf
locals {
  mandatory_tags = {
    ManagedBy        = "Terraform"
    Environment      = var.environment
    Owner            = var.owner_email
    CostCenter       = var.cost_center
    DataClassification = var.data_classification
    ComplianceLevel  = var.compliance_level
    LastReviewed     = timestamp()
  }
  
  repository_tags = {
    for name, repo in local.repositories : name => merge(
      local.mandatory_tags,
      {
        RepositoryType = lookup(repo, "type", "application")
        Criticality    = lookup(repo, "criticality", "low")
      }
    )
  }
}
```

### B. Audit Logging
```hcl
# audit.tf
resource "github_organization_webhook" "audit_webhook" {
  events = [
    "repository",
    "member",
    "team",
    "organization"
  ]
  
  configuration {
    url          = var.audit_webhook_url
    content_type = "json"
    secret       = var.webhook_secret
  }
}

# Log all Terraform operations
resource "local_file" "terraform_audit_log" {
  filename = "${path.module}/logs/terraform-${timestamp()}.log"
  content  = jsonencode({
    timestamp = timestamp()
    user      = data.github_user.current.login
    action    = "terraform-apply"
    changes   = terraform.workspace
  })
}
```

### C. Compliance Rules
```hcl
# compliance.tf
resource "null_resource" "compliance_check" {
  for_each = local.repositories
  
  provisioner "local-exec" {
    command = <<-EOT
      # Check for required files
      for file in LICENSE README.md SECURITY.md; do
        if ! gh api repos/${var.github_organization}/${each.key}/contents/$file 2>/dev/null; then
          echo "WARNING: ${each.key} missing required file: $file"
        fi
      done
    EOT
  }
}
```

## 3. 🚀 Operational Excellence

### A. Drift Detection
```hcl
# drift-detection.tf
resource "null_resource" "drift_detection" {
  provisioner "local-exec" {
    command = "terraform plan -detailed-exitcode -out=plan.tfplan"
  }
  
  triggers = {
    always_run = timestamp()
  }
}
```

### B. Resource Naming Convention
```hcl
# naming.tf
locals {
  naming_convention = {
    repository = "${var.org_prefix}-${var.environment}-${local.repository_name}"
    team       = "${var.org_prefix}-team-${local.team_name}"
    secret     = "${upper(var.org_prefix)}_${upper(local.secret_name)}"
  }
}

variable "org_prefix" {
  description = "Organization prefix for resource naming"
  type        = string
  default     = "gh"
  
  validation {
    condition     = length(var.org_prefix) <= 5
    error_message = "Prefix must be 5 characters or less."
  }
}
```

### C. Automated Documentation
```hcl
# documentation.tf
resource "local_file" "repository_docs" {
  filename = "${path.module}/docs/repositories.md"
  content  = templatefile("${path.module}/templates/repo-docs.md", {
    repositories = local.repositories
    teams        = github_team.teams
    updated_at   = timestamp()
  })
}
```

## 4. 📈 Monitoring & Observability

### A. Metrics Collection
```hcl
# metrics.tf
output "repository_metrics" {
  value = {
    total_repositories = length(local.repositories)
    private_repos     = length([for r in local.repositories : r if r.visibility == "private"])
    public_repos      = length([for r in local.repositories : r if r.visibility == "public"])
    archived_repos    = length([for r in github_repository.repos : r if r.archived])
  }
}

output "security_metrics" {
  value = {
    repos_with_branch_protection = length(github_branch_protection.main_protection)
    repos_with_vuln_alerts     = length([for r in github_repository.repos : r if r.vulnerability_alerts])
    total_secrets               = length(github_actions_secret.repo_secrets)
  }
}
```

### B. Health Checks
```hcl
# health-checks.tf
resource "null_resource" "repository_health" {
  for_each = local.repositories
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Checking health of ${each.key}..."
      # Check last commit date
      LAST_COMMIT=$(gh api repos/${var.github_organization}/${each.key}/commits -q '.[0].commit.author.date')
      echo "Last commit: $LAST_COMMIT"
      
      # Check open issues
      OPEN_ISSUES=$(gh api repos/${var.github_organization}/${each.key} -q '.open_issues_count')
      echo "Open issues: $OPEN_ISSUES"
      
      # Check for stale branches
      STALE_BRANCHES=$(gh api repos/${var.github_organization}/${each.key}/branches --paginate -q '.[] | select(.commit.commit.author.date < (now - 7776000 | todate)) | .name' | wc -l)
      echo "Stale branches (>90 days): $STALE_BRANCHES"
    EOT
  }
}
```

## 5. 🔄 CI/CD Integration

### A. Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      - id: terraform_tfsec
      - id: terraform_checkov
```

### B. GitHub Actions Workflow
```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  pull_request:
    paths:
      - '**.tf'
      - '**.tfvars'
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        
      - name: Terraform Init
        run: terraform init -backend=false
        
      - name: Terraform Validate
        run: terraform validate
        
      - name: TFSec Security Scan
        uses: aquasecurity/tfsec-action@v1.0.0
        
      - name: Checkov Policy Scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform
          
      - name: Cost Estimation
        uses: infracost/infracost-action@v1
        with:
          path: .
```

## 6. 🎯 Performance Optimization

### A. Parallel Execution
```hcl
# performance.tf
terraform {
  # Increase parallelism for faster execution
  experiments = [module_variable_optional_attrs]
  
  # Custom parallelism per environment
  parallelism = var.environment == "production" ? 10 : 30
}
```

### B. Resource Dependencies
```hcl
# Explicit dependencies for better performance
resource "github_repository" "repos" {
  # ... config ...
  
  depends_on = [
    github_team.teams
  ]
}

resource "github_branch_protection" "main_protection" {
  # ... config ...
  
  depends_on = [
    github_repository.repos
  ]
}
```

## 7. 🔧 Maintenance & Operations

### A. Backup Strategy
```bash
#!/bin/bash
# backup.sh
BACKUP_DIR="backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup state
terraform state pull > $BACKUP_DIR/terraform.tfstate

# Backup all repository settings
for repo in $(terraform output -json repository_urls | jq -r 'keys[]'); do
  gh api repos/$GITHUB_ORG/$repo > $BACKUP_DIR/$repo.json
done

# Compress and encrypt
tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR
gpg --encrypt --recipient $BACKUP_EMAIL $BACKUP_DIR.tar.gz
```

### B. Disaster Recovery
```hcl
# disaster-recovery.tf
resource "local_file" "recovery_script" {
  filename = "${path.module}/scripts/recover.sh"
  content  = templatefile("${path.module}/templates/recover.sh", {
    repositories = local.repositories
    teams        = github_team.teams
    timestamp    = timestamp()
  })
  
  file_permission = "0755"
}
```

## 8. 📝 Documentation Standards

### A. Self-Documenting Code
```hcl
# Every resource should have descriptions
variable "repository_settings" {
  description = <<-EOT
    Repository configuration settings.
    
    Structure:
    - visibility: public/private/internal
    - has_issues: Enable issue tracking
    - has_wiki: Enable wiki pages
    - topics: List of repository topics for discovery
    
    Example:
    {
      "my-repo" = {
        visibility = "private"
        has_issues = true
        has_wiki   = false
        topics     = ["terraform", "infrastructure"]
      }
    }
  EOT
  type = map(object({
    visibility = string
    has_issues = bool
    has_wiki   = bool
    topics     = list(string)
  }))
}
```

### B. Change Log
```hcl
# changelog.tf
resource "local_file" "changelog" {
  filename = "${path.module}/CHANGELOG.md"
  content  = <<-EOT
    # Terraform Changes
    
    ## ${timestamp()}
    - User: ${data.github_user.current.login}
    - Workspace: ${terraform.workspace}
    - Changes: See plan output
    
    ${file("${path.module}/CHANGELOG.md")}
  EOT
}
```

## Implementation Priority

### 🚨 High Priority (Immediate)
1. Enable security scanning and vulnerability alerts
2. Implement audit logging
3. Add pre-commit hooks
4. Set up backup strategy

### ⚡ Medium Priority (This Quarter)
1. Implement drift detection
2. Add compliance checks
3. Set up CI/CD pipeline
4. Create documentation templates

### 📅 Low Priority (Future)
1. Advanced metrics collection
2. Cost optimization
3. Performance tuning
4. Full disaster recovery automation

## Summary

These best practices provide:
- **Better Security**: Automated scanning, secret rotation, audit trails
- **Improved Governance**: Compliance checks, naming conventions, tagging
- **Operational Excellence**: Monitoring, health checks, drift detection
- **Team Efficiency**: CI/CD, documentation, backup/recovery

Start with high-priority items and gradually implement others based on your organization's needs.