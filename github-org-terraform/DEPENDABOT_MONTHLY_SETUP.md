# Dependabot Configuration: Monthly Updates + Security Priority

## Overview

Your Dependabot configuration has been optimized for a solo developer workflow with:
- **Monthly regular dependency updates** (reduces PR noise)
- **Immediate security updates** (auto-merged for safety)

## How It Works

### 📅 Monthly Schedule
- **When**: First Monday of each month at 4 AM
- **What**: Regular dependency updates (non-security)
- **PR Limit**: 5 PRs at a time (manageable batch)
- **Action Required**: Manual review and merge

### 🔒 Security Updates
- **When**: Immediately upon detection
- **What**: Security vulnerabilities only
- **Auto-merge**: Yes (automatically merged)
- **Action Required**: None (automatic)

## Benefits

1. **Less Interruption**: ~5 PRs per month instead of weekly noise
2. **Security First**: Critical fixes are immediate and automatic
3. **Batch Processing**: Review all updates once a month
4. **No Blocking**: Security never waits for your review

## PR Labels

| Label | Meaning | Action |
|-------|---------|--------|
| `security` | Security vulnerability fix | Auto-merged |
| `dependencies` | All Dependabot PRs | Informational |
| `automated` | Created by automation | Informational |
| `monthly-update` | Regular monthly update | Review when convenient |
| `major-update` | Major version change | Careful review needed |

## Workflow

### Security Update Flow
```
1. GitHub detects security vulnerability
2. Dependabot creates PR immediately
3. Auto-merge workflow runs
4. PR is automatically merged
5. You get notified (if configured)
```

### Monthly Update Flow
```
1. First Monday of month
2. Dependabot creates up to 5 PRs
3. PRs wait for your review
4. You review/merge at your convenience
5. Next batch created after merging
```

## Configuration Details

### Update Schedule by Ecosystem
All ecosystems configured for monthly updates:
- npm (Node.js)
- pip (Python)
- cargo (Rust)
- bundler (Ruby/Chef)
- terraform
- docker
- github-actions
- gomod (Go)

### Auto-merge Rules
```yaml
Auto-merge: ONLY if:
- dependency-type == "direct:production"
- AND (title contains "security" OR has "security" label)
```

### Repository Coverage
20/20 repositories configured with appropriate ecosystems:
- Chef cookbooks → bundler
- Python tools → pip
- Rust projects → cargo
- Terraform modules → terraform
- Node.js apps → npm
- All repos → github-actions

## Customization

### Change to Weekly Updates
In `dependabot.tf`, change:
```hcl
schedule = "monthly"  # Change to "weekly"
```

### Disable Security Auto-merge
In `solo-developer.tfvars`:
```hcl
enable_auto_merge = false  # Disables security auto-merge
```

### Adjust PR Limits
In `dependabot.tf`:
```hcl
open_pull_requests_limit = 5  # Increase/decrease as needed
```

## Monitoring

### Check Pending PRs
```bash
# All Dependabot PRs across your repos
gh search prs --owner=thomasvincent --author="app/dependabot" --state=open

# Security updates only
gh search prs --owner=thomasvincent --author="app/dependabot" --state=open --label=security
```

### View Update Schedule
```bash
# Check when next updates will occur
gh api /repos/thomasvincent/REPO_NAME/contents/.github/dependabot.yml --jq '.content' | base64 -d
```

## Best Practices

1. **Review Monthly**: Set a calendar reminder for first Monday
2. **Merge Security First**: Always prioritize security updates
3. **Test After Major Updates**: Run tests after major version changes
4. **Keep PR Count Low**: Merge/close PRs to stay under limit

## FAQ

**Q: Why monthly instead of weekly?**
A: As a solo developer, you don't need constant interruption. Security updates are immediate, everything else can batch monthly.

**Q: What if I miss the monthly review?**
A: PRs stay open until you review them. No rush.

**Q: Can I force an update check?**
A: Yes, through GitHub UI: Settings → Security → Dependabot → Check for updates

**Q: Are dev dependencies updated too?**
A: Yes, but grouped separately and clearly labeled.

---

This configuration gives you the best of both worlds: immediate security protection and manageable update batches.