package test

import (
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

const region = "eu-west-1"

func TestEventSourceMapping(t *testing.T) {
	td := []struct {
		name         string
		dir          string
		expBatchSize int64
	}{
		{name: "sqs", dir: "../examples/with-event-source-mappings/sqs", expBatchSize: 5},
		{name: "dynamodb", dir: "../examples/with-event-source-mappings/dynamodb", expBatchSize: 50},
	}

	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	svc := lambda.New(sess, &aws.Config{Region: aws.String(region)})

	for _, tc := range td {
		tc := tc // capture range variable for parallel execution of sub-tests
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: tc.dir,
				NoColor:      true,
			})
			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)

			fn := terraform.Output(t, terraformOptions, "function_name")
			arn := terraform.Output(t, terraformOptions, "arn")

			resp, err := svc.ListEventSourceMappings(&lambda.ListEventSourceMappingsInput{
				FunctionName: aws.String(fn),
			})
			if err != nil {
				t.Fatalf("failed to list event source mappings: %v", err)
			}

			assert.Len(t, resp.EventSourceMappings, 1)

			e := resp.EventSourceMappings[0]
			t.Log(e)
			assert.Equal(t, tc.expBatchSize, *e.BatchSize)
			assert.Equal(t, arn, *e.FunctionArn)
		})
	}
}
