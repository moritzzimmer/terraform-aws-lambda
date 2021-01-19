# AWS Lambda Terraform module

![](https://github.com/moritzzimmer/terraform-aws-lambda/workflows/Terraform%20CI/badge.svg) [![Terraform Module Registry](https://img.shields.io/badge/Terraform%20Module%20Registry-5.8.0-blue.svg)](https://registry.terraform.io/modules/moritzzimmer/lambda/aws/5.8.0) ![Terraform Version](https://img.shields.io/badge/Terraform-0.12+-green.svg) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Terraform module to create AWS [Lambda](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) and accompanying resources for an efficient and secure
development of Lambda functions like:

- configurable trigger for DynamodDb, EventBridge, Kinesis, SNS and SQS
- IAM role with permissions following the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
- CloudWatch Logs configuration
- blue/green deployments with AWS CodePipeline and CodeDeploy

## Features

- IAM role with permissions following the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
- [Event Source Mappings](https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html) for DynamoDb, Kinesis and SQS triggers including required permissions (see [examples](examples/with-event-source-mappings)).
- [SNS Topic Subscriptions](https://www.terraform.io/docs/providers/aws/r/sns_topic_subscription.html) for SNS triggers including required [Lambda permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) (see [example](examples/with-sns-subscriptions))
- [CloudWatch Event Rules](https://www.terraform.io/docs/providers/aws/r/cloudwatch_event_rule.html) to trigger by [EventBridge](https://docs.aws.amazon.com/eventbridge/latest/userguide/what-is-amazon-eventbridge.html) event patterns or on a regular, scheduled basis (see [example](examples/example-with-cloudwatch-event))
- IAM permissions for read access to parameters from [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
- [CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html) Log group configuration including retention time and [subscription filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html) with required permissions to stream logs via another Lambda (e.g. to Elasticsearch)
- add-on [module](modules/deployment) for controlled blue/green deployments using AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)
  and [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps-lambda.html) including all required permissions (see [example](examples/deployment))

## History

Implementation of this module started at [Spring Media/Welt](https://github.com/spring-media/terraform-aws-lambda). Users of `spring-media/lambda/aws`
should migrate to this module as a drop-in replacement to benefit from new features and bugfixes.

## How do I use this module?

The module can be used for all [runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html) supported by AWS Lambda.

Deployment packages can be specified either directly as a local file (using the `filename` argument), indirectly via Amazon S3 (using the `s3_bucket`, `s3_key` and `s3_object_versions` arguments)
or using [container images](https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html) (using `image_uri` and `package_type` arguments),
see [documentation](https://www.terraform.io/docs/providers/aws/r/lambda_function.html#specifying-the-deployment-package) for details.

**simple**

```hcl
provider "aws" {
  region = "eu-west-1"
}

module "lambda" {
  source           = "moritzzimmer/lambda/aws"
  version          = "5.8.0"
  filename         = "my-package.zip"
  function_name    = "my-function"
  handler          = "my-handler"
  runtime          = "go1.x"
  source_code_hash = filebase64sha256("${path.module}/my-package.zip")
}
```

**using container images**

```hcl
module "lambda" {
  source        = "moritzzimmer/lambda/aws"
  version       = "5.8.0"
  function_name = "my-function"
  image_uri     = "111111111111.dkr.ecr.eu-west-1.amazonaws.com/my-image"
  package_type  = "Image"
}
```

**with event source mappings**

```hcl
module "lambda" {
  // see above

  event_source_mappings = {
    queue_1 = {
      event_source_arn = aws_sqs_queue.queue_1.arn
    }
    queue_2 = {
      event_source_arn = aws_sqs_queue.queue_2.arn
    }
  }
}
```

**with SNS subscriptions**

```hcl
module "lambda" {
  // see above

  sns_subscriptions = {
    topic_1 = {
      topic_arn = aws_sns_topic.topic_1.arn
    }

    topic_2 = {
      topic_arn = aws_sns_topic.topic_2.arn
    }
  }
}
```

**with access to parameter store**

```hcl
module "lambda" {
  // see above

  ssm = {
      parameter_names = [aws_ssm_parameter.string.name, aws_ssm_parameter.secure_string.name]
  }
}
```

**with log subscription (stream to ElasticSearch)**

```hcl
module "lambda" {
  // see above

  logfilter_destination_arn = "arn:aws:lambda:eu-west-1:647379381847:function:cloudwatch_logs_to_es_production"
}
```

### Deployments

Controlled, blue/green deployments of Lambda functions with (automatic) rolebacks and traffic shifting can be implemented using
Lambda [aliases](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html) and AWS [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html).

The optional [deployment](modules/deployment) submodule can be used to create the required AWS resources and permissions for creating and starting such
CodeDeploy deployments as part of an AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html), see [example](examples/deployment) for details.

### Examples

- [container-image](examples/container-image)
- [deployment](examples/deployment)
- [example-with-cloudwatch-event](examples/example-with-cloudwatch-event)
- [simple](examples/simple)
- [with-event-source-mappings](examples/with-event-source-mappings)
- [with-sns-subscriptions](examples/with-sns-subscriptions)


### Bootstrap with func

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
| aws | >= 3.19 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.19 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| description | Description of what your Lambda Function does. | `string` | `""` | no |
| environment | Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries | <pre>object({<br>    variables = map(string)<br>  })</pre> | `null` | no |
| event | Event source configuration which triggers the Lambda function. Supported events: cloudwatch-scheduled-event, dynamodb (deprecated - use event\_source\_mappings), kinesis (deprecated - use event\_source\_mappings), s3, sns (deprecated - use sns\_subscriptions), sqs (deprecated - use event\_source\_mappings) | `map(string)` | `{}` | no |
| event\_source\_mappings | Event source mappings to allow the Lambda function to get events from Kinesis, DynamoDB and SQS. The IAM role of this Lambda function will be enhanced with necessary minimum permissions to get those events. | `map(any)` | `{}` | no |
| filename | The path to the function's deployment package within the local filesystem. If defined, The s3\_-prefixed options and image\_uri cannot be used. | `string` | `null` | no |
| function\_name | A unique name for your Lambda Function. | `string` | n/a | yes |
| handler | The function entrypoint in your code. | `string` | `""` | no |
| ignore\_external\_function\_updates | Ignore updates to your Lambda function executed externally to the Terraform lifecycle. Set this to `true` if you're using CodeDeploy, aws CLI or other external tools to update your Lambda function code. | `bool` | `false` | no |
| image\_config | The Lambda OCI [image configurations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#image_config) block with three (optional) arguments:<br><br>  - *entry\_point* - The ENTRYPOINT for the docker image (type `list(string)`).<br>  - *command* - The CMD for the docker image (type `list(string)`).<br>  - *working\_directory* - The working directory for the docker image (type `string`). | `any` | `{}` | no |
| image\_uri | The ECR image URI containing the function's deployment package. Conflicts with filename, s3\_bucket, s3\_key, and s3\_object\_version. | `string` | `null` | no |
| kms\_key\_arn | Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. If this configuration is provided when environment variables are not in use, the AWS Lambda API does not save this configuration and Terraform will show a perpetual difference of adding the key. To fix the perpetual difference, remove this configuration. | `string` | `""` | no |
| layers | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function. | `list(string)` | `[]` | no |
| log\_retention\_in\_days | Specifies the number of days you want to retain log events in the specified log group. | `number` | `14` | no |
| logfilter\_destination\_arn | The ARN of the destination to deliver matching log events to. Kinesis stream or Lambda function ARN. | `string` | `""` | no |
| memory\_size | Amount of memory in MB your Lambda Function can use at runtime. | `number` | `128` | no |
| package\_type | The Lambda deployment package type. Valid values are Zip and Image. | `string` | `"Zip"` | no |
| publish | Whether to publish creation/change as new Lambda Function Version. | `bool` | `false` | no |
| reserved\_concurrent\_executions | The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. | `string` | `"-1"` | no |
| runtime | The runtime environment for the Lambda function you are uploading. | `string` | `""` | no |
| s3\_bucket | The S3 bucket location containing the function's deployment package. Conflicts with filename and image\_uri. This bucket must reside in the same AWS region where you are creating the Lambda function. | `string` | `null` | no |
| s3\_key | The S3 key of an object containing the function's deployment package. Conflicts with filename and image\_uri. | `string` | `null` | no |
| s3\_object\_version | The object version containing the function's deployment package. Conflicts with filename and image\_uri. | `string` | `null` | no |
| sns\_subscriptions | Subscriptions to SNS topics which trigger your Lambda function. Lambda invocation permissions will be generated. | `map(any)` | `{}` | no |
| source\_code\_hash | Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3\_key. The usual way to set this is filebase64sha256('file.zip') where 'file.zip' is the local filename of the lambda function source archive. | `string` | `""` | no |
| ssm | List of AWS Systems Manager Parameter Store parameter names. The IAM role of this Lambda function will be enhanced with read permissions for those parameters. Parameters must start with a forward slash and can be encrypted with the default KMS key. | <pre>object({<br>    parameter_names = list(string)<br>  })</pre> | `null` | no |
| ssm\_parameter\_names | DEPRECATED: use `ssm` object instead. This variable will be removed in version 6 of this module. (List of AWS Systems Manager Parameter Store parameters this Lambda will have access to. In order to decrypt secure parameters, a kms\_key\_arn needs to be provided as well.) | `list` | `[]` | no |
| tags | A mapping of tags to assign to the Lambda function and all resources supporting tags. | `map(string)` | `{}` | no |
| timeout | The amount of time your Lambda Function has to run in seconds. | `number` | `3` | no |
| tracing\_config\_mode | Tracing config mode of the Lambda function. Can be either PassThrough or Active. | `string` | `null` | no |
| vpc\_config | Provide this to allow your function to access your VPC (if both 'subnet\_ids' and 'security\_group\_ids' are empty then vpc\_config is considered to be empty or unset, see https://docs.aws.amazon.com/lambda/latest/dg/vpc.html for details). | <pre>object({<br>    security_group_ids = list(string)<br>    subnet_ids         = list(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| function\_name | The unique name of your Lambda Function. |
| invoke\_arn | The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws\_api\_gateway\_integration's uri |
| role\_name | The name of the IAM role attached to the Lambda Function. |
| version | Latest published version of your Lambda Function. |

