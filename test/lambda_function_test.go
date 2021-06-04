package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func TestLambdaFunction(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Copy the example terraform folder to a temp folder
		TerraformDir: test_structure.CopyTerraformFolderToTemp(t, "..", "examples/simple"),
		NoColor:      true,
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	role := terraform.Output(t, terraformOptions, "role_name")
	assert.Equal(t, "example-without-event-eu-west-1", role)

	fct := terraform.Output(t, terraformOptions, "function_name")
	assert.Equal(t, "example-without-event", fct)
}

func TestCloudWatchLogGroup(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Copy the example terraform folder to a temp folder
		TerraformDir: test_structure.CopyTerraformFolderToTemp(t, "..", "examples/simple"),
		NoColor:      true,
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	lg := terraform.Output(t, terraformOptions, "cloudwatch_log_group_name")
	assert.Equal(t, "/aws/lambda/example-without-event", lg)
}
