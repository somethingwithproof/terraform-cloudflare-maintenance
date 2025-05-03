#!/usr/bin/env bash
# fix.sh - Script to fix issues in the terraform-cloudflare-maintenance repository

set -euo pipefail

# Define emoji mapping for conventional commits
declare -A EMOJI
EMOJI=(
  ["feat"]="✨"
  ["fix"]="🐛"
  ["docs"]="📝"
  ["style"]="🎨"
  ["refactor"]="♻️"
  ["test"]="🧪"
  ["chore"]="🔧"
  ["ci"]="👷"
)

echo "🔍 Checking for issues in the repository..."

# 1. Fix worker build script permissions
echo "🔧 Fixing worker build script permissions..."
chmod +x worker/build.sh
git add worker/build.sh
git commit -m "fix(worker): make build script executable ${EMOJI[fix]}"

# 2. Update backend configuration
echo "🔄 Updating backend configuration..."
sed -i '' 's/your-org/example-org/g' backend.tf
git add backend.tf
git commit -m "fix(config): update backend organization name ${EMOJI[fix]}"

# 3. Update worker dependencies
echo "📦 Updating worker dependencies..."
cd worker
npm update
git add package.json package-lock.json
cd ..
git commit -m "chore(deps): update worker dependencies ${EMOJI[chore]}"

# 4. Create GitHub workflow directory if it doesn't exist
if [ ! -d ".github/workflows" ]; then
  echo "📁 Creating GitHub workflows directory..."
  mkdir -p .github/workflows
  
  # Add CI workflow
  cat > .github/workflows/ci.yml << EOF
name: CI
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      - name: Terraform Format
        run: terraform fmt -check -recursive
      - name: Terraform Validate
        run: terraform validate
  
  test-worker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - name: Install dependencies
        run: cd worker && npm ci
      - name: Run tests
        run: cd worker && npm test
EOF
  
  git add .github/workflows/ci.yml
  git commit -m "ci(workflow): add GitHub Actions workflow ${EMOJI[ci]}"
fi

# 5. Ensure go.mod exists for tests
if [ ! -f "tests/integration/go.mod" ]; then
  echo "🧪 Setting up Go module for tests..."
  mkdir -p tests/integration
  cat > tests/integration/go.mod << EOF
module github.com/thomasvincent/terraform-cloudflare-maintenance/tests/integration

go 1.20

require github.com/gruntwork-io/terratest v0.43.0
EOF
  
  git add tests/integration/go.mod
  git commit -m "test(integration): add Go module file ${EMOJI[test]}"
fi

# 6. Apply terraform formatting
echo "🎨 Applying terraform formatting..."
terraform fmt -recursive
git add .
git commit -m "style(format): apply terraform fmt ${EMOJI[style]}"

echo "✅ Repository fixes complete!"
echo "📝 You can now push the changes with: git push origin main"
