#!/bin/bash
# Simple validation script for Terraform GitHub configuration

set -e

echo "🔍 GitHub Terraform Security Validation"
echo "======================================="

# Check for required tools
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed"
        return 1
    else
        echo "✅ $1 is installed"
        return 0
    fi
}

echo -e "\n1. Checking required tools:"
check_tool terraform
check_tool git
check_tool gh

# Check GitHub authentication
echo -e "\n2. Checking GitHub authentication:"
if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️  GITHUB_TOKEN not set - checking gh cli auth"
    if gh auth status &> /dev/null; then
        echo "✅ GitHub CLI authenticated"
    else
        echo "❌ No GitHub authentication found"
        echo "   Run: export GITHUB_TOKEN=your-token"
        echo "   Or:  gh auth login"
        exit 1
    fi
else
    echo "✅ GITHUB_TOKEN is set"
fi

# Terraform validation
echo -e "\n3. Validating Terraform configuration:"
terraform init -backend=false > /dev/null 2>&1
if terraform validate; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration has errors"
    exit 1
fi

# Check for sensitive data in files
echo -e "\n4. Checking for exposed secrets:"
SENSITIVE_PATTERNS=(
    "ghp_[a-zA-Z0-9]{36}"
    "github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}"
    "ghs_[a-zA-Z0-9]{36}"
    "ghu_[a-zA-Z0-9]{36}"
    "ghr_[a-zA-Z0-9]{36}"
    "AKIA[0-9A-Z]{16}"
)

FOUND_SECRETS=0
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -r "$pattern" . --exclude-dir=.git --exclude-dir=.terraform --exclude="*.tfstate*" --exclude="validate.sh" --exclude="*.md" 2>/dev/null; then
        echo "❌ Found potential secret matching pattern: $pattern"
        FOUND_SECRETS=1
    fi
done

if [ $FOUND_SECRETS -eq 0 ]; then
    echo "✅ No exposed secrets found"
fi

# Check state file security
echo -e "\n5. Checking state file security:"
if [ -f "terraform.tfstate" ]; then
    echo "⚠️  Local state file exists - ensure it's in .gitignore"
    if grep -q "terraform.tfstate" .gitignore 2>/dev/null; then
        echo "✅ terraform.tfstate is in .gitignore"
    else
        echo "❌ terraform.tfstate is NOT in .gitignore - add it immediately!"
        exit 1
    fi
else
    echo "✅ No local state file found"
fi

# Check for backend configuration
echo -e "\n6. Checking backend configuration:"
if grep -q 'backend "s3"' *.tf 2>/dev/null; then
    echo "✅ S3 backend configured (ensure encryption is enabled)"
elif grep -q 'backend "local"' *.tf 2>/dev/null; then
    echo "⚠️  Using local backend - consider S3 or Terraform Cloud for production"
else
    echo "⚠️  No backend explicitly configured - using default local backend"
fi

# Repository security check
echo -e "\n7. Checking repository configurations:"
if grep -q "vulnerability_alerts.*=.*true" repositories.tf 2>/dev/null; then
    echo "✅ Vulnerability alerts enabled"
else
    echo "⚠️  Vulnerability alerts not explicitly enabled"
fi

if grep -q "delete_branch_on_merge.*=.*true" repositories.tf 2>/dev/null; then
    echo "✅ Branch deletion on merge enabled"
else
    echo "⚠️  Branch deletion on merge not enabled"
fi

# Summary
echo -e "\n======================================="
echo "📊 Security Validation Summary"
echo "======================================="

if [ $FOUND_SECRETS -eq 0 ]; then
    echo "✅ Basic security checks passed"
    echo ""
    echo "📝 Recommendations:"
    echo "1. Use environment variables for sensitive values"
    echo "2. Consider using S3 backend with encryption for state"
    echo "3. Enable branch protection on all repositories"
    echo "4. Regularly rotate GitHub tokens"
    echo "5. Use GitHub App authentication for production"
else
    echo "❌ Security issues found - please fix before proceeding"
    exit 1
fi