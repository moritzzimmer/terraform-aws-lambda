# Lambda function deployments using AWS CodePipeline and AWS CodeDeploy

Terraform module to create AWS resources for blue/green deployments of [Lambda](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) functions
using AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html) and [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps-lambda.html).

Basic principle for this module is to separate the infrastructure/configuration aspect of Lambda functions (e.g. IAM role, timeouts, runtime, CloudWatch logs)
from continuous deployments of the actual function code.

The latter should be build, tested and packaged (`Zip` or `Image`) on CI systems like GitHub actions and uploaded to AWS (ECR or S3). Controlled,
blue/green deployments of the function code with (automatic) rollbacks and traffic shifting will then be executed on AWS CodePipline using CodeDeploy.

<img src="../../docs/deployment/deployment.png" />

## Features

- fully automated AWS CodePipelines as code to deploy containerized Lambda functions from ECR or zipped packages from S3
- creation of IAM roles with permissions following the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege) for CodePipeline, CodeBuild and CodeDeploy
  or bring your own roles
- optional CodeStar notifications via SNS

(currently) not supported:

- `BeforeAllowTraffic` and `AfterAllowTraffic` hooks in CodeDeploy

## How do I use this module?

### Initial Terraform run

The Terraform [lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) relies
on existing `image_uri` (for containerized functions) or `s3_object_version` (for S3 based packages) in the initial run.

For containerized functions this can be achieved by:

- targeting only `aws_ecr_repository` in the first run and push and initial image before applying the rest of the infrastructure
- using [docker_registry_image](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/registry_image) to build the image as part of the terraform lifecycle
- using a `null_resource` with a `local-exec` provisioner to build and push the image as part of the terraform lifecycle, see [container-image (ECR)](../../examples/deployment/container-image)
for a full example

For `Zip` packages on S3 this can be achieved using an `aws_s3_bucket_object` ignoring changes to `etag` and `version_id`, see
[zipped package (S3)](../../examples/deployment/s3) for a full example.

It's recommended to build, test, package and upload all further function code changes using a CI system like GitHub actions.

### using container images

```hcl
locals {
  environment   = "production"
  function_name = "example-with-ecr-codepipeline"
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

### using S3 packages

```hcl
locals {
  environment   = "production"
  function_name = "example-with-s3-codepipeline"
  s3_key        = "package/lambda.zip"
}

resource "aws_lambda_alias" "this" {
  function_name    = module.lambda.function_name
  function_version = module.lambda.version
  name             = local.environment

  lifecycle {
    ignore_changes = [function_version]
  }
}

module "deployment" {
  source = "moritzzimmer/lambda/aws//modules/deployment"

  alias_name    = aws_lambda_alias.this.name
  function_name = local.function_name
  s3_bucket     = aws_s3_bucket_object.source.bucket
  s3_key        = local.s3_key
}

module "lambda" {
  source        = "moritzzimmer/lambda/aws"

  function_name                    = local.function_name
  handler                          = "index.handler"
  ignore_external_function_updates = true
  publish                          = true
  runtime                          = "nodejs14.x"
  s3_bucket                        = aws_s3_bucket_object.source.bucket
  s3_key                           = local.s3_key
  s3_object_version                = aws_s3_bucket_object.source.version_id
}

resource "aws_s3_bucket" "source" {
  acl           = "private"
  bucket        = "source-bucket"
  force_destroy = true

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "source" {
  bucket = aws_s3_bucket.source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// this resource is only used for the initial `terraform apply` - all further
// deployments are running on CodePipeline
resource "aws_s3_bucket_object" "source" {
  bucket = aws_s3_bucket.source.bucket
  key    = local.s3_key
  source = module.function.output_path
  etag   = module.function.output_md5

  lifecycle {
    ignore_changes = [etag, version_id]
  }
}
```

### Examples

- [container-image (ECR)](../../examples/deployment/container-image)
- [zipped package (S3)](../../examples/deployment/s3)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.19 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.67.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_event_rule.s3_trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.s3_trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_codebuild_project.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codedeploy_app.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app) | resource |
| [aws_codedeploy_deployment_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group) | resource |
| [aws_codepipeline.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_codestarnotifications_notification_rule.notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarnotifications_notification_rule) | resource |
| [aws_iam_role.codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codedeploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codepipeline_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.codedeploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_sns_topic.notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_codestar_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alias_name"></a> [alias\_name](#input\_alias\_name) | Name of the Lambda alias used in CodeDeploy. | `string` | n/a | yes |
| <a name="input_codebuild_cloudwatch_logs_retention_in_days"></a> [codebuild\_cloudwatch\_logs\_retention\_in\_days](#input\_codebuild\_cloudwatch\_logs\_retention\_in\_days) | Specifies the number of days you want to retain log events in the CodeBuild log group. | `number` | `14` | no |
| <a name="input_codebuild_environment_compute_type"></a> [codebuild\_environment\_compute\_type](#input\_codebuild\_environment\_compute\_type) | Information about the compute resources the build project will use. | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| <a name="input_codebuild_environment_image"></a> [codebuild\_environment\_image](#input\_codebuild\_environment\_image) | Docker image to use for this build project. | `string` | `"aws/codebuild/amazonlinux2-x86_64-standard:3.0"` | no |
| <a name="input_codebuild_environment_type"></a> [codebuild\_environment\_type](#input\_codebuild\_environment\_type) | Type of build environment to use for related builds. | `string` | `"LINUX_CONTAINER"` | no |
| <a name="input_codebuild_role_arn"></a> [codebuild\_role\_arn](#input\_codebuild\_role\_arn) | ARN of an existing IAM role for CodeBuild execution. If empty, a dedicated role for your Lambda function with minimal required permissions will be created. | `string` | `""` | no |
| <a name="input_codepipeline_artifact_store_bucket"></a> [codepipeline\_artifact\_store\_bucket](#input\_codepipeline\_artifact\_store\_bucket) | Name of an existing S3 bucket used by AWS CodePipeline to store pipeline artifacts. Use the same bucket name as in `s3_bucket` to store deployment packages and pipeline artifacts in one bucket for `package_type=Zip` functions. If empty, a dedicated S3 bucket for your Lambda function will be created. | `string` | `""` | no |
| <a name="input_codepipeline_role_arn"></a> [codepipeline\_role\_arn](#input\_codepipeline\_role\_arn) | ARN of an existing IAM role for CodePipeline execution. If empty, a dedicated role for your Lambda function with minimal required permissions will be created. | `string` | `""` | no |
| <a name="input_codestar_notifications_detail_type"></a> [codestar\_notifications\_detail\_type](#input\_codestar\_notifications\_detail\_type) | The level of detail to include in the notifications for this resource. Possible values are BASIC and FULL. | `string` | `"BASIC"` | no |
| <a name="input_codestar_notifications_enabled"></a> [codestar\_notifications\_enabled](#input\_codestar\_notifications\_enabled) | Enable CodeStar notifications for your pipeline. | `bool` | `true` | no |
| <a name="input_codestar_notifications_event_type_ids"></a> [codestar\_notifications\_event\_type\_ids](#input\_codestar\_notifications\_event\_type\_ids) | A list of event types associated with this notification rule. For list of allowed events see https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#concepts-api. | `list(string)` | <pre>[<br>  "codepipeline-pipeline-pipeline-execution-succeeded",<br>  "codepipeline-pipeline-pipeline-execution-failed"<br>]</pre> | no |
| <a name="input_codestar_notifications_target_arn"></a> [codestar\_notifications\_target\_arn](#input\_codestar\_notifications\_target\_arn) | Use an existing ARN for a notification rule target (for example, a SNS Topic ARN). Otherwise a separate sns topic for this service will be created. | `string` | `""` | no |
| <a name="input_create_codepipeline_cloudtrail"></a> [create\_codepipeline\_cloudtrail](#input\_create\_codepipeline\_cloudtrail) | Create a CloudTrail to detect S3 package uploads. Since AWS has a hard limit of 5 trails/region, it's recommended to create one central trail for all S3 packaged Lambda functions external to this module. | `bool` | `false` | no |
| <a name="input_deployment_config_name"></a> [deployment\_config\_name](#input\_deployment\_config\_name) | The name of the deployment config used in the CodeDeploy deployment group. | `string` | `"CodeDeployDefault.LambdaAllAtOnce"` | no |
| <a name="input_ecr_image_tag"></a> [ecr\_image\_tag](#input\_ecr\_image\_tag) | The container tag used for ECR/container based deployments. | `string` | `"latest"` | no |
| <a name="input_ecr_repository_name"></a> [ecr\_repository\_name](#input\_ecr\_repository\_name) | Name of the ECR repository source used for ECR/container based deployments, required for `package_type=Image`. | `string` | `""` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | The name of your Lambda Function to deploy. | `string` | n/a | yes |
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | Name of the bucket used for S3 based deployments, required for `package_type=Zip`. | `string` | `""` | no |
| <a name="input_s3_key"></a> [s3\_key](#input\_s3\_key) | Object key used for S3 based deployments, required for `package_type=Zip`. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources supporting tags. | `map(string)` | `{}` | no |

## Outputs

No outputs.
