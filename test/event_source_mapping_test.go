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

var svc *lambda.Lambda

func init() {
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	svc = lambda.New(sess, &aws.Config{Region: aws.String(region)})
}

func TestSqsEventSourceMappings(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/example-with-event-source-mapping",
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

	for _, e := range resp.EventSourceMappings {
		t.Log(e)
		assert.Equal(t, int64(5), *e.BatchSize)
		assert.Equal(t, arn, *e.FunctionArn)
	}
}
