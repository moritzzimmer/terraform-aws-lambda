package test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/iam"
	"github.com/aws/aws-sdk-go-v2/service/lambda"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

const region = "eu-west-1"

type Policy struct {
	// 2012-10-17 or 2008-10-17 old policies, do NOT use this for new policies
	Version    string      `json:"Version"`
	Id         string      `json:"Id,omitempty"`
	Statements []Statement `json:"Statement"`
}

type Statement struct {
	Sid          string           `json:"Sid,omitempty"`          // statement ID, service specific
	Effect       string           `json:"Effect"`                 // Allow or Deny
	Principal    map[string]Value `json:"Principal,omitempty"`    // principal that is allowed or denied
	NotPrincipal map[string]Value `json:"NotPrincipal,omitempty"` // exception to a list of principals
	Action       Value            `json:"Action"`                 // allowed or denied action
	NotAction    Value            `json:"NotAction,omitempty"`    // matches everything except
	Resource     Value            `json:"Resource,omitempty"`     // object or objects that the statement covers
	NotResource  Value            `json:"NotResource,omitempty"`  // matches everything except
	Condition    json.RawMessage  `json:"Condition,omitempty"`    // conditions for when a policy is in effect
}

// AWS allows string or []string as value, we convert everything to []string to avoid casting
type Value []string

func (value *Value) UnmarshalJSON(b []byte) error {

	var raw interface{}
	err := json.Unmarshal(b, &raw)
	if err != nil {
		return err
	}

	var p []string
	//  value can be string or []string, convert everything to []string
	switch v := raw.(type) {
	case string:
		p = []string{v}
	case []interface{}:
		var items []string
		for _, item := range v {
			items = append(items, fmt.Sprintf("%v", item))
		}
		p = items
	default:
		return fmt.Errorf("invalid %s value element: allowed is only string or []string", value)
	}

	*value = p
	return nil
}

func TestPolicyAttachments(t *testing.T) {
	td := []struct {
		name    string
		dir     string
		actions []string
	}{
		{name: "sqs", dir: "examples/with-event-source-mappings/sqs", actions: []string{"sqs:ReceiveMessage", "sqs:GetQueueAttributes", "sqs:DeleteMessageBatch", "sqs:DeleteMessage", "sqs:ChangeMessageVisibilityBatch", "sqs:ChangeMessageVisibility"}},
		{name: "dynamodb", dir: "examples/with-event-source-mappings/dynamodb-with-alias", actions: []string{"dynamodb:ListStreams", "dynamodb:GetShardIterator", "dynamodb:GetRecords", "dynamodb:DescribeStream"}},
	}

	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {
		t.Fatalf("failed to load config: %v", err)
	}
	svc := iam.NewFromConfig(cfg)

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

			policy := getPolicy(t, svc, terraformOptions)

			for _, s := range policy.Statements {
				assert.Equal(t, "Allow", s.Effect)

				// verify Resource ARNs
				es := terraform.OutputList(t, terraformOptions, "event_source_arns")
				assert.Len(t, s.Resource, 2)
				for _, r := range s.Resource {
					assert.Contains(t, es, r)
				}

				// verify mandatory actions
				assert.Len(t, s.Action, len(tc.actions))
				for _, a := range s.Action {
					assert.Contains(t, tc.actions, a)
				}
			}
		})
	}
}

func getPolicy(t *testing.T, svc *iam.Client, options *terraform.Options) Policy {
	rn := terraform.Output(t, options, "role_name")
	policies, err := svc.ListAttachedRolePolicies(context.TODO(), &iam.ListAttachedRolePoliciesInput{
		RoleName: aws.String(rn),
	})
	if err != nil {
		t.Fatalf("failed to list role policies: %v", err)
	}
	assert.Len(t, policies.AttachedPolicies, 2)

	// custom policy attachment for event source should always be after 'AWSLambdaBasicExecutionRole '
	v, err := svc.GetPolicyVersion(context.TODO(), &iam.GetPolicyVersionInput{
		PolicyArn: policies.AttachedPolicies[1].PolicyArn,
		VersionId: aws.String("v1"),
	})

	if err != nil {
		t.Fatalf("failed to get policy version: %v", err)
	}

	decoded, err := url.QueryUnescape(*v.PolicyVersion.Document)
	if err != nil {
		t.Fatalf("failed to unescape policy document: %v", err)
	}

	var policy Policy
	err = json.Unmarshal([]byte(decoded), &policy)
	if err != nil {
		t.Fatalf("failed to unmarshall policy document: %v", err)
	}
	t.Logf("%+v\n", decoded)
	return policy
}

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
