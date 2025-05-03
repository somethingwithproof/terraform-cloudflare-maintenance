#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Building Cloudflare Worker..."
npm install
npm run build

if [ ! -f "dist/index.js" ]; then
  echo "Error: dist/index.js not found!"
  exit 1
fi

SCRIPT_CONTENT=$(cat dist/index.js | base64 | tr -d '\n')
echo "{\"script\":\"$(echo $SCRIPT_CONTENT | base64 --decode | jq -sR)\"}"
