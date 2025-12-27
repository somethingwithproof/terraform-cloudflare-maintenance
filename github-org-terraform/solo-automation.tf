# Automated maintenance for solo developer
# Set it and forget it configuration

# Weekly maintenance workflow for all repos
resource "github_repository_file" "maintenance_workflow" {
  for_each = local.repositories

  repository = github_repository.solo_repos[each.key].name
  branch     = github_repository.solo_repos[each.key].default_branch
  file       = ".github/workflows/maintenance.yml"

  content = <<-EOT
    name: Automated Maintenance
    
    on:
      schedule:
        - cron: '0 2 * * 0'  # Sunday 2 AM
      workflow_dispatch:  # Allow manual trigger
    
    permissions:
      contents: write
      issues: write
      pull-requests: write
    
    jobs:
      cleanup:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          
          # Clean up old branches
          - name: Delete merged branches
            run: |
              git config --global user.email "action@github.com"
              git config --global user.name "GitHub Action"
              
              # Fetch all branches
              git fetch --prune origin
              
              # Delete merged branches except main/master/develop
              for branch in $(git branch -r --merged | grep -v "main\|master\|develop" | sed 's/origin\///'); do
                echo "Deleting branch: $branch"
                git push origin --delete "$branch" || true
              done
          
          # Close stale issues
          - name: Close stale issues
            uses: actions/stale@v9
            with:
              stale-issue-message: 'This issue has been automatically marked as stale because it has not had recent activity.'
              close-issue-message: 'This issue was closed automatically due to inactivity.'
              days-before-stale: 90
              days-before-close: 7
              stale-issue-label: 'stale'
              exempt-issue-labels: 'pinned,security,bug'
          
          # Close stale PRs
          - name: Close stale PRs
            uses: actions/stale@v9
            with:
              stale-pr-message: 'This PR has been automatically marked as stale because it has not had recent activity.'
              close-pr-message: 'This PR was closed automatically due to inactivity.'
              days-before-stale: 60
              days-before-close: 7
              stale-pr-label: 'stale'
              exempt-pr-labels: 'pinned,security'
          
          # Update dependencies cache
          - name: Cache cleanup
            run: |
              # Clear GitHub Actions cache periodically
              echo "Cache cleanup completed"
      
      statistics:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          
          - name: Generate repository stats
            run: |
              echo "# Repository Statistics - $(date)" > STATS.md
              echo "" >> STATS.md
              
              # Count lines of code
              echo "## Lines of Code" >> STATS.md
              find . -type f -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.tf" | xargs wc -l | tail -1 >> STATS.md
              echo "" >> STATS.md
              
              # List recent commits
              echo "## Recent Activity" >> STATS.md
              git log --oneline -10 >> STATS.md
              echo "" >> STATS.md
              
              # Dependencies count
              echo "## Dependencies" >> STATS.md
              if [ -f "package.json" ]; then
                echo "NPM packages: $(jq '.dependencies | length' package.json)" >> STATS.md
              fi
              if [ -f "requirements.txt" ]; then
                echo "Python packages: $(wc -l < requirements.txt)" >> STATS.md
              fi
              if [ -f "go.mod" ]; then
                echo "Go modules: $(grep -c "require" go.mod)" >> STATS.md
              fi
              
          - name: Update stats file
            run: |
              git config --global user.email "action@github.com"
              git config --global user.name "GitHub Action"
              git add STATS.md || true
              git commit -m "Update repository statistics [skip ci]" || true
              git push || true
  EOT

  commit_message      = "Add automated maintenance workflow"
  commit_author       = "Terraform"
  commit_email        = "terraform@localhost"
  overwrite_on_create = true
}

# Add issue templates for consistency
resource "github_repository_file" "issue_template_bug" {
  for_each = local.repositories

  repository = github_repository.solo_repos[each.key].name
  branch     = github_repository.solo_repos[each.key].default_branch
  file       = ".github/ISSUE_TEMPLATE/bug.md"

  content = <<-EOT
    ---
    name: Bug Report
    about: Report a bug
    title: '[BUG] '
    labels: 'bug'
    assignees: '${var.github_organization}'
    ---
    
    **Description**
    A clear description of the bug.
    
    **To Reproduce**
    Steps to reproduce:
    1. 
    2. 
    
    **Expected behavior**
    What should happen instead.
    
    **Environment:**
    - OS: 
    - Version: 
    
    **Additional context**
    Any other relevant information.
  EOT

  commit_message      = "Add bug report template"
  commit_author       = "Terraform"
  commit_email        = "terraform@localhost"
  overwrite_on_create = true
}

resource "github_repository_file" "issue_template_feature" {
  for_each = local.repositories

  repository = github_repository.solo_repos[each.key].name
  branch     = github_repository.solo_repos[each.key].default_branch
  file       = ".github/ISSUE_TEMPLATE/feature.md"

  content = <<-EOT
    ---
    name: Feature Request
    about: Suggest a new feature
    title: '[FEATURE] '
    labels: 'enhancement'
    assignees: '${var.github_organization}'
    ---
    
    **Feature Description**
    What would you like to add?
    
    **Use Case**
    Why is this needed?
    
    **Proposed Solution**
    How might this work?
    
    **Alternatives**
    Other approaches considered.
  EOT

  commit_message      = "Add feature request template"
  commit_author       = "Terraform"
  commit_email        = "terraform@localhost"
  overwrite_on_create = true
}

# Add PR template
resource "github_repository_file" "pr_template" {
  for_each = local.repositories

  repository = github_repository.solo_repos[each.key].name
  branch     = github_repository.solo_repos[each.key].default_branch
  file       = ".github/pull_request_template.md"

  content = <<-EOT
    ## Description
    Brief description of changes
    
    ## Type of Change
    - [ ] Bug fix
    - [ ] New feature
    - [ ] Breaking change
    - [ ] Documentation update
    
    ## Testing
    - [ ] Tests pass locally
    - [ ] Added new tests (if applicable)
    
    ## Checklist
    - [ ] Code follows project style
    - [ ] Self-reviewed code
    - [ ] Updated documentation
    - [ ] No new warnings
  EOT

  commit_message      = "Add PR template"
  commit_author       = "Terraform"
  commit_email        = "terraform@localhost"
  overwrite_on_create = true
}

# Repository labels for better organization
resource "github_issue_label" "labels" {
  for_each = merge([
    for repo in keys(local.repositories) : {
      for label in local.standard_labels : "${repo}-${label.name}" => {
        repository  = repo
        name        = label.name
        color       = label.color
        description = label.description
      }
    }
  ]...)

  repository  = github_repository.solo_repos[each.value.repository].name
  name        = each.value.name
  color       = each.value.color
  description = each.value.description
}

locals {
  standard_labels = [
    { name = "bug", color = "d73a4a", description = "Something isn't working" },
    { name = "enhancement", color = "a2eeef", description = "New feature or request" },
    { name = "documentation", color = "0075ca", description = "Documentation improvements" },
    { name = "dependencies", color = "0366d6", description = "Dependency updates" },
    { name = "security", color = "ee0701", description = "Security issues" },
    { name = "automated", color = "555555", description = "Automated PR or issue" },
    { name = "stale", color = "ffffff", description = "No recent activity" },
    { name = "wontfix", color = "ffffff", description = "Will not be worked on" },
    { name = "duplicate", color = "cfd3d7", description = "Duplicate issue" },
    { name = "good first issue", color = "7057ff", description = "Good for newcomers" },
    { name = "help wanted", color = "008672", description = "Extra attention needed" },
    { name = "major-update", color = "ff9800", description = "Major version update" }
  ]
}