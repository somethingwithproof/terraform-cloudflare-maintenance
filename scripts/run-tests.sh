#!/usr/bin/env bash
# Runs the test suites locally.
# Usage: ./scripts/run-tests.sh [--worker] [--terraform] [--e2e] [--coverage]
#
#   --worker      Worker and notify.sh tests, type check and lint (worker/)
#   --terraform   OpenTofu tests for the module and the notifications module
#   --e2e         Terratest against a real zone; needs the CF_E2E_* settings
#                 described in the README and creates real resources
#   --coverage    Collect Worker test coverage
#
# With no suite named, runs --worker and --terraform.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
worker=false terraform=false e2e=false coverage=false

for arg in "$@"; do
  case "$arg" in
  --worker) worker=true ;;
  --terraform) terraform=true ;;
  --e2e) e2e=true ;;
  --coverage) coverage=true ;;
  -h | --help)
    sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "Unknown option: $arg (see --help)" >&2
    exit 2
    ;;
  esac
done
if ! $worker && ! $terraform && ! $e2e; then
  worker=true terraform=true
fi

if $worker; then
  echo "== Worker"
  cd "$root/worker"
  npm ci --ignore-scripts
  npm run typecheck
  npm run lint
  if $coverage; then npm run test:coverage; else npm test; fi
fi

if $terraform; then
  echo "== OpenTofu"
  for dir in "$root" "$root/modules/notifications"; do
    cd "$dir"
    tofu init -backend=false -input=false >/dev/null
    tofu test
  done
  "$root/modules/notifications/tests/apply-handoff.sh"
fi

if $e2e; then
  echo "== Terratest E2E"
  cd "$root/tests/e2e"
  go test -v -timeout 30m ./...
fi
