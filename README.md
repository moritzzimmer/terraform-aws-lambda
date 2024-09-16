# AWS Lambda Terraform module

![](https://github.com/moritzzimmer/terraform-aws-lambda/workflows/static%20analysis/badge.svg) [![Terraform Module Registry](https://img.shields.io/badge/Terraform%20Module%20Registry-7.6.1-blue.svg)](https://registry.terraform.io/modules/moritzzimmer/lambda/aws/7.6.1) ![Terraform Version](https://img.shields.io/badge/Terraform-0.12+-green.svg) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Terraform module to create AWS [Lambda](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) and accompanying resources for an efficient and secure
development of Lambda functions like:

- inline declaration of triggers for DynamodDb, EventBridge (CloudWatch Events), Kinesis, SNS or SQS including all required permissions
- IAM role with permissions following the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
- CloudWatch Logs and Lambda Insights configuration
- [blue/green deployments](https://github.com/moritzzimmer/terraform-aws-lambda/blob/main/modules/deployment/README.md) with AWS CodePipeline and CodeDeploy

## Features

- IAM role with permissions following the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
- inline declaration of [Event Source Mappings](https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html) for DynamoDb, Kinesis and SQS triggers including required permissions (see [examples](examples/with-event-source-mappings)).
- inline declaration of [SNS Topic Subscriptions](https://www.terraform.io/docs/providers/aws/r/sns_topic_subscription.html) including required [Lambda permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) (see [example](examples/with-sns-subscriptions))
- inline declaration of [CloudWatch Event Rules](https://www.terraform.io/docs/providers/aws/r/cloudwatch_event_rule.html) including required [Lambda permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) (see [example](examples/with-cloudwatch-event-rules))
- IAM permissions for read access to parameters from [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
- [CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html) Log group configuration including retention time and [subscription filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html) with required permissions
to stream logs to other Lambda functions (e.g. forwarding logs to Elasticsearch)
- Lambda@Edge support fulfilling [requirements for CloudFront triggers](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-requirements-limits.html#lambda-requirements-cloudfront-triggers). Functions need
to be deployed to US East (N. Virginia) region (`us-east-1`)
- configuration for [Amazon CloudWatch Lambda Insights](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-insights.html) including required
  permissions and Lambda Layer, see [details](#with-cloudwatch-lambda-insights)
- add-on [module](modules/deployment) for controlled blue/green deployments using AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)
  and [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps-lambda.html) including all required permissions (see [examples](examples/deployment)).
  Optionally ignore terraform state changes resulting from those deployments (using `ignore_external_function_updates`).

## How do I use this module?

The module can be used for all [runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html) supported by AWS Lambda.

Deployment packages can be specified either directly as a local file (using the `filename` argument), indirectly via Amazon S3 (using the `s3_bucket`, `s3_key` and `s3_object_versions` arguments)
or using [container images](https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html) (using `image_uri` and `package_type` arguments),
see [documentation](https://www.terraform.io/docs/providers/aws/r/lambda_function.html#specifying-the-deployment-package) for details.

### basic

see [example](examples/complete) for other configuration options

```hcl
provider "aws" {
  region = "eu-west-1"
}

module "lambda" {
  source           = "moritzzimmer/lambda/aws"

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

      // optionally add `cloudwatch_event_target_input` for event input
      cloudwatch_event_target_input = jsonencode({"key": "value"})
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
Kinesis and SQS can be declared inline. The module will add the required read-only IAM permissions depending on the event source type to
the function role automatically (including support for [dedicated-throughput consumers](https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-configure) using enhanced fan-out).

Permissions to send discarded batches to SNS or SQS will be added automatically, if `destination_arn_on_failure` is configured.

see [examples](examples/with-event-source-mappings) for details

#### DynamoDb

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

      // optionally configure a SNS or SQS destination for discarded batches, required IAM
      // permissions will be added automatically by this module,
      // see https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html
      destination_arn_on_failure = aws_sqs_queue.errors.arn

      // optionally overwrite function_name in case an alias should be used in the
      // event source mapping, see https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html
      function_name = aws_lambda_alias.example.arn

      // Lambda event filtering, see https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventfiltering.html
      filter_criteria = [
        {
          pattern = jsonencode({
            data : {
              Key1 : ["Value1"]
            }
          })
        },
        {
          pattern = jsonencode({
            data : {
              Key2 : [{ "anything-but" : ["Value2"] }]
            }
          })
        }
      ]
    }

    table_2 = {
      event_source_arn = aws_dynamodb_table.table_2.stream_arn
    }
  }
}
```

#### Kinesis

```hcl
resource "aws_kinesis_stream_consumer" "this" {
  name       = module.lambda.function_name
  stream_arn = aws_kinesis_stream.stream_2.arn
}

module "lambda" {
  // see above

  event_source_mappings = {
    stream_1 = {
      // To use a dedicated-throughput consumer with enhanced fan-out, specify the consumer's ARN instead of the stream's ARN, see https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-configure
      event_source_arn = aws_kinesis_stream_consumer.this.arn
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
for your Lambda function. It's retention period and [CloudWatch Logs subscription filters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter)
to stream logs to other Lambda functions (e.g. to forward logs to Amazon OpenSearch Service) can be declared inline.

The module will create the required [Lambda permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) automatically.
Sending logs to CloudWatch can be disabled with `cloudwatch_logs_enabled = false`

see [example](examples/with-cloudwatch-logs-subscription) for details

```hcl
module "lambda" {
  // see above

  // disable CloudWatch logs
  // cloudwatch_logs_enabled = false

  cloudwatch_logs_retention_in_days = 14

  cloudwatch_log_subscription_filters = {
    lambda_1 = {
      //see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter for available arguments
      destination_arn = module.destination_1.arn
    }

    lambda_2 = {
      destination_arn = module.destination_2.arn
    }
  }
}
```

### with CloudWatch Lambda Insights

[Amazon CloudWatch Lambda Insights](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-insights.html) can be enabled for `zip` and `image` function
deployment packages of all [runtimes](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-extensions-api.html) supporting Lambda extensions.

This module will add the required IAM permissions to the function role automatically for both package types. In case of a `zip` deployment package,
the region and architecture specific [layer version](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versions.html)
needs to specified in `layers`.

```hcl
module "lambda" {
  // see above

  cloudwatch_lambda_insights_enabled = true

  // see https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versions.html
  layers = "arn:aws:lambda:eu-west-1:580247275435:layer:LambdaInsightsExtension:16"
}
```

For `image` deployment packages, the Lambda Insights extension needs to be added to the [container image](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-Getting-Started-docker.html):

```dockerfile
FROM public.ecr.aws/lambda/nodejs:12

RUN curl -O https://lambda-insights-extension.s3-ap-northeast-1.amazonaws.com/amazon_linux/lambda-insights-extension.rpm && \
    rpm -U lambda-insights-extension.rpm && \
    rm -f lambda-insights-extension.rpm

COPY index.js /var/task/
```

## Deployments

Controlled, blue/green deployments of Lambda functions with (automatic) rollbacks and traffic shifting can be implemented using
Lambda [aliases](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html) and AWS [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html).

The [deployment](modules/deployment) submodule can be used to create the required AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html), [CodeBuild](https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html)
and [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html) resources and permissions to execute secure deployments of S3 or containerized Lambda functions in your AWS account,
see [examples](examples/deployment) for details.

## Examples

- [complete](examples/complete)
- [container-image](examples/container-image)
- [deployment](examples/deployment)
- [with-cloudwatch-event-rules](examples/with-cloudwatch-event-rules)
- [with-cloudwatch-logs-subscription](examples/with-cloudwatch-logs-subscription)
- [with-event-source-mappings](examples/with-event-source-mappings)
- [with-sns-subscriptions](examples/with-sns-subscriptions)
- [with-vpc](examples/with-vpc)


## Bootstrap new projects

In case you are using [go](https://golang.org/) for developing your Lambda functions, you can also use [func](https://github.com/moritzzimmer/func) to bootstrap your project and get started quickly.

## How do I contribute to this module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/moritzzimmer/terraform-aws-lambda/blob/main/CONTRIBUTING.md) for instructions.

## How is this module versioned?

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release in the [releases page](../../releases).

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR,
MINOR, and PATCH versions on each release to indicate any incompatibilities.

## History

Implementation of this module started at [Spring Media/Welt](https://github.com/spring-media/terraform-aws-lambda). Users of `spring-media/lambda/aws`
should migrate to this module as a drop-in replacement to benefit from new features and bugfixes.

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
| [aws_cloudwatch_event_rule.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_subscription_filter.cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_iam_policy.event_sources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_lambda_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.event_sources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
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
| [aws_iam_policy_document.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_architectures"></a> [architectures](#input\_architectures) | Instruction set architecture for your Lambda function. Valid values are ["x86\_64"] and ["arm64"]. Removing this attribute, function's architecture stay the same. | `list(string)` | `null` | no |
| <a name="input_cloudwatch_event_rules"></a> [cloudwatch\_event\_rules](#input\_cloudwatch\_event\_rules) | Creates EventBridge (CloudWatch Events) rules invoking your Lambda function. Required Lambda invocation permissions will be generated. | `map(any)` | `{}` | no |
| <a name="input_cloudwatch_lambda_insights_enabled"></a> [cloudwatch\_lambda\_insights\_enabled](#input\_cloudwatch\_lambda\_insights\_enabled) | Enable CloudWatch Lambda Insights for your Lambda function. | `bool` | `false` | no |
| <a name="input_cloudwatch_log_subscription_filters"></a> [cloudwatch\_log\_subscription\_filters](#input\_cloudwatch\_log\_subscription\_filters) | CloudWatch Logs subscription filter resources. Currently supports only Lambda functions as destinations. | `map(any)` | `{}` | no |
| <a name="input_cloudwatch_logs_enabled"></a> [cloudwatch\_logs\_enabled](#input\_cloudwatch\_logs\_enabled) | Enables your Lambda function to send logs to CloudWatch. The IAM role of this Lambda function will be enhanced with required permissions. | `bool` | `true` | no |
| <a name="input_cloudwatch_logs_kms_key_id"></a> [cloudwatch\_logs\_kms\_key\_id](#input\_cloudwatch\_logs\_kms\_key\_id) | The ARN of the KMS Key to use when encrypting log data. | `string` | `null` | no |
| <a name="input_cloudwatch_logs_retention_in_days"></a> [cloudwatch\_logs\_retention\_in\_days](#input\_cloudwatch\_logs\_retention\_in\_days) | Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire. | `number` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of what your Lambda Function does. | `string` | `"Instruction set architecture for your Lambda function. Valid values are [\"x86_64\"] and [\"arm64\"]."` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries | <pre>object({<br>    variables = map(string)<br>  })</pre> | `null` | no |
| <a name="input_ephemeral_storage_size"></a> [ephemeral\_storage\_size](#input\_ephemeral\_storage\_size) | The size of your Lambda functions ephemeral storage (/tmp) represented in MB. Valid value between 512 MB to 10240 MB. | `number` | `512` | no |
| <a name="input_event_source_mappings"></a> [event\_source\_mappings](#input\_event\_source\_mappings) | Creates event source mappings to allow the Lambda function to get events from Kinesis, DynamoDB and SQS. The IAM role of this Lambda function will be enhanced with necessary minimum permissions to get those events. | `any` | `{}` | no |
| <a name="input_filename"></a> [filename](#input\_filename) | The path to the function's deployment package within the local filesystem. If defined, The s3\_-prefixed options and image\_uri cannot be used. | `string` | `null` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | A unique name for your Lambda Function. | `string` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | The function entrypoint in your code. | `string` | `""` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Override the name of the IAM role for the function. Otherwise the default will be your function name with the region as a suffix. | `string` | `null` | no |
| <a name="input_ignore_external_function_updates"></a> [ignore\_external\_function\_updates](#input\_ignore\_external\_function\_updates) | Ignore updates to your Lambda function executed externally to the Terraform lifecycle. Set this to `true` if you're using CodeDeploy, aws CLI or other external tools to update your Lambda function code. | `bool` | `false` | no |
| <a name="input_image_config"></a> [image\_config](#input\_image\_config) | The Lambda OCI [image configurations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#image_config) block with three (optional) arguments:<br><br>  - *entry\_point* - The ENTRYPOINT for the docker image (type `list(string)`).<br>  - *command* - The CMD for the docker image (type `list(string)`).<br>  - *working\_directory* - The working directory for the docker image (type `string`). | `any` | `{}` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | The ECR image URI containing the function's deployment package. Conflicts with filename, s3\_bucket, s3\_key, and s3\_object\_version. | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. If this configuration is provided when environment variables are not in use, the AWS Lambda API does not save this configuration and Terraform will show a perpetual difference of adding the key. To fix the perpetual difference, remove this configuration. | `string` | `""` | no |
| <a name="input_lambda_at_edge"></a> [lambda\_at\_edge](#input\_lambda\_at\_edge) | Enable Lambda@Edge for your Node.js or Python functions. Required trust relationship and publishing of function versions will be configured. | `bool` | `false` | no |
| <a name="input_layers"></a> [layers](#input\_layers) | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function. | `list(string)` | `[]` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Amount of memory in MB your Lambda Function can use at runtime. | `number` | `128` | no |
| <a name="input_package_type"></a> [package\_type](#input\_package\_type) | The Lambda deployment package type. Valid values are Zip and Image. | `string` | `"Zip"` | no |
| <a name="input_publish"></a> [publish](#input\_publish) | Whether to publish creation/change as new Lambda Function Version. | `bool` | `false` | no |
| <a name="input_replace_security_groups_on_destroy"></a> [replace\_security\_groups\_on\_destroy](#input\_replace\_security\_groups\_on\_destroy) | (Optional) Whether to replace the security groups on the function's VPC configuration prior to destruction. Removing these security group associations prior to function destruction can speed up security group deletion times of AWS's internal cleanup operations. By default, the security groups will be replaced with the default security group in the function's configured VPC. Set the `replacement_security_group_ids` attribute to use a custom list of security groups for replacement. | `bool` | `null` | no |
| <a name="input_replacement_security_group_ids"></a> [replacement\_security\_group\_ids](#input\_replacement\_security\_group\_ids) | (Optional) List of security group IDs to assign to the function's VPC configuration prior to destruction. `replace_security_groups_on_destroy` must be set to `true` to use this attribute. | `list(string)` | `null` | no |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. | `number` | `-1` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The runtime environment for the Lambda function you are uploading. | `string` | `""` | no |
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | The S3 bucket location containing the function's deployment package. Conflicts with filename and image\_uri. This bucket must reside in the same AWS region where you are creating the Lambda function. | `string` | `null` | no |
| <a name="input_s3_key"></a> [s3\_key](#input\_s3\_key) | The S3 key of an object containing the function's deployment package. Conflicts with filename and image\_uri. | `string` | `null` | no |
| <a name="input_s3_object_version"></a> [s3\_object\_version](#input\_s3\_object\_version) | The object version containing the function's deployment package. Conflicts with filename and image\_uri. | `string` | `null` | no |
| <a name="input_snap_start"></a> [snap\_start](#input\_snap\_start) | Enable snap start settings for low-latency startups. This feature is currently only supported for `java11` and `java17` runtimes and `x86_64` architectures. | `bool` | `false` | no |
| <a name="input_sns_subscriptions"></a> [sns\_subscriptions](#input\_sns\_subscriptions) | Creates subscriptions to SNS topics which trigger your Lambda function. Required Lambda invocation permissions will be generated. | `map(any)` | `{}` | no |
| <a name="input_source_code_hash"></a> [source\_code\_hash](#input\_source\_code\_hash) | Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3\_key. The usual way to set this is filebase64sha256('file.zip') where 'file.zip' is the local filename of the lambda function source archive. | `string` | `""` | no |
| <a name="input_ssm"></a> [ssm](#input\_ssm) | List of AWS Systems Manager Parameter Store parameter names. The IAM role of this Lambda function will be enhanced with read permissions for those parameters. Parameters must start with a forward slash and can be encrypted with the default KMS key. | <pre>object({<br>    parameter_names = list(string)<br>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the Lambda function and all resources supporting tags. | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The amount of time your Lambda Function has to run in seconds. | `number` | `3` | no |
| <a name="input_tracing_config_mode"></a> [tracing\_config\_mode](#input\_tracing\_config\_mode) | Tracing config mode of the Lambda function. Can be either PassThrough or Active. | `string` | `null` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | Provide this to allow your function to access your VPC (if both `subnet_ids` and `security_group_ids` are empty then vpc\_config is considered to be empty or unset, see https://docs.aws.amazon.com/lambda/latest/dg/vpc.html for details). | <pre>object({<br>    ipv6_allowed_for_dual_stack = optional(bool, false)<br>    security_group_ids          = list(string)<br>    subnet_ids                  = list(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | The Amazon Resource Name (ARN) identifying the CloudWatch log group used by your Lambda function. |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | The name of the CloudWatch log group used by your Lambda function. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | The unique name of your Lambda Function. |
| <a name="output_invoke_arn"></a> [invoke\_arn](#output\_invoke\_arn) | The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws\_api\_gateway\_integration's uri |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The ARN of the IAM role attached to the Lambda Function. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the IAM role attached to the Lambda Function. |
| <a name="output_version"></a> [version](#output\_version) | Latest published version of your Lambda Function. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
