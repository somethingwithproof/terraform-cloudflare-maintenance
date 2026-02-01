// Package test contains end-to-end tests for the Terraform Cloudflare Maintenance module
package test

import (
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestMaintenanceModuleBasic tests basic module functionality
func TestMaintenanceModuleBasic(t *testing.T) {
	t.Parallel()

	// Skip if required environment variables are not set
	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	uniqueID := random.UniqueId()
	workerRoute := fmt.Sprintf("test-%s.example.com/*", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"cloudflare_api_token":   os.Getenv("CLOUDFLARE_API_TOKEN"),
			"cloudflare_account_id":  os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
			"cloudflare_zone_id":     os.Getenv("CLOUDFLARE_ZONE_ID"),
			"enabled":                true,
			"maintenance_title":      "E2E Test Maintenance",
			"maintenance_message":    "This is an automated E2E test",
			"contact_email":          "test@example.com",
			"worker_route":           workerRoute,
			"environment":            "test",
		},
		NoColor: true,
	})

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the module
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	workerScriptName := terraform.Output(t, terraformOptions, "worker_script_name")
	assert.NotEmpty(t, workerScriptName, "Worker script name should not be empty")

	maintenanceStatus := terraform.Output(t, terraformOptions, "maintenance_status")
	assert.Equal(t, "ENABLED", maintenanceStatus, "Maintenance status should be ENABLED")

	workerRoutePattern := terraform.Output(t, terraformOptions, "worker_route_pattern")
	assert.NotEqual(t, "Maintenance mode disabled", workerRoutePattern, "Worker route should be configured")

	environment := terraform.Output(t, terraformOptions, "environment")
	assert.Equal(t, "test", environment, "Environment should match input")
}

// TestMaintenanceModuleDisabled tests module with maintenance disabled
func TestMaintenanceModuleDisabled(t *testing.T) {
	t.Parallel()

	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	uniqueID := random.UniqueId()
	workerRoute := fmt.Sprintf("test-%s.example.com/*", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"cloudflare_api_token":   os.Getenv("CLOUDFLARE_API_TOKEN"),
			"cloudflare_account_id":  os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
			"cloudflare_zone_id":     os.Getenv("CLOUDFLARE_ZONE_ID"),
			"enabled":                false,
			"maintenance_title":      "Disabled Test",
			"worker_route":           workerRoute,
			"environment":            "test",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate disabled state
	maintenanceStatus := terraform.Output(t, terraformOptions, "maintenance_status")
	assert.Equal(t, "DISABLED", maintenanceStatus, "Maintenance status should be DISABLED")

	workerRoutePattern := terraform.Output(t, terraformOptions, "worker_route_pattern")
	assert.Equal(t, "Maintenance mode disabled", workerRoutePattern, "Worker route should indicate disabled")

	dnsRecordID := terraform.Output(t, terraformOptions, "dns_record_id")
	assert.Equal(t, "No DNS record created", dnsRecordID, "No DNS record should be created when disabled")

	rulesetID := terraform.Output(t, terraformOptions, "ruleset_id")
	assert.Equal(t, "No ruleset created", rulesetID, "No ruleset should be created when disabled")
}

// TestMaintenanceModuleWithIPAllowlist tests IP allowlist functionality
func TestMaintenanceModuleWithIPAllowlist(t *testing.T) {
	t.Parallel()

	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	uniqueID := random.UniqueId()
	workerRoute := fmt.Sprintf("test-%s.example.com/*", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"cloudflare_api_token":   os.Getenv("CLOUDFLARE_API_TOKEN"),
			"cloudflare_account_id":  os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
			"cloudflare_zone_id":     os.Getenv("CLOUDFLARE_ZONE_ID"),
			"enabled":                true,
			"maintenance_title":      "IP Allowlist Test",
			"worker_route":           workerRoute,
			"environment":            "test",
			"allowed_ips":            []string{"192.168.1.1", "10.0.0.1", "8.8.8.8"},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate ruleset is created
	rulesetID := terraform.Output(t, terraformOptions, "ruleset_id")
	assert.NotEqual(t, "No ruleset created", rulesetID, "Ruleset should be created for IP allowlist")
}

// TestMaintenanceModuleWithRegionAllowlist tests region allowlist functionality
func TestMaintenanceModuleWithRegionAllowlist(t *testing.T) {
	t.Parallel()

	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	uniqueID := random.UniqueId()
	workerRoute := fmt.Sprintf("test-%s.example.com/*", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"cloudflare_api_token":   os.Getenv("CLOUDFLARE_API_TOKEN"),
			"cloudflare_account_id":  os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
			"cloudflare_zone_id":     os.Getenv("CLOUDFLARE_ZONE_ID"),
			"enabled":                true,
			"maintenance_title":      "Region Allowlist Test",
			"worker_route":           workerRoute,
			"environment":            "test",
			"allowed_regions":        []string{"US", "CA", "GB"},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	rulesetID := terraform.Output(t, terraformOptions, "ruleset_id")
	assert.NotEqual(t, "No ruleset created", rulesetID, "Ruleset should be created for region allowlist")

	allowedRegions := terraform.OutputList(t, terraformOptions, "allowed_regions")
	assert.Len(t, allowedRegions, 3, "Should have 3 allowed regions")
	assert.Contains(t, allowedRegions, "US", "Should include US")
	assert.Contains(t, allowedRegions, "CA", "Should include CA")
	assert.Contains(t, allowedRegions, "GB", "Should include GB")
}

// TestMaintenanceModuleWithMaintenanceWindow tests scheduled maintenance window
func TestMaintenanceModuleWithMaintenanceWindow(t *testing.T) {
	t.Parallel()

	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	uniqueID := random.UniqueId()
	workerRoute := fmt.Sprintf("test-%s.example.com/*", uniqueID)

	// Set maintenance window
	startTime := time.Now().Add(1 * time.Hour).UTC().Format(time.RFC3339)
	endTime := time.Now().Add(3 * time.Hour).UTC().Format(time.RFC3339)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"cloudflare_api_token":   os.Getenv("CLOUDFLARE_API_TOKEN"),
			"cloudflare_account_id":  os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
			"cloudflare_zone_id":     os.Getenv("CLOUDFLARE_ZONE_ID"),
			"enabled":                true,
			"maintenance_title":      "Scheduled Maintenance Test",
			"worker_route":           workerRoute,
			"environment":            "test",
			"maintenance_window": map[string]string{
				"start_time": startTime,
				"end_time":   endTime,
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate maintenance window output
	maintenanceWindow := terraform.OutputMap(t, terraformOptions, "maintenance_window")
	assert.Equal(t, startTime, maintenanceWindow["start_time"], "Start time should match")
	assert.Equal(t, endTime, maintenanceWindow["end_time"], "End time should match")
}

// TestMaintenanceModuleWithRateLimiting tests rate limiting functionality
func TestMaintenanceModuleWithRateLimiting(t *testing.T) {
	t.Parallel()

	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	uniqueID := random.UniqueId()
	workerRoute := fmt.Sprintf("test-%s.example.com/*", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"cloudflare_api_token":   os.Getenv("CLOUDFLARE_API_TOKEN"),
			"cloudflare_account_id":  os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
			"cloudflare_zone_id":     os.Getenv("CLOUDFLARE_ZONE_ID"),
			"enabled":                true,
			"maintenance_title":      "Rate Limit Test",
			"worker_route":           workerRoute,
			"environment":            "test",
			"rate_limit": map[string]interface{}{
				"enabled":             true,
				"requests_per_period": 100,
				"period":              60,
				"action":              "block",
				"mitigation_timeout":  600,
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate rate limiting outputs
	rateLimitEnabled := terraform.Output(t, terraformOptions, "rate_limit_enabled")
	assert.Equal(t, "true", rateLimitEnabled, "Rate limit should be enabled")

	rateLimitRulesetID := terraform.Output(t, terraformOptions, "rate_limit_ruleset_id")
	assert.NotEmpty(t, rateLimitRulesetID, "Rate limit ruleset ID should not be empty")
}

// TestMaintenanceModuleWithCustomStyling tests custom CSS and logo
func TestMaintenanceModuleWithCustomStyling(t *testing.T) {
	t.Parallel()

	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	uniqueID := random.UniqueId()
	workerRoute := fmt.Sprintf("test-%s.example.com/*", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"cloudflare_api_token":   os.Getenv("CLOUDFLARE_API_TOKEN"),
			"cloudflare_account_id":  os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
			"cloudflare_zone_id":     os.Getenv("CLOUDFLARE_ZONE_ID"),
			"enabled":                true,
			"maintenance_title":      "Custom Style Test",
			"maintenance_message":    "Testing custom styling",
			"worker_route":           workerRoute,
			"environment":            "test",
			"custom_css":             "body { background-color: #1a1a2e; color: white; }",
			"logo_url":               "https://example.com/logo.png",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate the module deployed successfully
	maintenanceStatus := terraform.Output(t, terraformOptions, "maintenance_status")
	assert.Equal(t, "ENABLED", maintenanceStatus, "Maintenance should be enabled with custom styling")
}

// TestMaintenanceModuleIdempotency tests that multiple applies produce the same result
func TestMaintenanceModuleIdempotency(t *testing.T) {
	t.Parallel()

	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	uniqueID := random.UniqueId()
	workerRoute := fmt.Sprintf("test-%s.example.com/*", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"cloudflare_api_token":   os.Getenv("CLOUDFLARE_API_TOKEN"),
			"cloudflare_account_id":  os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
			"cloudflare_zone_id":     os.Getenv("CLOUDFLARE_ZONE_ID"),
			"enabled":                true,
			"maintenance_title":      "Idempotency Test",
			"worker_route":           workerRoute,
			"environment":            "test",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	// First apply
	terraform.InitAndApply(t, terraformOptions)
	firstWorkerName := terraform.Output(t, terraformOptions, "worker_script_name")

	// Second apply (should be idempotent)
	terraform.Apply(t, terraformOptions)
	secondWorkerName := terraform.Output(t, terraformOptions, "worker_script_name")

	// Verify idempotency
	assert.Equal(t, firstWorkerName, secondWorkerName, "Worker name should be the same after multiple applies")
}

// TestMaintenanceModuleEnvironments tests different environment configurations
func TestMaintenanceModuleEnvironments(t *testing.T) {
	t.Parallel()

	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	environments := []string{"development", "staging", "production"}

	for _, env := range environments {
		env := env // capture range variable
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			uniqueID := random.UniqueId()
			workerRoute := fmt.Sprintf("test-%s-%s.example.com/*", env, uniqueID)

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../",
				Vars: map[string]interface{}{
					"cloudflare_api_token":   os.Getenv("CLOUDFLARE_API_TOKEN"),
					"cloudflare_account_id":  os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
					"cloudflare_zone_id":     os.Getenv("CLOUDFLARE_ZONE_ID"),
					"enabled":                true,
					"maintenance_title":      fmt.Sprintf("%s Maintenance", env),
					"worker_route":           workerRoute,
					"environment":            env,
				},
				NoColor: true,
			})

			defer terraform.Destroy(t, terraformOptions)

			terraform.InitAndApply(t, terraformOptions)

			outputEnv := terraform.Output(t, terraformOptions, "environment")
			assert.Equal(t, env, outputEnv, "Environment should match input")
		})
	}
}

// TestMaintenanceModuleCombinedFeatures tests all features together
func TestMaintenanceModuleCombinedFeatures(t *testing.T) {
	t.Parallel()

	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	uniqueID := random.UniqueId()
	workerRoute := fmt.Sprintf("test-%s.example.com/*", uniqueID)
	startTime := time.Now().Add(1 * time.Hour).UTC().Format(time.RFC3339)
	endTime := time.Now().Add(3 * time.Hour).UTC().Format(time.RFC3339)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"cloudflare_api_token":   os.Getenv("CLOUDFLARE_API_TOKEN"),
			"cloudflare_account_id":  os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
			"cloudflare_zone_id":     os.Getenv("CLOUDFLARE_ZONE_ID"),
			"enabled":                true,
			"maintenance_title":      "Full Feature Test",
			"maintenance_message":    "Testing all features",
			"contact_email":          "test@example.com",
			"worker_route":           workerRoute,
			"environment":            "test",
			"allowed_ips":            []string{"192.168.1.1", "10.0.0.1"},
			"allowed_regions":        []string{"US", "CA"},
			"custom_css":             "body { background: #000; }",
			"logo_url":               "https://example.com/logo.png",
			"maintenance_window": map[string]string{
				"start_time": startTime,
				"end_time":   endTime,
			},
			"rate_limit": map[string]interface{}{
				"enabled":             true,
				"requests_per_period": 50,
				"period":              30,
				"action":              "block",
				"mitigation_timeout":  300,
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate all outputs
	maintenanceStatus := terraform.Output(t, terraformOptions, "maintenance_status")
	assert.Equal(t, "ENABLED", maintenanceStatus)

	rulesetID := terraform.Output(t, terraformOptions, "ruleset_id")
	assert.NotEqual(t, "No ruleset created", rulesetID)

	allowedRegions := terraform.OutputList(t, terraformOptions, "allowed_regions")
	assert.Len(t, allowedRegions, 2)

	maintenanceWindow := terraform.OutputMap(t, terraformOptions, "maintenance_window")
	assert.Equal(t, startTime, maintenanceWindow["start_time"])

	rateLimitEnabled := terraform.Output(t, terraformOptions, "rate_limit_enabled")
	assert.Equal(t, "true", rateLimitEnabled)
}

// Helper function to skip tests if environment variables are missing
func skipIfMissingEnvVars(t *testing.T, envVars []string) {
	for _, envVar := range envVars {
		if os.Getenv(envVar) == "" {
			t.Skipf("Skipping test: %s environment variable not set", envVar)
		}
	}
}

// TestMaintenanceModuleValidationErrors tests that invalid inputs produce errors
func TestMaintenanceModuleValidationErrors(t *testing.T) {
	t.Parallel()

	skipIfMissingEnvVars(t, []string{
		"CLOUDFLARE_API_TOKEN",
		"CLOUDFLARE_ACCOUNT_ID",
		"CLOUDFLARE_ZONE_ID",
	})

	testCases := []struct {
		name        string
		vars        map[string]interface{}
		expectError bool
	}{
		{
			name: "Invalid rate limit period (too low)",
			vars: map[string]interface{}{
				"rate_limit": map[string]interface{}{
					"enabled": true,
					"period":  5, // Below minimum of 10
				},
			},
			expectError: true,
		},
		{
			name: "Invalid rate limit action",
			vars: map[string]interface{}{
				"rate_limit": map[string]interface{}{
					"enabled": true,
					"action":  "invalid_action",
				},
			},
			expectError: true,
		},
		{
			name: "Invalid region code",
			vars: map[string]interface{}{
				"allowed_regions": []string{"USA"}, // Should be "US"
			},
			expectError: true,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			uniqueID := random.UniqueId()
			baseVars := map[string]interface{}{
				"cloudflare_api_token":  os.Getenv("CLOUDFLARE_API_TOKEN"),
				"cloudflare_account_id": os.Getenv("CLOUDFLARE_ACCOUNT_ID"),
				"cloudflare_zone_id":    os.Getenv("CLOUDFLARE_ZONE_ID"),
				"enabled":               true,
				"worker_route":          fmt.Sprintf("test-%s.example.com/*", uniqueID),
				"environment":           "test",
			}

			// Merge test-specific vars
			for k, v := range tc.vars {
				baseVars[k] = v
			}

			terraformOptions := &terraform.Options{
				TerraformDir: "../../",
				Vars:         baseVars,
				NoColor:      true,
			}

			_, err := terraform.InitAndPlanE(t, terraformOptions)

			if tc.expectError {
				require.Error(t, err, "Expected validation error for: %s", tc.name)
			} else {
				require.NoError(t, err, "Did not expect error for: %s", tc.name)
			}
		})
	}
}
