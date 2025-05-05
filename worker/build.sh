#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Building Cloudflare Worker..."
# Install dependencies if node_modules doesn't exist or if package.json has changed
if [ ! -d "node_modules" ] || [ package.json -nt node_modules/.package-lock.json ]; then
  echo "Installing dependencies..."
  npm ci
fi

# Run typecheck
echo "Running type check..."
npm run typecheck

# Build optimized production version
echo "Building optimized production bundle..."
npm run build

if [ ! -f "dist/index.js" ]; then
  echo "Error: dist/index.js not found!"
  exit 1
fi

# Optimize the output further by removing whitespace in the JSON conversion
echo "Processing final output..."
SCRIPT_CONTENT=$(cat dist/index.js | gzip -9 | base64 | tr -d '\n')
echo "{\"script\":\"$(cat dist/index.js | jq -sR)\"}"
