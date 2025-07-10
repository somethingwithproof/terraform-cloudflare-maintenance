---
name: Bug report
about: Create a report to help us improve the Terraform CloudFlare Maintenance module
title: ''
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**Terraform Version**
Run `terraform version` to show the version. If you are not running the latest version of Terraform, please upgrade because your issue may have already been fixed.

**Module Version**
Which version of this module are you using?

**CloudFlare Configuration**
- CloudFlare Plan: [e.g., Free, Pro, Business, Enterprise]
- Worker Type: [e.g., Bundled, Service Worker]
- Zone Setup: [e.g., Full, Partial]

**Configuration**
```hcl
# Copy-paste your Terraform configuration here
```

**Debug Output**
Please provide a link to a GitHub Gist containing the complete debug output. Please do NOT paste the debug output in the issue; just paste a link to the Gist.

To obtain the debug output, run `terraform apply` with the environment variable `TF_LOG=DEBUG`.

**Expected behavior**
What should have happened?

**Actual behavior**
What actually happened?

**Steps to Reproduce**
1. `terraform init`
2. `terraform plan`
3. `terraform apply`

**Additional context**
Add any other context about the problem here.

**Important Factoids**
Are there anything atypical about your accounts that we should know?