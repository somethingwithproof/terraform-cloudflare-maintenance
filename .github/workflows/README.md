# GitHub Workflows

## CodeQL Configuration

CodeQL runs through the advanced `codeql.yml` workflow (Go and
JavaScript/TypeScript), matching the owner's other repositories. GitHub's
default code scanning setup must stay disabled in the repository settings:
when both are enabled, GitHub rejects the workflow's SARIF uploads with
"CodeQL analyses from advanced configurations cannot be processed when the
default setup is enabled".
