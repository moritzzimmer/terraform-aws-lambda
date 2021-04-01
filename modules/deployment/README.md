# Lambda function deployments using AWS CodePipeline and AWS CodeDeploy

Terraform module to create AWS resources for blue/green deployments of [Lambda](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) functions
using AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html) and [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps-lambda.html)

<img src="../../docs/deployment/deployment.png" />

## Features

- fully automated AWS CodePipelines triggered by ECR pushes of containerized Lambda functions
- creation of IAM roles with permissions following the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege) for CodePipeline, CodeBuild and CodeDeploy
  or bring your own roles
- optional CodeStar notifications via SNS

(currently) not supported:

- S3 based deployments of Lambda functions
- `BeforeAllowTraffic` and `AfterAllowTraffic` hooks in CodeDeploy
- external configuration of CodeBuild infrastructure like `compute_type` or `image`

## How do I use this module?

Make sure the specified `image_uri` exists in the `aws_ecr_repository` for the initial terraform run. This can be achieved for example by:

- targeting only `aws_ecr_repository` in the first run and push and initial image before applying the rest of the infrastructure
- using [docker_registry_image](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/registry_image) to build the image as part of the terraform lifecycle
- using a `null_resource` with a `local-exec` provisioner to build and push the image as part of the terraform lifecycle

It's recommended to build and push all further container images using a CI system like GitHub actions.

```hcl
locals {
  environment   = "production"
  function_name = "example-with-code-pipeline"
}

resource "aws_lambda_alias" "this" {
  function_name    = module.lambda.function_name
  function_version = module.lambda.version
  name             = local.environment

  lifecycle {
    ignore_changes = [function_version]
  }
}

resource "aws_ecr_repository" "this" {
  name = local.function_name
}

module "deployment" {
  source = "moritzzimmer/lambda/aws//modules/deployment"

  alias_name          = aws_lambda_alias.this.name
  ecr_image_tag       = local.environment
  ecr_repository_name = aws_ecr_repository.this.name
  function_name       = local.function_name
}

module "lambda" {
  source        = "moritzzimmer/lambda/aws"

  function_name                    = local.function_name
  ignore_external_function_updates = true
  image_uri                        = "${aws_ecr_repository.this.repository_url}:${local.environment}"
  package_type                     = "Image"
  publish                          = true
}
```

### Examples

- [deployment](../../examples/deployment)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.0 |
| aws | >= 3.19 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.19 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| s3_bucket | terraform-aws-modules/s3-bucket/aws |  |

## Resources

| Name |
|------|
| [aws_caller_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) |
| [aws_cloudwatch_event_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) |
| [aws_cloudwatch_event_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) |
| [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) |
| [aws_codebuild_project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) |
| [aws_codedeploy_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app) |
| [aws_codedeploy_deployment_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group) |
| [aws_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) |
| [aws_codestarnotifications_notification_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarnotifications_notification_rule) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| [aws_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) |
| [aws_sns_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) |
| [aws_sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alias\_name | Name of the Lambda alias used in CodeDeploy. | `string` | n/a | yes |
| cloudwatch\_logs\_retention\_in\_days | Specifies the number of days you want to retain log events in the specified log group. | `number` | `14` | no |
| codebuild\_role\_arn | ARN of an existing IAM role for CodeBuild execution. If empty, a dedicated role for your Lambda function with minimal required permissions will be created. | `string` | `""` | no |
| codepipeline\_role\_arn | ARN of an existing IAM role for CodePipeline execution. If empty, a dedicated role for your Lambda function with minimal required permissions will be created. | `string` | `""` | no |
| codestar\_notifications\_detail\_type | The level of detail to include in the notifications for this resource. Possible values are BASIC and FULL. | `string` | `"BASIC"` | no |
| codestar\_notifications\_enabled | Enable CodeStar notifications for your pipeline. | `bool` | `true` | no |
| codestar\_notifications\_event\_type\_ids | A list of event types associated with this notification rule. For list of allowed events see https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#concepts-api. | `list(string)` | <pre>[<br>  "codepipeline-pipeline-pipeline-execution-succeeded",<br>  "codepipeline-pipeline-pipeline-execution-failed"<br>]</pre> | no |
| codestar\_notifications\_target\_arn | Use an existing ARN for a notification rule target (for example, a SNS Topic ARN). Otherwise a separate sns topic for this service will be created. | `string` | `""` | no |
| deployment\_config\_name | The name of the deployment config used in the CodeDeploy deployment group. | `string` | `"CodeDeployDefault.LambdaAllAtOnce"` | no |
| ecr\_image\_tag | The tag used for the Lambda container image. | `string` | `"latest"` | no |
| ecr\_repository\_name | Name of the ECR repository source used for deployments. | `string` | n/a | yes |
| function\_name | The name of your Lambda Function to deploy. | `string` | n/a | yes |
| tags | A mapping of tags to assign to all resources supporting tags. | `map(string)` | `{}` | no |

## Outputs

No output.
