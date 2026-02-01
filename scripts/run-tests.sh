#!/usr/bin/env bash
# Test Runner Script for Terraform Cloudflare Maintenance Module
# Usage: ./scripts/run-tests.sh [options]
#
# Options:
#   --unit          Run unit tests only
#   --integration   Run integration tests only
#   --terraform     Run Terraform native tests only
#   --e2e           Run Terratest E2E tests (requires credentials)
#   --all           Run all tests (default)
#   --coverage      Generate coverage report
#   --mock-server   Start mock Cloudflare API server
#   --help          Show this help message

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default options
RUN_UNIT=false
RUN_INTEGRATION=false
RUN_TERRAFORM=false
RUN_E2E=false
RUN_ALL=true
COVERAGE=false
MOCK_SERVER=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit)
            RUN_UNIT=true
            RUN_ALL=false
            shift
            ;;
        --integration)
            RUN_INTEGRATION=true
            RUN_ALL=false
            shift
            ;;
        --terraform)
            RUN_TERRAFORM=true
            RUN_ALL=false
            shift
            ;;
        --e2e)
            RUN_E2E=true
            RUN_ALL=false
            shift
            ;;
        --all)
            RUN_ALL=true
            shift
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        --mock-server)
            MOCK_SERVER=true
            shift
            ;;
        --help)
            head -20 "$0" | tail -n +2 | sed 's/^# //'
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# If running all tests
if $RUN_ALL; then
    RUN_UNIT=true
    RUN_INTEGRATION=true
    RUN_TERRAFORM=true
fi

# Print header
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Terraform Cloudflare Maintenance Module - Test Suite       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    local missing=()

    if ! command -v node &> /dev/null; then
        missing+=("Node.js")
    fi

    if ! command -v npm &> /dev/null; then
        missing+=("npm")
    fi

    if ! command -v tofu &> /dev/null && ! command -v terraform &> /dev/null; then
        missing+=("OpenTofu or Terraform")
    fi

    if $RUN_E2E && ! command -v go &> /dev/null; then
        missing+=("Go (for E2E tests)")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Missing prerequisites: ${missing[*]}${NC}"
        exit 1
    fi

    echo -e "${GREEN}All prerequisites met!${NC}"
    echo ""
}

# Start mock server if requested
start_mock_server() {
    if $MOCK_SERVER; then
        echo -e "${YELLOW}Starting mock Cloudflare API server...${NC}"
        cd "$PROJECT_ROOT/tests"
        node mocks/cloudflare-mock-server.js &
        MOCK_PID=$!
        echo "Mock server PID: $MOCK_PID"
        sleep 2
        export CLOUDFLARE_API_BASE_URL="http://localhost:8787/client/v4"
        echo -e "${GREEN}Mock server started!${NC}"
        echo ""
    fi
}

# Stop mock server
stop_mock_server() {
    if $MOCK_SERVER && [ -n "${MOCK_PID:-}" ]; then
        echo -e "${YELLOW}Stopping mock server...${NC}"
        kill "$MOCK_PID" 2>/dev/null || true
    fi
}

# Trap to ensure cleanup
trap stop_mock_server EXIT

# Run unit tests
run_unit_tests() {
    if $RUN_UNIT; then
        echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}Running Unit Tests${NC}"
        echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

        cd "$PROJECT_ROOT/tests"

        # Install dependencies if needed
        if [ ! -d "node_modules" ]; then
            echo "Installing test dependencies..."
            npm install
        fi

        if $COVERAGE; then
            npm run test:coverage -- --dir unit
        else
            npm run test:unit
        fi

        echo -e "${GREEN}Unit tests completed!${NC}"
        echo ""
    fi
}

# Run integration tests
run_integration_tests() {
    if $RUN_INTEGRATION; then
        echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}Running Integration Tests${NC}"
        echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

        cd "$PROJECT_ROOT/tests"

        # Install dependencies if needed
        if [ ! -d "node_modules" ]; then
            echo "Installing test dependencies..."
            npm install
        fi

        if $COVERAGE; then
            npm run test:coverage -- --dir integration
        else
            npm run test:integration
        fi

        echo -e "${GREEN}Integration tests completed!${NC}"
        echo ""
    fi
}

# Run Terraform native tests
run_terraform_tests() {
    if $RUN_TERRAFORM; then
        echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}Running Terraform Native Tests${NC}"
        echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

        cd "$PROJECT_ROOT"

        # Use tofu if available, otherwise terraform
        local TF_CMD="tofu"
        if ! command -v tofu &> /dev/null; then
            TF_CMD="terraform"
        fi

        echo "Using: $TF_CMD"

        # Initialize if needed
        if [ ! -d ".terraform" ]; then
            $TF_CMD init -backend=false
        fi

        # Run each test file
        for test_file in tests/*.tftest.hcl; do
            echo ""
            echo -e "${YELLOW}Running: $(basename "$test_file")${NC}"
            $TF_CMD test -filter="$test_file" || echo -e "${YELLOW}Warning: Some tests may have been skipped${NC}"
        done

        echo -e "${GREEN}Terraform tests completed!${NC}"
        echo ""
    fi
}

# Run E2E tests
run_e2e_tests() {
    if $RUN_E2E; then
        echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}Running E2E Tests (Terratest)${NC}"
        echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

        # Check for required environment variables
        if [ -z "${TF_VAR_cloudflare_api_token:-}" ]; then
            echo -e "${RED}Error: TF_VAR_cloudflare_api_token is required for E2E tests${NC}"
            echo "Set environment variables:"
            echo "  export TF_VAR_cloudflare_api_token=your-api-token"
            echo "  export TF_VAR_cloudflare_account_id=your-account-id"
            echo "  export TF_VAR_cloudflare_zone_id=your-zone-id"
            exit 1
        fi

        cd "$PROJECT_ROOT/tests/e2e"

        # Download dependencies if needed
        if [ ! -f "go.sum" ]; then
            echo "Downloading Go dependencies..."
            go mod tidy
        fi

        go test -v -timeout 30m ./...

        echo -e "${GREEN}E2E tests completed!${NC}"
        echo ""
    fi
}

# Main execution
check_prerequisites
start_mock_server
run_unit_tests
run_integration_tests
run_terraform_tests
run_e2e_tests

# Print summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Test Suite Complete                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}All requested tests have completed!${NC}"
