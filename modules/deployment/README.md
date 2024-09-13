# Lambda function deployments using AWS CodePipeline and AWS CodeDeploy

Terraform module to create AWS resources for secure blue/green deployments
of [Lambda](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) functions using AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html), [CodeBuild](https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html) and [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps-lambda.html).

Basic principle for this module is to separate the infrastructure/configuration aspect of Lambda functions (e.g. IAM
role, timeouts, runtime, CloudWatch logs) from continuous deployments of the actual function code.

The latter should be build, tested and packaged on CI systems like GitHub actions and uploaded to
S3 (`package_type=Zip`) or pushed to ECR (`package_type=Image`).
Controlled and secure blue/green deployments of the function code with (automatic) rollbacks and traffic shifting will
then be executed in an AWS CodePipline using CodeBuild
to update the function code and CodeDeploy to deploy the new function version.

<img src="../../docs/deployment/deployment.drawio.svg" />

## Features

- fully automated AWS CodePipelines with CodeBuild and CodeDeploy stages to deploy containerized Lambda functions from
  ECR or zipped packages from S3
- creation of IAM roles with permissions following the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege) for CodePipeline,
  CodeBuild and CodeDeploy or bring your own roles
- SNS topic for [AWS CodeStar Notifications](https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome.html) of CodePipeline events, or bring your own SNS topic
- `BeforeAllowTraffic` and `AfterAllowTraffic` [hooks](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-lambda) for CodeDeploy
- AWS predefined and custom [deployment configurations](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html) for CodeDeploy
- automatic [rollbacks](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployments-rollback-and-redeploy.html#deployments-rollback-and-redeploy-automatic-rollbacks) and support of [CloudWatch alarms](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-groups-configure-advanced-options.html) to stop deployments
- additional custom CodePipeline steps executed after the deployment

## How do I use this module?

### Initial Terraform run

The Terraform [lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) relies on existing `image_uri` (for containerized functions) or `s3_object_version` (for S3 based packages) in the initial run.

For containerized functions this can be achieved one of the following options:

- targeting only `aws_ecr_repository` in the first run and push and initial image before applying the rest of the
  infrastructure
- using [docker_registry_image](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/registry_image) to build the image as part of the terraform lifecycle
- using a `null_resource` with a `local-exec` provisioner to build and push the image as part of the terraform
  lifecycle, see [container-image (ECR)](../../examples/deployment/container-image) for a full example

For `Zip` packages on S3 this can be achieved using an `aws_s3_object` ignoring changes to `etag`, see
[zipped package (S3)](../../examples/deployment/s3) for a full example.

It's then recommended to build, test, package and upload all further function code changes using a CI system like GitHub
actions.

### using container images

see [ECR example](../../examples/deployment/container-image) for details:

```terraform
locals {
  environment   = "production"
  function_name = "with-ecr-codepipeline"
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
  source = "moritzzimmer/lambda/aws"

  function_name                    = local.function_name
  ignore_external_function_updates = true
  image_uri                        = "${aws_ecr_repository.this.repository_url}:${local.environment}"
  package_type                     = "Image"
  publish                          = true
}
```

### using S3 packages

see [S3 example](../../examples/deployment/s3) for details:

```terraform
locals {
  environment   = "production"
  function_name = "with-s3-codepipeline"
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
  s3_bucket     = aws_s3_object.source.bucket
  s3_key        = local.s3_key
}

module "lambda" {
  source = "moritzzimmer/lambda/aws"

  function_name                    = local.function_name
  handler                          = "index.handler"
  ignore_external_function_updates = true
  publish                          = true
  runtime                          = "nodejs20.x"
  s3_bucket                        = aws_s3_object.source.bucket
  s3_key                           = local.s3_key
  s3_object_version                = aws_s3_object.source.version_id
}

resource "aws_s3_bucket" "source" {
  bucket        = "source-bucket"
  force_destroy = true
}

// make sure to enable S3 bucket notifications to start CodePipeline
resource "aws_s3_bucket_notification" "source" {
  bucket      = aws_s3_bucket.source.id
  eventbridge = true
}

// versioning is required for CodePipeline
resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id

  versioning_configuration {
    status = "Enabled"
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
resource "aws_s3_object" "source" {
  bucket = aws_s3_bucket.source.bucket
  key    = local.s3_key
  source = module.function.output_path
  etag   = module.function.output_md5

  lifecycle {
    ignore_changes = [etag]
  }
}
```

The [Amazon S3 source action](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-S3.html)
of the CodePipeline needs an AWS S3 Notification for emitting events in your Amazon S3 source bucket and sending
filtered events to EventBridge and trigger the pipeline (see [docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventBridge.html) for details). Make sure to enable S3 bucket
notifications for your source bucket!

### with custom deployment configuration

This module supports all predefined [default deployment configurations](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html)
for the AWS Lambda compute platform as well as custom defined configs,
see [complete example](../../examples/deployment/complete) for details:

```terraform
// see above

module "deployment" {
  source = "moritzzimmer/lambda/aws//modules/deployment"

  alias_name             = aws_lambda_alias.this.name
  function_name          = local.function_name
  s3_bucket              = aws_s3_bucket.source.bucket
  s3_key                 = local.s3_key

  // optionally use custom deployment configuration or a different default deployment configuration like `CodeDeployDefault.LambdaLinear10PercentEvery1Minute` from https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html
  deployment_config_name = aws_codedeploy_deployment_config.custom.id
}

resource "aws_codedeploy_deployment_config" "custom" {
  deployment_config_name = "custom-lambda-deployment-config"
  compute_platform       = "Lambda"

  traffic_routing_config {
    type = "TimeBasedLinear"

    time_based_linear {
      interval   = 1
      percentage = 20
    }
  }
}
```

### with before and after allow traffic hooks

see [complete example](../../examples/deployment/complete) for details:

```terraform
// see above

module "deployment" {
  source = "moritzzimmer/lambda/aws//modules/deployment"

  alias_name                                        = aws_lambda_alias.this.name
  codedeploy_appspec_hooks_after_allow_traffic_arn  = module.traffic_hook.arn
  codedeploy_appspec_hooks_before_allow_traffic_arn = module.traffic_hook.arn
  codepipeline_artifact_store_bucket                = aws_s3_bucket.source.bucket
  function_name                                     = local.function_name
  s3_bucket                                         = aws_s3_bucket.source.bucket
  s3_key                                            = local.s3_key
}

module "traffic_hook" {
  source = "moritzzimmer/lambda/aws"

  architectures    = ["arm64"]
  description      = "Lambda function executed by CodeDeploy before and/or after allow traffic to deployed version."
  filename         = data.archive_file.traffic_hook.output_path
  function_name    = "codedeploy-hook-example"
  handler          = "hook.handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.traffic_hook.output_base64sha256
}

data "aws_iam_policy_document" "traffic_hook" {
  statement {
    actions   = ["codedeploy:PutLifecycleEventHookExecutionStatus"]
    resources = [module.deployment.codedeploy_deployment_group_arn]
  }
}

resource "aws_iam_policy" "traffic_hook" {
  name   = "codedeploy-hook-policy"
  policy = data.aws_iam_policy_document.traffic_hook.json
}

resource "aws_iam_role_policy_attachment" "traffic_hook" {
  role       = module.traffic_hook.role_name
  policy_arn = aws_iam_policy.traffic_hook.arn
}
```

### with rollbacks based on CloudWatch alarms

see [complete example](../../examples/deployment/complete) for details:

```terraform
// see above

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_description   = "${module.lambda.function_name} has a high error rate"
  alarm_name          = "${module.lambda.function_name}-error-rate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 1
  evaluation_periods  = 1
  threshold           = 5
  treat_missing_data  = "notBreaching"

  // calculate error rate here
}

module "deployment" {
  source = "moritzzimmer/lambda/aws//modules/deployment"

  alias_name                                                      = aws_lambda_alias.this.name
  codedeploy_deployment_group_alarm_configuration_enabled         = true
  codedeploy_deployment_group_alarm_configuration_alarms          = [aws_cloudwatch_metric_alarm.error_rate.id]
  codedeploy_deployment_group_auto_rollback_configuration_enabled = true
  codedeploy_deployment_group_auto_rollback_configuration_events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  codepipeline_artifact_store_bucket                              = aws_s3_bucket.source.bucket
  deployment_config_name                                          = aws_codedeploy_deployment_config.canary.id
  function_name                                                   = local.function_name
  s3_bucket                                                       = aws_s3_bucket.source.bucket
  s3_key                                                          = local.s3_key
}

resource "aws_codedeploy_deployment_config" "canary" {
  deployment_config_name = "custom-lambda-canary-deployment-config"
  compute_platform       = "Lambda"

  traffic_routing_config {
    type = "TimeBasedCanary"

    time_based_canary {
      interval   = 5
      percentage = 50
    }
  }
}
```

### with custom CodePipeline steps

see [complete example](../../examples/deployment/complete) for details:

```terraform
// see above and make sure to add required IAM permissions

module "deployment" {
  source = "moritzzimmer/lambda/aws//modules/deployment"

  // see above
  codepipeline_post_deployment_stages = [
    {
      name = "Custom"

      actions = [
        {
          name            = "CustomCodeBuildStep"
          category        = "Build"
          owner           = "AWS"
          provider        = "CodeBuild"
          version         = "1"
          input_artifacts = ["deploy"]

          configuration = {
            ProjectName : aws_codebuild_project.custom_step.name
          }
        }
      ]
    }
  ]
}
```
### Examples

- [complete](../../examples/deployment/complete)
- [container-image (ECR)](../../examples/deployment/container-image)
- [zipped package (S3)](../../examples/deployment/s3)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.32 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.32 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
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
| [aws_s3_bucket_public_access_block.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_sns_topic.notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.sns_codestar_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alias_name"></a> [alias\_name](#input\_alias\_name) | Name of the Lambda alias used in CodeDeploy. | `string` | n/a | yes |
| <a name="input_codebuild_cloudwatch_logs_retention_in_days"></a> [codebuild\_cloudwatch\_logs\_retention\_in\_days](#input\_codebuild\_cloudwatch\_logs\_retention\_in\_days) | Specifies the number of days you want to retain log events in the CodeBuild log group. | `number` | `14` | no |
| <a name="input_codebuild_environment_compute_type"></a> [codebuild\_environment\_compute\_type](#input\_codebuild\_environment\_compute\_type) | Information about the compute resources the build project will use. | `string` | `"BUILD_LAMBDA_1GB"` | no |
| <a name="input_codebuild_environment_image"></a> [codebuild\_environment\_image](#input\_codebuild\_environment\_image) | Docker image to use for this build project. The image needs to include python. | `string` | `"aws/codebuild/amazonlinux-aarch64-lambda-standard:python3.12"` | no |
| <a name="input_codebuild_environment_type"></a> [codebuild\_environment\_type](#input\_codebuild\_environment\_type) | Type of build environment to use for related builds. | `string` | `"ARM_LAMBDA_CONTAINER"` | no |
| <a name="input_codebuild_role_arn"></a> [codebuild\_role\_arn](#input\_codebuild\_role\_arn) | ARN of an existing IAM role for CodeBuild execution. If empty, a dedicated role for your Lambda function with minimal required permissions will be created. | `string` | `""` | no |
| <a name="input_codedeploy_appspec_hooks_after_allow_traffic_arn"></a> [codedeploy\_appspec\_hooks\_after\_allow\_traffic\_arn](#input\_codedeploy\_appspec\_hooks\_after\_allow\_traffic\_arn) | Lambda function ARN to run after traffic is shifted to the deployed Lambda function version. | `string` | `""` | no |
| <a name="input_codedeploy_appspec_hooks_before_allow_traffic_arn"></a> [codedeploy\_appspec\_hooks\_before\_allow\_traffic\_arn](#input\_codedeploy\_appspec\_hooks\_before\_allow\_traffic\_arn) | Lambda function ARN to run before traffic is shifted to the deployed Lambda function version. | `string` | `""` | no |
| <a name="input_codedeploy_deployment_group_alarm_configuration_alarms"></a> [codedeploy\_deployment\_group\_alarm\_configuration\_alarms](#input\_codedeploy\_deployment\_group\_alarm\_configuration\_alarms) | A list of alarms configured for the deployment group. A maximum of 10 alarms can be added to a deployment group. | `list(string)` | `[]` | no |
| <a name="input_codedeploy_deployment_group_alarm_configuration_enabled"></a> [codedeploy\_deployment\_group\_alarm\_configuration\_enabled](#input\_codedeploy\_deployment\_group\_alarm\_configuration\_enabled) | Indicates whether the alarm configuration is enabled. This option is useful when you want to temporarily deactivate alarm monitoring for a deployment group without having to add the same alarms again later. | `bool` | `false` | no |
| <a name="input_codedeploy_deployment_group_alarm_configuration_ignore_poll_alarm_failure"></a> [codedeploy\_deployment\_group\_alarm\_configuration\_ignore\_poll\_alarm\_failure](#input\_codedeploy\_deployment\_group\_alarm\_configuration\_ignore\_poll\_alarm\_failure) | Indicates whether a deployment should continue if information about the current state of alarms cannot be retrieved from CloudWatch. | `bool` | `false` | no |
| <a name="input_codedeploy_deployment_group_auto_rollback_configuration_enabled"></a> [codedeploy\_deployment\_group\_auto\_rollback\_configuration\_enabled](#input\_codedeploy\_deployment\_group\_auto\_rollback\_configuration\_enabled) | Indicates whether a defined automatic rollback configuration is currently enabled for this deployment group. If you enable automatic rollback, you must specify at least one event type. | `bool` | `false` | no |
| <a name="input_codedeploy_deployment_group_auto_rollback_configuration_events"></a> [codedeploy\_deployment\_group\_auto\_rollback\_configuration\_events](#input\_codedeploy\_deployment\_group\_auto\_rollback\_configuration\_events) | The event type or types that trigger a rollback. Supported types are `DEPLOYMENT_FAILURE` and `DEPLOYMENT_STOP_ON_ALARM` | `list(string)` | `[]` | no |
| <a name="input_codepipeline_artifact_store_bucket"></a> [codepipeline\_artifact\_store\_bucket](#input\_codepipeline\_artifact\_store\_bucket) | Name of an existing S3 bucket used by AWS CodePipeline to store pipeline artifacts. Use the same bucket name as in `s3_bucket` to store deployment packages and pipeline artifacts in one bucket for `package_type=Zip` functions. If empty, a dedicated S3 bucket for your Lambda function will be created. | `string` | `""` | no |
| <a name="input_codepipeline_artifact_store_encryption_key_id"></a> [codepipeline\_artifact\_store\_encryption\_key\_id](#input\_codepipeline\_artifact\_store\_encryption\_key\_id) | The KMS key ARN or ID of a key block AWS CodePipeline uses to encrypt the data in the artifact store, such as an AWS Key Management Service (AWS KMS) key. If you don't specify a key, AWS CodePipeline uses the default key for Amazon Simple Storage Service (Amazon S3). | `string` | `""` | no |
| <a name="input_codepipeline_post_deployment_stages"></a> [codepipeline\_post\_deployment\_stages](#input\_codepipeline\_post\_deployment\_stages) | A map of post deployment stages to execute after the Lambda function has been deployed. The following stages are supported: `CodeBuild`, `CodeDeploy`, `CodePipeline`, `CodeStarNotifications`. | <pre>list(object({<br>    name = string<br>    actions = list(object({<br>      name             = string<br>      category         = string<br>      owner            = string<br>      provider         = string<br>      version          = string<br>      input_artifacts  = optional(list(any))<br>      output_artifacts = optional(list(any))<br>      configuration    = optional(map(string))<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_codepipeline_role_arn"></a> [codepipeline\_role\_arn](#input\_codepipeline\_role\_arn) | ARN of an existing IAM role for CodePipeline execution. If empty, a dedicated role for your Lambda function with minimal required permissions will be created. | `string` | `""` | no |
| <a name="input_codepipeline_type"></a> [codepipeline\_type](#input\_codepipeline\_type) | Type of the CodePipeline. Possible values are: `V1` and `V2`. | `string` | `"V1"` | no |
| <a name="input_codepipeline_variables"></a> [codepipeline\_variables](#input\_codepipeline\_variables) | CodePipeline variables. Valid only when `codepipeline_type` is `V2`. | <pre>list(object({<br>    name          = string<br>    default_value = optional(string)<br>    description   = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_codestar_notifications_detail_type"></a> [codestar\_notifications\_detail\_type](#input\_codestar\_notifications\_detail\_type) | The level of detail to include in the notifications for this resource. Possible values are BASIC and FULL. | `string` | `"BASIC"` | no |
| <a name="input_codestar_notifications_enabled"></a> [codestar\_notifications\_enabled](#input\_codestar\_notifications\_enabled) | Enable CodeStar notifications for your pipeline. | `bool` | `true` | no |
| <a name="input_codestar_notifications_event_type_ids"></a> [codestar\_notifications\_event\_type\_ids](#input\_codestar\_notifications\_event\_type\_ids) | A list of event types associated with this notification rule. For list of allowed events see https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#events-ref-pipeline. | `list(string)` | <pre>[<br>  "codepipeline-pipeline-pipeline-execution-succeeded",<br>  "codepipeline-pipeline-pipeline-execution-failed"<br>]</pre> | no |
| <a name="input_codestar_notifications_target_arn"></a> [codestar\_notifications\_target\_arn](#input\_codestar\_notifications\_target\_arn) | Use an existing ARN for a notification rule target (for example, a SNS Topic ARN). Otherwise a separate sns topic for this service will be created. | `string` | `""` | no |
| <a name="input_deployment_config_name"></a> [deployment\_config\_name](#input\_deployment\_config\_name) | The name of the deployment config used in the CodeDeploy deployment group, see https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html for all available default configurations or provide a custom one. | `string` | `"CodeDeployDefault.LambdaAllAtOnce"` | no |
| <a name="input_ecr_image_tag"></a> [ecr\_image\_tag](#input\_ecr\_image\_tag) | The container tag used for ECR/container based deployments. | `string` | `"latest"` | no |
| <a name="input_ecr_repository_name"></a> [ecr\_repository\_name](#input\_ecr\_repository\_name) | Name of the ECR repository source used for ECR/container based deployments, required for `package_type=Image`. | `string` | `""` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | The name of your Lambda Function to deploy. | `string` | n/a | yes |
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | Name of the bucket used for S3 based deployments, required for `package_type=Zip`. Make sure to enable S3 bucket notifications for this bucket for continuous deployment of your Lambda function, see https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventBridge.html. | `string` | `""` | no |
| <a name="input_s3_key"></a> [s3\_key](#input\_s3\_key) | Object key used for S3 based deployments, required for `package_type=Zip`. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources supporting tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codebuild_project_arn"></a> [codebuild\_project\_arn](#output\_codebuild\_project\_arn) | The Amazon Resource Name (ARN) of the CodeBuild project. |
| <a name="output_codebuild_project_id"></a> [codebuild\_project\_id](#output\_codebuild\_project\_id) | The Id of the CodeBuild project. |
| <a name="output_codedeploy_app_arn"></a> [codedeploy\_app\_arn](#output\_codedeploy\_app\_arn) | The Amazon Resource Name (ARN) of the CodeDeploy application. |
| <a name="output_codedeploy_app_name"></a> [codedeploy\_app\_name](#output\_codedeploy\_app\_name) | The name of the CodeDeploy application. |
| <a name="output_codedeploy_deployment_group_arn"></a> [codedeploy\_deployment\_group\_arn](#output\_codedeploy\_deployment\_group\_arn) | The Amazon Resource Name (ARN) of the CodeDeploy deployment group. |
| <a name="output_codedeploy_deployment_group_deployment_group_id"></a> [codedeploy\_deployment\_group\_deployment\_group\_id](#output\_codedeploy\_deployment\_group\_deployment\_group\_id) | The ID of the CodeDeploy deployment group. |
| <a name="output_codedeploy_deployment_group_id"></a> [codedeploy\_deployment\_group\_id](#output\_codedeploy\_deployment\_group\_id) | Application name and deployment group name. |
| <a name="output_codepipeline_arn"></a> [codepipeline\_arn](#output\_codepipeline\_arn) | The Amazon Resource Name (ARN) of the CodePipeline. |
| <a name="output_codepipeline_artifact_storage_arn"></a> [codepipeline\_artifact\_storage\_arn](#output\_codepipeline\_artifact\_storage\_arn) | The Amazon Resource Name (ARN) of the CodePipeline artifact store. |
| <a name="output_codepipeline_id"></a> [codepipeline\_id](#output\_codepipeline\_id) | The ID of the CodePipeline. |
| <a name="output_codepipeline_role_name"></a> [codepipeline\_role\_name](#output\_codepipeline\_role\_name) | The name of the IAM role used for the CodePipeline. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
