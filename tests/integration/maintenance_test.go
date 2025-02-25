package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestMaintenancePageDeployment(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/basic-usage",
    }
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
}
