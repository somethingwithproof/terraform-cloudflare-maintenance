# GitHub Organization Terraform Configuration

This Terraform configuration manages your GitHub organization/user repositories, teams, secrets, and branch protection rules.

## Features

- **Repository Management**: Creates and configures all repositories with consistent settings
- **Team Management**: Manages teams and their memberships
- **Secrets Management**: Handles organization and repository-level secrets
- **Branch Protection**: Configures branch protection rules for repositories
- **Local State**: Uses local Terraform state (no remote backend)

## Prerequisites

1. **GitHub Personal Access Token** with appropriate permissions:
   - `repo` (Full control of private repositories)
   - `admin:org` (Full control of orgs and teams)
   - `workflow` (Update GitHub Action workflows)

2. **Terraform** >= 1.0

3. **GitHub CLI** (gh) configured and authenticated

## Setup

1. Export your GitHub token:
   ```bash
   export GITHUB_TOKEN="your-personal-access-token"
   ```

2. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` to customize your configuration

4. Initialize Terraform:
   ```bash
   terraform init
   ```

## Usage

### Plan Changes
```bash
terraform plan
```

### Apply Configuration
```bash
terraform apply
```

### Import Existing Resources
To import existing repositories:
```bash
terraform import 'github_repository.repos["repo-name"]' repo-name
```

## File Structure

- `versions.tf` - Terraform and provider requirements
- `variables.tf` - Input variable definitions
- `repositories.tf` - Repository resources and configurations
- `teams.tf` - Team and membership management
- `secrets.tf` - GitHub Actions secrets management
- `outputs.tf` - Output values for reference
- `terraform.tfvars.example` - Example configuration values
- `.gitignore` - Git ignore patterns for Terraform files

## Configuration

### Repository Settings
All repositories are configured with:
- Private visibility
- Issues enabled
- Projects/Wiki/Discussions configurable
- Branch deletion on merge
- Vulnerability alerts enabled
- Customizable merge strategies

### Secrets Management
Secrets are managed as placeholders. After applying Terraform:
1. Navigate to GitHub Settings
2. Update secret values manually
3. Terraform will ignore value changes (lifecycle rule)

### Branch Protection
Configure branch protection rules in `terraform.tfvars`:
```hcl
branch_protection_rules = {
  "repo-name" = {
    pattern                         = "main"
    enforce_admins                  = false
    require_signed_commits          = false
    required_status_checks          = ["ci/build", "ci/test"]
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
    required_approving_review_count = 1
  }
}
```

## State Management

This configuration uses **local state** stored in `terraform.tfstate`. 

⚠️ **Important**: 
- Do not commit `terraform.tfstate` to version control
- Back up your state file regularly
- Consider using remote state for team environments

## Security Notes

- Never commit `terraform.tfvars` with real secret values
- Use environment variables for sensitive data
- The `.gitignore` file excludes sensitive files
- Secret values are managed as placeholders

## Outputs

After applying, Terraform provides:
- Repository URLs (HTTPS and SSH)
- Repository IDs
- Team IDs
- Default branches

Access outputs:
```bash
terraform output repository_urls
terraform output repository_ssh_urls
```

## Troubleshooting

### Authentication Issues
Ensure your GitHub token has required permissions:
```bash
gh auth status
gh auth refresh -h github.com -s admin:org,repo,workflow
```

### Import Conflicts
If resources already exist, import them before applying:
```bash
terraform import 'github_repository.repos["existing-repo"]' existing-repo
```

### State Lock
If state is locked, ensure no other Terraform processes are running.

## Maintenance

### Adding New Repositories
1. Add repository definition in `repositories.tf`
2. Run `terraform plan` to preview
3. Run `terraform apply` to create

### Updating Settings
1. Modify configuration in respective `.tf` files
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to update

### Removing Resources
1. Remove from configuration files
2. Run `terraform plan` to preview destruction
3. Run `terraform apply` to remove from GitHub

## License

This configuration is provided as-is for managing your GitHub organization.