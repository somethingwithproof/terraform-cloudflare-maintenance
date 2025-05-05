#!/bin/bash
#
# Terraform Cloudflare Maintenance Module Test Runner
# 
# This script runs all Terraform test files in the tests directory
# and provides a summary of the results.
#

# Terminal colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test summary counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Error handling
set -e
trap 'echo -e "${RED}Error: Command failed with exit code $?${NC}" >&2; exit 1' ERR

# Print banner
print_banner() {
  echo -e "${BLUE}====================================================================${NC}"
  echo -e "${BLUE}                 Terraform Test Runner                            ${NC}"
  echo -e "${BLUE}====================================================================${NC}"
  echo ""
}

# Print usage instructions
usage() {
  echo -e "Usage: $0 [options] [test_file]"
  echo ""
  echo "Options:"
  echo "  -h, --help      Show this help message"
  echo "  -v, --verbose   Enable verbose output"
  echo ""
  echo "Arguments:"
  echo "  test_file       Optional specific test file to run (without the tests/ path)"
  echo "                  If not provided, all test files will be run"
  echo ""
  exit 0
}

# Process command line arguments
VERBOSE=0
TEST_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    *)
      TEST_FILE="$1"
      shift
      ;;
  esac
done

# Check if terraform is installed
check_terraform() {
  if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: terraform is not installed or not in the PATH${NC}" >&2
    echo "Please install Terraform: https://developer.hashicorp.com/terraform/downloads"
    exit 1
  fi
  
  TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
  echo -e "${BLUE}Terraform version:${NC} $TF_VERSION"
  
  # Check terraform test command support
  if terraform -help test &> /dev/null; then
    echo -e "${GREEN}Terraform test command is supported${NC}"
  else
    echo -e "${RED}Error: Your Terraform version does not support the 'test' command${NC}" >&2
    echo "Please upgrade to Terraform v1.6.0 or later"
    exit 1
  fi
}

# Validate terraform configuration
validate_terraform() {
  echo -e "${BLUE}Validating Terraform configuration...${NC}"
  
  VALIDATE_OUTPUT=$(terraform validate -json)
  VALIDATE_RESULT=$(echo $VALIDATE_OUTPUT | jq -r '.valid')
  
  if [ "$VALIDATE_RESULT" == "true" ]; then
    echo -e "${GREEN}Terraform configuration is valid${NC}"
  else
    echo -e "${RED}Terraform configuration is invalid:${NC}"
    echo $VALIDATE_OUTPUT | jq -r '.error_count'
    echo $VALIDATE_OUTPUT | jq -r '.diagnostics'
    exit 1
  fi
}

# Run a specific test file
run_test_file() {
  local test_file="$1"
  local test_name=$(basename "$test_file" .tftest.hcl)
  
  echo -e "${BLUE}Running test:${NC} $test_name"
  
  # Check if the test file exists
  if [ ! -f "$test_file" ]; then
    echo -e "${RED}Error: Test file not found: $test_file${NC}" >&2
    return 1
  fi
  
  local start_time=$(date +%s)
  
  if [ $VERBOSE -eq 1 ]; then
    terraform test -filter="$test_file"
    TEST_RESULT=$?
  else
    terraform test -filter="$test_file" > /tmp/tf_test_$$.log 2>&1
    TEST_RESULT=$?
  fi
  
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  
  if [ $TEST_RESULT -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "${GREEN}✓ PASS${NC} $test_name ${BLUE}(${duration}s)${NC}"
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "${RED}✗ FAIL${NC} $test_name ${BLUE}(${duration}s)${NC}"
    if [ $VERBOSE -eq 0 ]; then
      echo -e "${YELLOW}Test output:${NC}"
      cat /tmp/tf_test_$$.log
    fi
  fi
  
  # Clean up temporary log file if it exists
  if [ -f "/tmp/tf_test_$$.log" ]; then
    rm /tmp/tf_test_$$.log
  fi
  
  return $TEST_RESULT
}

# Run all tests in the tests directory
run_all_tests() {
  local all_success=0
  local test_files=(tests/*.tftest.hcl)
  
  echo -e "${BLUE}Found ${#test_files[@]} test files${NC}"
  echo ""
  
  # Run each test file
  for test_file in "${test_files[@]}"; do
    run_test_file "$test_file" || all_success=1
    echo ""
  done
  
  return $all_success
}

# Run a specific test
run_specific_test() {
  local test_file="tests/$TEST_FILE"
  
  # Add .tftest.hcl extension if not provided
  if [[ ! "$test_file" == *.tftest.hcl ]]; then
    test_file="${test_file}.tftest.hcl"
  fi
  
  run_test_file "$test_file"
  return $?
}

# Print test summary
print_summary() {
  echo -e "${BLUE}====================================================================${NC}"
  echo -e "${BLUE}                         Test Summary                              ${NC}"
  echo -e "${BLUE}====================================================================${NC}"
  echo -e "Total:  $TOTAL_TESTS"
  echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
  if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
  else
    echo -e "Failed: $FAILED_TESTS"
  fi
  
  if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All tests passed successfully!${NC}"
    return 0
  else
    echo -e "${RED}Some tests failed.${NC}"
    return 1
  fi
}

# Check if Node.js is installed
check_nodejs() {
  if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed or not in the PATH${NC}" >&2
    echo "Please install Node.js: https://nodejs.org/"
    exit 1
  fi
  
  NODE_VERSION=$(node -v)
  echo -e "${BLUE}Node.js version:${NC} $NODE_VERSION"
}

# Run worker tests
run_worker_tests() {
  echo -e "${BLUE}====================================================================${NC}"
  echo -e "${BLUE}                Running Worker Tests                               ${NC}"
  echo -e "${BLUE}====================================================================${NC}"
  
  echo -e "${BLUE}Installing dependencies...${NC}"
  cd worker && npm ci
  
  echo -e "${BLUE}Running TypeScript type check...${NC}"
  npm run typecheck
  local typecheck_result=$?
  
  echo -e "${BLUE}Running ESLint...${NC}"
  npm run lint || true  # Don't fail on lint issues
  
  echo -e "${BLUE}Running tests...${NC}"
  npm test
  local test_result=$?
  
  cd ..
  
  if [ $typecheck_result -eq 0 ] && [ $test_result -eq 0 ]; then
    echo -e "${GREEN}Worker tests completed successfully!${NC}"
    return 0
  else
    echo -e "${RED}Worker tests failed.${NC}"
    return 1
  fi
}

# Run TFLint
run_tflint() {
  echo -e "${BLUE}====================================================================${NC}"
  echo -e "${BLUE}                Running TFLint                                     ${NC}"
  echo -e "${BLUE}====================================================================${NC}"
  
  if ! command -v tflint &> /dev/null; then
    echo -e "${YELLOW}Warning: TFLint is not installed, skipping TFLint checks${NC}"
    return 0
  fi
  
  echo -e "${BLUE}Running TFLint...${NC}"
  tflint --config=.tflint.hcl || true  # Don't fail on lint issues
  
  echo -e "${GREEN}TFLint completed!${NC}"
  return 0
}

# Run TFSec
run_tfsec() {
  echo -e "${BLUE}====================================================================${NC}"
  echo -e "${BLUE}                Running TFSec                                      ${NC}"
  echo -e "${BLUE}====================================================================${NC}"
  
  if ! command -v tfsec &> /dev/null; then
    echo -e "${YELLOW}Warning: TFSec is not installed, skipping security checks${NC}"
    return 0
  fi
  
  echo -e "${BLUE}Running TFSec...${NC}"
  tfsec . --no-color || true  # Don't fail on security issues during development
  
  echo -e "${GREEN}TFSec completed!${NC}"
  return 0
}

# Main function
main() {
  print_banner
  check_terraform
  check_nodejs
  validate_terraform
  run_tflint
  run_tfsec
  
  echo ""
  echo -e "${BLUE}Running Terraform tests...${NC}"
  echo ""
  
  # Initialize if needed
  if [ ! -d ".terraform" ]; then
    echo -e "${BLUE}Initializing Terraform...${NC}"
    terraform init -backend=false
  fi
  
  local tf_result=0
  local worker_result=0
  
  # Run Terraform tests
  if [ -n "$TEST_FILE" ]; then
    run_specific_test || tf_result=1
  else
    run_all_tests || tf_result=1
  fi
  
  # Run Worker tests
  run_worker_tests || worker_result=1
  
  # Print summary
  echo ""
  print_summary
  
  if [ $worker_result -eq 0 ]; then
    echo -e "${GREEN}Worker tests: PASSED${NC}"
  else
    echo -e "${RED}Worker tests: FAILED${NC}"
  fi
  
  if [ $tf_result -eq 0 ] && [ $worker_result -eq 0 ]; then
    echo -e "${GREEN}All tests passed successfully!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
  fi
}

# Execute main function
main

