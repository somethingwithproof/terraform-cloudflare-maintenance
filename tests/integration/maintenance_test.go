package test

import (
	"testing"
	"os/exec"
	"strings"
	"fmt"
)

// TestMaintenancePageBasicDeployment tests the basic deployment of the maintenance page
func TestMaintenancePageBasicDeployment(t *testing.T) {
	// Skip test if not running in CI environment
	t.Skip("Skipping test in local environment. Run in CI with proper credentials.")

	// Test directory
	testDir := "../../examples/basic-usage"

	// Run terraform init
	cmd := exec.Command("terraform", "init")
	cmd.Dir = testDir
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("terraform init failed: %v\nOutput: %s", err, output)
	}

	// Run terraform validate
	cmd = exec.Command("terraform", "validate")
	cmd.Dir = testDir
	output, err = cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("terraform validate failed: %v\nOutput: %s", err, output)
	}

	// Check if validation was successful
	if !strings.Contains(string(output), "Success!") {
		t.Errorf("terraform validate did not succeed: %s", output)
	}

	fmt.Println("Basic deployment test passed validation")
}

// TestMaintenancePageAdvancedConfig tests the advanced configuration of the maintenance page
func TestMaintenancePageAdvancedConfig(t *testing.T) {
	// Skip test if not running in CI environment
	t.Skip("Skipping test in local environment. Run in CI with proper credentials.")

	// Test directory
	testDir := "../../examples/advanced-config"

	// Run terraform init
	cmd := exec.Command("terraform", "init")
	cmd.Dir = testDir
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("terraform init failed: %v\nOutput: %s", err, output)
	}

	// Run terraform validate
	cmd = exec.Command("terraform", "validate")
	cmd.Dir = testDir
	output, err = cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("terraform validate failed: %v\nOutput: %s", err, output)
	}

	// Check if validation was successful
	if !strings.Contains(string(output), "Success!") {
		t.Errorf("terraform validate did not succeed: %s", output)
	}

	fmt.Println("Advanced configuration test passed validation")
}
