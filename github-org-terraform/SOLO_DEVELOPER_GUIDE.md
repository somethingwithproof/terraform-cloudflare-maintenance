# Solo Developer GitHub Management Guide

## Quick Start

This configuration is optimized for a single developer managing their GitHub repositories with maximum automation and minimal friction.

### 1. Initial Setup (5 minutes)

```bash
# Set your GitHub token
export GITHUB_TOKEN="your-github-token"

# Initialize Terraform
terraform init

# Review the solo developer configuration
cat solo-developer.tfvars

# Edit your email for security notifications
sed -i '' 's/your-email@example.com/YOUR_ACTUAL_EMAIL/' solo-developer.tfvars
```

### 2. Deploy Everything

```bash
# Plan with solo developer settings
terraform plan -var-file="solo-developer.tfvars"

# Apply configuration
terraform apply -var-file="solo-developer.tfvars"
```

## What This Does

### 🤖 **Dependabot Everywhere**
- ✅ Automatically configured for all 20 repositories
- ✅ Detects language/framework automatically
- ✅ **Monthly updates** (First Monday at 4 AM) for regular dependencies
- ✅ **Immediate security updates** (auto-merged)
- ✅ Manual review for non-security updates
- ✅ Lower PR noise with monthly batching

### 🔒 **Security Features**
- ✅ Secret scanning enabled (prevents credential leaks)
- ✅ Vulnerability alerts on all repos
- ✅ Security policy (SECURITY.md) added
- ✅ Comprehensive .gitignore files
- ✅ Weekly security scans

### 🧹 **Automated Maintenance**
- ✅ Stale issue/PR cleanup
- ✅ Merged branch deletion
- ✅ Repository statistics generation
- ✅ Consistent issue/PR templates
- ✅ Standardized labels across all repos

### 📊 **Repository Configuration**
All repositories get:
- Vulnerability alerts
- Delete branch on merge
- Auto-merge capability (for Dependabot)
- Consistent merge strategies
- Security scanning

## Dependabot Languages Configured

| Repository | Languages/Ecosystems |
|------------|---------------------|
| terraform-* repos | Terraform, GitHub Actions |
| chef-* cookbooks | Ruby/Bundler |
| Python projects | pip, GitHub Actions |
| Rust projects | Cargo, GitHub Actions |
| Node.js projects | npm, Docker |
| Ansible roles | pip, GitHub Actions |

## Solo Developer Benefits

### No Team Complexity
- No team management needed
- No required PR reviews
- No branch protection blocking you
- Direct push access maintained

### Smart Update Strategy
- **Security fixes**: Immediate and auto-merged
- **Regular updates**: Monthly batches to reduce noise
- **Manual control**: Review non-security updates at your pace
- **Less interruption**: ~5 PRs/month instead of weekly noise

### Flexibility
- Force push when needed
- Work directly on main
- Override any automation
- Manual control retained

## Monitoring Your Repos

### Check Dependabot Status
```bash
terraform output dependabot_status
```

### View Security Coverage
```bash
# See which repos have security features
gh api /user/repos --jq '.[] | select(.owner.login=="thomasvincent") | {name, vulnerability_alerts}'
```

### Check for Open Dependabot PRs
```bash
gh pr list --author "dependabot[bot]" --state open --repo thomasvincent/REPO_NAME
```

## Customization Options

### Disable Dependabot for Specific Repos
Edit `dependabot.tf`:
```hcl
repo_ecosystems = {
  # Comment out repos you don't want
  # "repo-name" = ["ecosystem"]
}
```

### Change Update Schedule
Current: **Monthly regular updates, immediate security updates**

To change in `dependabot.tf`:
```hcl
schedule = "monthly"  # Current setting (recommended)
# Options: "daily", "weekly", "monthly"
time     = "04:00"    # 24-hour format
```

### Add Webhook Notifications
Edit `solo-developer.tfvars`:
```hcl
enable_notifications = true
webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

## Maintenance Commands

### Update All Terraform Resources
```bash
terraform apply -var-file="solo-developer.tfvars" -auto-approve
```

### Force Recreate Dependabot Configs
```bash
terraform apply -var-file="solo-developer.tfvars" -replace="github_repository_file.dependabot_config"
```

### Check What Changed
```bash
terraform plan -var-file="solo-developer.tfvars" -detailed-exitcode
```

## Troubleshooting

### Dependabot Not Creating PRs?
1. Check if enabled: `terraform output dependabot_status`
2. Verify ecosystem detection is correct in `dependabot.tf`
3. Check GitHub Settings > Security > Dependabot

### Too Many Dependabot PRs?
- Already optimized: Monthly updates + only 5 PRs at a time
- Security updates come through immediately (and auto-merge)
- Regular updates batch monthly for less noise

### Auto-merge Not Working?
1. Ensure `allow_auto_merge = true` in repository settings
2. Check the auto-merge workflow exists: `.github/workflows/dependabot-auto-merge.yml`
3. Verify GitHub Actions is enabled for the repository

## Security Notes

- **Never commit tokens**: Use environment variables
- **State file**: Contains sensitive data, keep secure
- **Secrets**: Managed with lifecycle ignore_changes
- **Dependabot**: Only auto-merges security updates
- **Update strategy**: Security fixes = immediate, others = monthly review

## Next Steps

After initial deployment:

1. **Monitor First Week**: Watch how Dependabot PRs come in
2. **Adjust Schedules**: Change timing if needed
3. **Review Major Updates**: Manually review major version bumps
4. **Check Security Alerts**: Review any vulnerability notifications

## Files Created

```
solo-dev-config.tf       # Main solo developer configuration
dependabot.tf           # Dependabot setup for all repos
solo-security.tf        # Security features
solo-automation.tf      # Automated maintenance
solo-developer.tfvars   # Your configuration values
```

## Support

- Run `./validate.sh` to check configuration
- Check logs in GitHub Actions for each repository
- Use `terraform plan` to preview any changes

---

**Remember**: This setup is designed to work quietly in the background. You should only need to intervene for major updates or security issues. Everything else is automated! 🚀