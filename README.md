# AWS Lambda Terraform module

![](https://github.com/moritzzimmer/terraform-aws-lambda/workflows/Terraform%20CI/badge.svg) [![Terraform Module Registry](https://img.shields.io/badge/Terraform%20Module%20Registry-5.12.2-blue.svg)](https://registry.terraform.io/modules/moritzzimmer/lambda/aws/5.12.2) ![Terraform Version](https://img.shields.io/badge/Terraform-0.12+-green.svg) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Terraform module to create AWS [Lambda](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) and accompanying resources for an efficient and secure
development of Lambda functions like:

- inline declaration of triggers for DynamodDb, EventBridge (CloudWatch Events), Kinesis, SNS or SQS including all required permissions
- IAM role with permissions following the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
- CloudWatch Logs and Lambda Insights configuration
- blue/green deployments with AWS CodePipeline and CodeDeploy

## Features

- IAM role with permissions following the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
- inline declaration of [Event Source Mappings](https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html) for DynamoDb, Kinesis and SQS triggers including required permissions (see [examples](examples/with-event-source-mappings)).
- inline declaration of [SNS Topic Subscriptions](https://www.terraform.io/docs/providers/aws/r/sns_topic_subscription.html) including required [Lambda permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) (see [example](examples/with-sns-subscriptions))
- inline declaration of [CloudWatch Event Rules](https://www.terraform.io/docs/providers/aws/r/cloudwatch_event_rule.html) including required [Lambda permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) (see [example](examples/with-cloudwatch-event-rules))
- IAM permissions for read access to parameters from [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
- [CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html) Log group configuration including retention time and [subscription filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html) with required permissions to stream logs via another Lambda (e.g. to Elasticsearch)
- Lambda@Edge support fulfilling [requirements for CloudFront triggers](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-requirements-limits.html#lambda-requirements-cloudfront-triggers). Functions need
to be deployed to US East (N. Virginia) region (`us-east-1`)
- configuration for [Amazon CloudWatch Lambda Insights](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-insights.html) including required
  permissions and Lambda Layer, see [details](#with-cloudwatch-lambda-insights)
- add-on [module](modules/deployment) for controlled blue/green deployments using AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)
  and [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps-lambda.html) including all required permissions (see [example](examples/deployment)).
  Optionally ignore terraform state changes resulting from those deployments (using `ignore_external_function_updates`).

## History

Implementation of this module started at [Spring Media/Welt](https://github.com/spring-media/terraform-aws-lambda). Users of `spring-media/lambda/aws`
should migrate to this module as a drop-in replacement to benefit from new features and bugfixes.

## How do I use this module?

The module can be used for all [runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html) supported by AWS Lambda.

Deployment packages can be specified either directly as a local file (using the `filename` argument), indirectly via Amazon S3 (using the `s3_bucket`, `s3_key` and `s3_object_versions` arguments)
or using [container images](https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html) (using `image_uri` and `package_type` arguments),
see [documentation](https://www.terraform.io/docs/providers/aws/r/lambda_function.html#specifying-the-deployment-package) for details.

### simple

see [example](examples/simple) for details

```hcl
provider "aws" {
  region = "eu-west-1"
}

module "lambda" {
  source           = "moritzzimmer/lambda/aws"
  version          = "5.12.2"

  filename         = "my-package.zip"
  function_name    = "my-function"
  handler          = "my-handler"
  runtime          = "go1.x"
  source_code_hash = filebase64sha256("${path.module}/my-package.zip")
}
```

### using container images

see [example](examples/container-image) for details

```hcl
module "lambda" {
  source        = "moritzzimmer/lambda/aws"
  version       = "5.12.2"

  function_name = "my-function"
  image_uri     = "111111111111.dkr.ecr.eu-west-1.amazonaws.com/my-image"
  package_type  = "Image"
}
```

### with Amazon EventBridge (CloudWatch Events) rules

[CloudWatch Event Rules](https://www.terraform.io/docs/providers/aws/r/cloudwatch_event_rule.html) to trigger your Lambda function
by [EventBridge](https://docs.aws.amazon.com/eventbridge/latest/userguide/what-is-amazon-eventbridge.html) patterns or on a regular, scheduled basis can
be declared inline. The module will create the required [Lambda permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission)
automatically.

see [example](examples/with-cloudwatch-event-rules) for details

```hcl
module "lambda" {
  // see above

  cloudwatch_event_rules = {
    scheduled = {
      schedule_expression = "rate(1 minute)"

      // optionally overwrite arguments like 'description'
      // from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule
      description = "Triggered by CloudTrail"

      // optionally overwrite `cloudwatch_event_target_arn` in case an alias should be used for the event rule
      cloudwatch_event_target_arn = aws_lambda_alias.example.arn
    }

    pattern = {
      event_pattern = <<PATTERN
      {
        "detail-type": [
          "AWS Console Sign In via CloudTrail"
        ]
      }
      PATTERN
    }
  }
}
```

### with event source mappings

[Event Source Mappings](https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html) to trigger your Lambda function by DynamoDb,
Kinesis and SQS can be declared inline. The module will add the required IAM permissions depending on the event source type to the function role automatically.

see [examples](examples/with-event-source-mappings) for details

```hcl
module "lambda" {
  // see above

  event_source_mappings = {
    table_1 = {
      event_source_arn  = aws_dynamodb_table.table_1.stream_arn

      // optionally overwrite arguments like 'batch_size'
      // from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping
      batch_size        = 50
      starting_position = "LATEST"

      // optionally overwrite function_name in case an alias should be used in the
      // event source mapping, see https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html
      function_name = aws_lambda_alias.example.arn
    }

    table_2 = {
      event_source_arn = aws_dynamodb_table.table_2.stream_arn
    }
  }
}
```

### with SNS subscriptions

[SNS Topic Subscriptions](https://www.terraform.io/docs/providers/aws/r/sns_topic_subscription.html) to trigger your Lambda function by SNS can de declared inline.
The module will create the required [Lambda permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) automatically.

see [example](examples/with-sns-subscriptions) for details

```hcl
module "lambda" {
  // see above

  sns_subscriptions = {
    topic_1 = {
      topic_arn = aws_sns_topic.topic_1.arn

      // optionally overwrite `endpoint` in case an alias should be used for the SNS subscription
      endpoint  = aws_lambda_alias.example.arn
    }

    topic_2 = {
      topic_arn = aws_sns_topic.topic_2.arn
    }
  }
}
```

### with access to AWS Systems Manager Parameter Store

Required IAM permissions to get parameter(s) from [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
(by path or name) can added to the Lambda role:

```hcl
module "lambda" {
  // see above

  ssm = {
      parameter_names = [aws_ssm_parameter.string.name, aws_ssm_parameter.secure_string.name]
  }
}
```

### with CloudWatch Logs configuration

The module will create a [CloudWatch Log Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)
for your Lambda function.

The retention period and a [CloudWatch Logs subscription filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter)
(e.g. to stream logs to Amazon Elasticsearch Service) including required permissions can be declared inline:

```hcl
module "lambda" {
  // see above

  log_retention_in_days     = 7
  logfilter_destination_arn = "arn:aws:lambda:eu-west-1:647379381847:function:cloudwatch_logs_to_es_production"
}
```

### with CloudWatch Lambda Insights

[Amazon CloudWatch Lambda Insights](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-insights.html) can be enabled for `zip` and `image` function
deployment packages of these [runtimes](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-insights.html#monitoring-insights-runtimes):

```hcl
module "lambda" {
  // see above

  cloudwatch_lambda_insights_enabled = true
}
```

This module will add the required IAM permissions to the function role automatically for both package types.

In case of a `zip` deployment package, this module will also add the appropriate [extension layer](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versions.html)
to your function (use `cloudwatch_lambda_insights_extension_version` to set the version of this layer).

For `image` deployment packages, the Lambda Insights extension needs to be added to the [container image](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-Getting-Started-docker.html):

```dockerfile
FROM public.ecr.aws/lambda/nodejs:12

RUN curl -O https://lambda-insights-extension.s3-ap-northeast-1.amazonaws.com/amazon_linux/lambda-insights-extension.rpm && \
    rpm -U lambda-insights-extension.rpm && \
    rm -f lambda-insights-extension.rpm

COPY app.js /var/task/
```

## Deployments

Controlled, blue/green deployments of Lambda functions with (automatic) rolebacks and traffic shifting can be implemented using
Lambda [aliases](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html) and AWS [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html).

The optional [deployment](modules/deployment) submodule can be used to create the required AWS resources and permissions for creating and starting such
CodeDeploy deployments as part of an AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html), see [example](examples/deployment) for details.

## Examples

- [container-image](examples/container-image)
- [deployment](examples/deployment)
- [simple](examples/simple)
- [with-cloudwatch-event-rules](examples/with-cloudwatch-event-rules)
- [with-event-source-mappings](examples/with-event-source-mappings)
- [with-sns-subscriptions](examples/with-sns-subscriptions)


## Bootstrap new projects

In case you are using [go](https://golang.org/) for developing your Lambda functions, you can also use [func](https://github.com/moritzzimmer/func) to bootstrap your project and get started quickly.

## How do I contribute to this module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/moritzzimmer/terraform-aws-lambda/blob/master/CONTRIBUTING.md) for instructions.

## How is this module versioned?

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release in the [releases page](../../releases).

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR,
MINOR, and PATCH versions on each release to indicate any incompatibilities.
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.19 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.19 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_subscription_filter.cloudwatch_logs_to_es](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_iam_policy.event_sources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_lambda_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.event_sources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.tracing_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vpc_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_event_source_mapping.event_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_function.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.lambda_external_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.cloudwatch_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic_subscription.subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.event_sources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_event_rules"></a> [cloudwatch\_event\_rules](#input\_cloudwatch\_event\_rules) | Creates EventBridge (CloudWatch Events) rules invoking your Lambda function. Required Lambda invocation permissions will be generated. | `map(any)` | `{}` | no |
| <a name="input_cloudwatch_lambda_insights_enabled"></a> [cloudwatch\_lambda\_insights\_enabled](#input\_cloudwatch\_lambda\_insights\_enabled) | Enable CloudWatch Lambda Insights for your Lambda function. | `bool` | `false` | no |
| <a name="input_cloudwatch_lambda_insights_extension_version"></a> [cloudwatch\_lambda\_insights\_extension\_version](#input\_cloudwatch\_lambda\_insights\_extension\_version) | Version of the Lambda Insights extension for Lambda functions using `zip` deployment packages, see https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versions.html. | `number` | `14` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of what your Lambda Function does. | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries | <pre>object({<br>    variables = map(string)<br>  })</pre> | `null` | no |
| <a name="input_event_source_mappings"></a> [event\_source\_mappings](#input\_event\_source\_mappings) | Creates event source mappings to allow the Lambda function to get events from Kinesis, DynamoDB and SQS. The IAM role of this Lambda function will be enhanced with necessary minimum permissions to get those events. | `map(any)` | `{}` | no |
| <a name="input_filename"></a> [filename](#input\_filename) | The path to the function's deployment package within the local filesystem. If defined, The s3\_-prefixed options and image\_uri cannot be used. | `string` | `null` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | A unique name for your Lambda Function. | `string` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | The function entrypoint in your code. | `string` | `""` | no |
| <a name="input_ignore_external_function_updates"></a> [ignore\_external\_function\_updates](#input\_ignore\_external\_function\_updates) | Ignore updates to your Lambda function executed externally to the Terraform lifecycle. Set this to `true` if you're using CodeDeploy, aws CLI or other external tools to update your Lambda function code. | `bool` | `false` | no |
| <a name="input_image_config"></a> [image\_config](#input\_image\_config) | The Lambda OCI [image configurations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#image_config) block with three (optional) arguments:<br><br>  - *entry\_point* - The ENTRYPOINT for the docker image (type `list(string)`).<br>  - *command* - The CMD for the docker image (type `list(string)`).<br>  - *working\_directory* - The working directory for the docker image (type `string`). | `any` | `{}` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | The ECR image URI containing the function's deployment package. Conflicts with filename, s3\_bucket, s3\_key, and s3\_object\_version. | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. If this configuration is provided when environment variables are not in use, the AWS Lambda API does not save this configuration and Terraform will show a perpetual difference of adding the key. To fix the perpetual difference, remove this configuration. | `string` | `""` | no |
| <a name="input_lambda_at_edge"></a> [lambda\_at\_edge](#input\_lambda\_at\_edge) | Enable Lambda@Edge for your Node.js or Python functions. Required trust relationship and publishing of function versions will be configured. | `bool` | `false` | no |
| <a name="input_layers"></a> [layers](#input\_layers) | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function. | `list(string)` | `[]` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Specifies the number of days you want to retain log events in the specified log group. | `number` | `14` | no |
| <a name="input_logfilter_destination_arn"></a> [logfilter\_destination\_arn](#input\_logfilter\_destination\_arn) | The ARN of the destination to deliver matching log events to. Kinesis stream or Lambda function ARN. | `string` | `""` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Amount of memory in MB your Lambda Function can use at runtime. | `number` | `128` | no |
| <a name="input_package_type"></a> [package\_type](#input\_package\_type) | The Lambda deployment package type. Valid values are Zip and Image. | `string` | `"Zip"` | no |
| <a name="input_publish"></a> [publish](#input\_publish) | Whether to publish creation/change as new Lambda Function Version. | `bool` | `false` | no |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. | `number` | `-1` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The runtime environment for the Lambda function you are uploading. | `string` | `""` | no |
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | The S3 bucket location containing the function's deployment package. Conflicts with filename and image\_uri. This bucket must reside in the same AWS region where you are creating the Lambda function. | `string` | `null` | no |
| <a name="input_s3_key"></a> [s3\_key](#input\_s3\_key) | The S3 key of an object containing the function's deployment package. Conflicts with filename and image\_uri. | `string` | `null` | no |
| <a name="input_s3_object_version"></a> [s3\_object\_version](#input\_s3\_object\_version) | The object version containing the function's deployment package. Conflicts with filename and image\_uri. | `string` | `null` | no |
| <a name="input_sns_subscriptions"></a> [sns\_subscriptions](#input\_sns\_subscriptions) | Creates subscriptions to SNS topics which trigger your Lambda function. Required Lambda invocation permissions will be generated. | `map(any)` | `{}` | no |
| <a name="input_source_code_hash"></a> [source\_code\_hash](#input\_source\_code\_hash) | Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3\_key. The usual way to set this is filebase64sha256('file.zip') where 'file.zip' is the local filename of the lambda function source archive. | `string` | `""` | no |
| <a name="input_ssm"></a> [ssm](#input\_ssm) | List of AWS Systems Manager Parameter Store parameter names. The IAM role of this Lambda function will be enhanced with read permissions for those parameters. Parameters must start with a forward slash and can be encrypted with the default KMS key. | <pre>object({<br>    parameter_names = list(string)<br>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the Lambda function and all resources supporting tags. | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The amount of time your Lambda Function has to run in seconds. | `number` | `3` | no |
| <a name="input_tracing_config_mode"></a> [tracing\_config\_mode](#input\_tracing\_config\_mode) | Tracing config mode of the Lambda function. Can be either PassThrough or Active. | `string` | `null` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | Provide this to allow your function to access your VPC (if both 'subnet\_ids' and 'security\_group\_ids' are empty then vpc\_config is considered to be empty or unset, see https://docs.aws.amazon.com/lambda/latest/dg/vpc.html for details). | <pre>object({<br>    security_group_ids = list(string)<br>    subnet_ids         = list(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | The name of the CloudWatch log group used by your Lambda function. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | The unique name of your Lambda Function. |
| <a name="output_invoke_arn"></a> [invoke\_arn](#output\_invoke\_arn) | The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws\_api\_gateway\_integration's uri |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the IAM role attached to the Lambda Function. |
| <a name="output_version"></a> [version](#output\_version) | Latest published version of your Lambda Function. |
