package test

import (
	"context"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/lambda"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

const region = "eu-west-1"

func TestEventSourceMapping(t *testing.T) {
	td := []struct {
		name  string
		dir   string
		alias bool
	}{
		{name: "sqs", dir: "examples/with-event-source-mappings/sqs", alias: false},
		{name: "dynamodb", dir: "examples/with-event-source-mappings/dynamodb-with-alias", alias: true},
		{name: "kinesis", dir: "examples/with-event-source-mappings/kinesis", alias: false},
	}

	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {
		t.Fatalf("failed to load config: %v", err)
	}
	svc := lambda.NewFromConfig(cfg)

	// Root folder where terraform files should be (relative to the test folder)
	rootFolder := ".."

	for _, tc := range td {
		tc := tc // capture range variable for parallel execution of sub-tests
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				// Copy the example terraform folder to a temp folder
				TerraformDir: test_structure.CopyTerraformFolderToTemp(t, rootFolder, tc.dir),
				NoColor:      true,
			})
			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)

			var fn, arn string
			if tc.alias {
				fn = terraform.Output(t, terraformOptions, "alias_arn")
				arn = terraform.Output(t, terraformOptions, "alias_arn")
			} else {
				fn = terraform.Output(t, terraformOptions, "function_name")
				arn = terraform.Output(t, terraformOptions, "arn")
			}

			resp, err := svc.ListEventSourceMappings(context.TODO(), &lambda.ListEventSourceMappingsInput{
				FunctionName: aws.String(fn),
			})
			if err != nil {
				t.Fatalf("failed to list event source mappings: %v", err)
			}

			assert.Len(t, resp.EventSourceMappings, 2)
			for _, m := range resp.EventSourceMappings {
				t.Log(m)
				assert.Equal(t, arn, *m.FunctionArn)
			}
		})
	}
}
