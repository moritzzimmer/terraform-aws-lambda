# AWS Lambda Terraform module

![](https://github.com/moritzzimmer/terraform-aws-lambda/workflows/Terraform%20CI/badge.svg) [![Terraform Module Registry](https://img.shields.io/badge/Terraform%20Module%20Registry-5.5.2-blue.svg)](https://registry.terraform.io/modules/moritzzimmer/lambda/aws/5.5.2) ![Terraform Version](https://img.shields.io/badge/Terraform-0.12+-green.svg) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Terraform module to create AWS [Lambda](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) resources with configurable event sources, IAM configuration (following the [principal of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)), VPC as well as SSM and log streaming support.

The following [event sources](https://docs.aws.amazon.com/lambda/latest/dg/invoking-lambda-function.html) are supported (see [examples](#examples)):

- [cloudwatch-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-cloudwatch-event): configures a [CloudWatch Event Rule](https://www.terraform.io/docs/providers/aws/r/cloudwatch_event_rule.html) to trigger the Lambda by CloudWatch [event pattern](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/CloudWatchEventsandEventPatterns.html) or on a regular, scheduled basis
- [dynamodb](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-dynamodb-event): configures an [Event Source Mapping](https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html) to trigger the Lambda by DynamoDb events
- [kinesis](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-kinesis-event): configures an [Event Source Mapping](https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html) to trigger the Lambda by Kinesis events
- [s3](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-s3-event): configures permission to trigger the Lambda by S3
- [sns](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-sns-event): to trigger Lambda by [SNS Topic Subscription](https://www.terraform.io/docs/providers/aws/r/sns_topic_subscription.html)
- [sqs](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-sqs-event): configures an [Event Source Mapping](https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html) to trigger the Lambda by SQS events

Furthermore this module supports:

- adding IAM permissions for read access to parameters from [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
- [CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html) Log group configuration including retention time and [subscription filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html) e.g. to stream logs via Lambda to Elasticsearch

## History

Implementation of this module started at [Spring Media/Welt](https://github.com/spring-media/terraform-aws-lambda). Users of `spring-media/lambda/aws`
should migrate to this module as a drop-in replacement for all provisions up to release/tag `5.2.0` to benefit from new features and bugfixes.

## How do I use this module?

The module can be used for all [runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html) supported by AWS Lambda.

Deployment packages can be specified either directly as a local file (using the `filename` argument) or indirectly via Amazon S3 (using the `s3_bucket`, `s3_key` and `s3_object_versions` arguments), see [documentation](https://www.terraform.io/docs/providers/aws/r/lambda_function.html#specifying-the-deployment-package) for details.

**basic**

```terraform
provider "aws" {
  region = "eu-west-1"
}

module "lambda" {
  source           = "moritzzimmer/lambda/aws"
  version          = "5.5.2"
  filename         = "my-package.zip"
  function_name    = "my-function"
  handler          = "my-handler"
  runtime          = "go1.x"
  source_code_hash = filebase64sha256("${path.module}/my-package.zip")
}
```

**with event trigger**

```terraform
module "lambda" {
  // see above

  event = {
    type                = "cloudwatch-event"
    schedule_expression = "rate(1 minute)"
  }
}
```

**in a VPC**

```terraform
module "lambda" {
  // see above

  vpc_config = {
    security_group_ids = ["sg-1"]
    subnet_ids         = ["subnet-1", "subnet-2"]
  }
}
```

**with access to parameter store**

```terraform
module "lambda" {
  // see above

  ssm = {
      parameter_names = [aws_ssm_parameter.string.name, aws_ssm_parameter.secure_string.name]
  }
}
```

**with log subscription (stream to ElasticSearch)**

```terraform
module "lambda" {
  // see above

  logfilter_destination_arn = "arn:aws:lambda:eu-west-1:647379381847:function:cloudwatch_logs_to_es_production"
}
```

### Examples

- [example-with-cloudwatch-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-cloudwatch-event)
- [example-with-dynamodb-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-dynamodb-event)
- [example-with-kinesis-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-kinesis-event)
- [example-with-s3-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-s3-event)
- [example-with-sns-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-sns-event)
- [example-with-sqs-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-sqs-event)
- [example-with-ssm-permissions](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-ssm-permissions)
- [example-with-vpc](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-vpc)
- [example-without-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-without-event)

### bootstrap with func

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
| terraform | >= 0.12.0 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| description | Description of what your Lambda Function does. | `string` | `""` | no |
| environment | Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries | <pre>object({<br>    variables = map(string)<br>  })</pre> | `null` | no |
| event | Event source configuration which triggers the Lambda function. Supported events: cloudwatch-scheduled-event, dynamodb, s3, sns | `map(string)` | `{}` | no |
| filename | The path to the function's deployment package within the local filesystem. If defined, The s3\_-prefixed options cannot be used. | `string` | `""` | no |
| function\_name | A unique name for your Lambda Function. | `any` | n/a | yes |
| handler | The function entrypoint in your code. | `any` | n/a | yes |
| kms\_key\_arn | Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. If this configuration is provided when environment variables are not in use, the AWS Lambda API does not save this configuration and Terraform will show a perpetual difference of adding the key. To fix the perpetual difference, remove this configuration. | `string` | `""` | no |
| layers | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function. | `list(string)` | `[]` | no |
| log\_retention\_in\_days | Specifies the number of days you want to retain log events in the specified log group. Defaults to 14. | `number` | `14` | no |
| logfilter\_destination\_arn | The ARN of the destination to deliver matching log events to. Kinesis stream or Lambda function ARN. | `string` | `""` | no |
| memory\_size | Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128. | `number` | `128` | no |
| publish | Whether to publish creation/change as new Lambda Function Version. Defaults to false. | `bool` | `false` | no |
| reserved\_concurrent\_executions | The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1. | `string` | `"-1"` | no |
| runtime | The runtime environment for the Lambda function you are uploading. | `any` | n/a | yes |
| s3\_bucket | The S3 bucket location containing the function's deployment package. Conflicts with filename. This bucket must reside in the same AWS region where you are creating the Lambda function. | `string` | `""` | no |
| s3\_key | The S3 key of an object containing the function's deployment package. Conflicts with filename. | `string` | `""` | no |
| s3\_object\_version | The object version containing the function's deployment package. Conflicts with filename. | `string` | `""` | no |
| source\_code\_hash | Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3\_key. The usual way to set this is filebase64sha256('file.zip') where 'file.zip' is the local filename of the lambda function source archive. | `string` | `""` | no |
| ssm | List of AWS Systems Manager Parameter Store parameter names. The IAM role of this Lambda function will be enhanced with read permissions for those parameters. Parameters must start with a forward slash and can be encrypted with the default KMS key. | <pre>object({<br>    parameter_names = list(string)<br>  })</pre> | `null` | no |
| ssm\_parameter\_names | DEPRECATED: use `ssm` object instead. This variable will be removed in version 6 of this module. (List of AWS Systems Manager Parameter Store parameters this Lambda will have access to. In order to decrypt secure parameters, a kms\_key\_arn needs to be provided as well.) | `list` | `[]` | no |
| tags | A mapping of tags to assign to the Lambda function and all resources supporting tags. | `map(string)` | `{}` | no |
| timeout | The amount of time your Lambda Function has to run in seconds. Defaults to 3. | `number` | `3` | no |
| vpc\_config | Provide this to allow your function to access your VPC (if both 'subnet\_ids' and 'security\_group\_ids' are empty then vpc\_config is considered to be empty or unset, see https://docs.aws.amazon.com/lambda/latest/dg/vpc.html for details). | <pre>object({<br>    security_group_ids = list(string)<br>    subnet_ids         = list(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| function\_name | The unique name of your Lambda Function. |
| invoke\_arn | The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws\_api\_gateway\_integration's uri |
| role\_name | The name of the IAM role attached to the Lambda Function. |
| version | Latest published version of your Lambda Function. |

