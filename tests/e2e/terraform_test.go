// Package test contains end-to-end tests for the Terraform Cloudflare Maintenance module.
//
// The tests apply the module to a real Cloudflare account and zone, so they
// only run when the CF_E2E_* settings below are present; otherwise every test
// skips. Each test works on its own copy of the module (separate .terraform
// directory and state) and deploys a uniquely named Worker on a unique
// hostname, so the tests can run in parallel without sharing anything.
package test

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Settings read from the environment. CLOUDFLARE_API_TOKEN is read by the
// provider itself.
const (
	envAPIToken        = "CLOUDFLARE_API_TOKEN"
	envAccountID       = "CF_E2E_ACCOUNT_ID"
	envZoneID          = "CF_E2E_ZONE_ID"
	envZoneName        = "CF_E2E_ZONE_NAME"
	envRateLimitZoneID = "CF_E2E_RATE_LIMIT_ZONE_ID"
	tofuBinary         = "tofu"
	moduleRoot         = "../.."
)

// e2eConfig holds the account and the dedicated test zone.
type e2eConfig struct {
	accountID string
	zoneID    string
	zoneName  string
}

// requireConfig skips the test unless the dedicated test zone is configured.
func requireConfig(t *testing.T) e2eConfig {
	t.Helper()
	for _, name := range []string{envAPIToken, envAccountID, envZoneID, envZoneName} {
		if os.Getenv(name) == "" {
			t.Skipf("skipping: %s is not set", name)
		}
	}
	return e2eConfig{
		accountID: os.Getenv(envAccountID),
		zoneID:    os.Getenv(envZoneID),
		zoneName:  os.Getenv(envZoneName),
	}
}

// moduleOptions copies the module to a temporary directory and returns
// options for it with a unique Worker name and route. vars override the
// defaults.
func moduleOptions(t *testing.T, cfg e2eConfig, vars map[string]interface{}) *terraform.Options {
	t.Helper()
	id := strings.ToLower(random.UniqueId())
	// The same copy test_structure.CopyTerraformFolderToTemp makes, without
	// the AWS and GCP dependencies that package pulls in.
	dir, err := files.CopyTerraformFolderToTemp(moduleRoot, "e2e-"+id)
	require.NoError(t, err)

	all := map[string]interface{}{
		"cloudflare_account_id": cfg.accountID,
		"cloudflare_zone_id":    cfg.zoneID,
		"script_name":           "e2e-maintenance-" + id,
		"worker_route":          fmt.Sprintf("e2e-%s.%s/*", id, cfg.zoneName),
		"environment":           "e2e",
	}
	for k, v := range vars {
		all[k] = v
	}

	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    dir,
		TerraformBinary: tofuBinary,
		Vars:            all,
		NoColor:         true,
	})
}

// deploy applies the options and registers a destroy that runs even when the
// test fails or panics.
func deploy(t *testing.T, opts *terraform.Options) {
	t.Helper()
	t.Cleanup(func() { terraform.Destroy(t, opts) })
	terraform.InitAndApply(t, opts)
}

func TestMaintenanceModuleBasic(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)
	opts := moduleOptions(t, cfg, map[string]interface{}{
		"enabled":             true,
		"maintenance_title":   "E2E Test Maintenance",
		"maintenance_message": "This is an automated E2E test",
		"contact_email":       "test@example.com",
	})
	deploy(t, opts)

	assert.Equal(t, opts.Vars["script_name"], terraform.Output(t, opts, "worker_script_name"))
	assert.Equal(t, "ENABLED", terraform.Output(t, opts, "maintenance_status"))
	assert.Equal(t, opts.Vars["worker_route"], terraform.Output(t, opts, "worker_route_pattern"))
	assert.Equal(t, "e2e", terraform.Output(t, opts, "environment"))
}

func TestMaintenanceModuleDisabled(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)
	opts := moduleOptions(t, cfg, map[string]interface{}{
		"enabled":           false,
		"maintenance_title": "Disabled Test",
	})
	deploy(t, opts)

	assert.Equal(t, "DISABLED", terraform.Output(t, opts, "maintenance_status"))
	assert.Equal(t, "Maintenance mode disabled", terraform.Output(t, opts, "worker_route_pattern"))
}

func TestMaintenanceModuleWithIPAllowlist(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)
	opts := moduleOptions(t, cfg, map[string]interface{}{
		"enabled":     true,
		"allowed_ips": []string{"192.0.2.1", "198.51.100.0/24", "2001:db8::/32"},
	})
	deploy(t, opts)

	assert.Equal(t, "ENABLED", terraform.Output(t, opts, "maintenance_status"))
}

func TestMaintenanceModuleWithRegionAllowlist(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)
	opts := moduleOptions(t, cfg, map[string]interface{}{
		"enabled":         true,
		"allowed_regions": []string{"US", "CA", "GB"},
	})
	deploy(t, opts)

	assert.ElementsMatch(t, []string{"US", "CA", "GB"}, terraform.OutputList(t, opts, "allowed_regions"))
}

func TestMaintenanceModuleWithMaintenanceWindow(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)
	start := time.Now().Add(1 * time.Hour).UTC().Format(time.RFC3339)
	end := time.Now().Add(3 * time.Hour).UTC().Format(time.RFC3339)
	opts := moduleOptions(t, cfg, map[string]interface{}{
		"maintenance_window": map[string]string{"start_time": start, "end_time": end},
	})
	deploy(t, opts)

	assert.Equal(t, "SCHEDULED", terraform.Output(t, opts, "maintenance_status"))
	window := terraform.OutputMap(t, opts, "maintenance_window")
	assert.Equal(t, start, window["start_time"])
	assert.Equal(t, end, window["end_time"])
}

// TestMaintenanceModuleWithRateLimiting creates and then deletes the zone's
// http_ratelimit entry-point ruleset, which would delete every rate limiting
// rule on the zone. It therefore needs its own throwaway zone and never runs
// against the shared test zone.
func TestMaintenanceModuleWithRateLimiting(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)
	rateLimitZone := os.Getenv(envRateLimitZoneID)
	if rateLimitZone == "" {
		t.Skipf("skipping: %s (a dedicated zone whose rate limiting rules may be deleted) is not set", envRateLimitZoneID)
	}
	// No route, so the test zone's hostname is not needed on that zone.
	opts := moduleOptions(t, cfg, map[string]interface{}{
		"cloudflare_zone_id": rateLimitZone,
		"enabled":            false,
		"rate_limit": map[string]interface{}{
			"enabled":             true,
			"requests_per_period": 100,
			"period":              60,
			"action":              "block",
			"mitigation_timeout":  600,
		},
	})
	deploy(t, opts)

	assert.Equal(t, "true", terraform.Output(t, opts, "rate_limit_enabled"))
	assert.NotEmpty(t, terraform.Output(t, opts, "rate_limit_ruleset_id"))
}

func TestMaintenanceModuleWithCustomStyling(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)
	opts := moduleOptions(t, cfg, map[string]interface{}{
		"enabled":    true,
		"custom_css": "body { background-color: #1a1a2e; color: white; }",
		"logo_url":   "https://example.com/logo.png",
	})
	deploy(t, opts)

	assert.Equal(t, "ENABLED", terraform.Output(t, opts, "maintenance_status"))
}

// TestMaintenanceModuleIdempotency checks that a second plan of the applied
// configuration is empty.
func TestMaintenanceModuleIdempotency(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)
	opts := moduleOptions(t, cfg, map[string]interface{}{"enabled": true})
	deploy(t, opts)

	exitCode := terraform.PlanExitCode(t, opts)
	assert.Equal(t, 0, exitCode, "a plan right after apply should have no changes")
}

func TestMaintenanceModuleEnvironments(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)

	for _, env := range []string{"development", "staging", "production"} {
		t.Run(env, func(t *testing.T) {
			t.Parallel()
			opts := moduleOptions(t, cfg, map[string]interface{}{
				"enabled":     true,
				"environment": env,
			})
			deploy(t, opts)

			assert.Equal(t, env, terraform.Output(t, opts, "environment"))
		})
	}
}

func TestMaintenanceModuleCombinedFeatures(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)
	start := time.Now().Add(1 * time.Hour).UTC().Format(time.RFC3339)
	end := time.Now().Add(3 * time.Hour).UTC().Format(time.RFC3339)
	opts := moduleOptions(t, cfg, map[string]interface{}{
		"enabled":             true,
		"maintenance_title":   "Full Feature Test",
		"maintenance_message": "Testing all features",
		"contact_email":       "test@example.com",
		"allowed_ips":         []string{"192.0.2.1", "198.51.100.0/24"},
		"allowed_regions":     []string{"US", "CA"},
		"custom_css":          "body { background: #000; }",
		"logo_url":            "https://example.com/logo.png",
		"maintenance_window":  map[string]string{"start_time": start, "end_time": end},
	})
	deploy(t, opts)

	assert.Equal(t, "SCHEDULED", terraform.Output(t, opts, "maintenance_status"))
	assert.Len(t, terraform.OutputList(t, opts, "allowed_regions"), 2)
	assert.Equal(t, start, terraform.OutputMap(t, opts, "maintenance_window")["start_time"])
}

// TestMaintenanceModuleValidationErrors plans invalid inputs; validation fails
// before any resource is created.
func TestMaintenanceModuleValidationErrors(t *testing.T) {
	t.Parallel()
	cfg := requireConfig(t)

	cases := map[string]map[string]interface{}{
		"rate limit period too low": {"rate_limit": map[string]interface{}{"enabled": true, "period": 5}},
		"unknown rate limit action": {"rate_limit": map[string]interface{}{"enabled": true, "action": "invalid_action"}},
		"three-letter region code":  {"allowed_regions": []string{"USA"}},
		"invalid script name":       {"script_name": "Not_Valid"},
	}

	for name, vars := range cases {
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			opts := moduleOptions(t, cfg, vars)
			_, err := terraform.InitAndPlanE(t, opts)
			require.Error(t, err)
		})
	}
}
