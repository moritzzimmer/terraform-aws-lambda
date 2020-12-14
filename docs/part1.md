# AWS Lambda Terraform module

![](https://github.com/moritzzimmer/terraform-aws-lambda/workflows/Terraform%20CI/badge.svg) [![Terraform Module Registry](https://img.shields.io/badge/Terraform%20Module%20Registry-5.6.1-blue.svg)](https://registry.terraform.io/modules/moritzzimmer/lambda/aws/5.6.1) ![Terraform Version](https://img.shields.io/badge/Terraform-0.12+-green.svg) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

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
  version          = "5.6.1"
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
  version       = "5.6.1"
  function_name = "my-function"
  image_uri     = "111111111111.dkr.ecr.eu-west-1.amazonaws.com/my-image"
  package_type  = "Image"
}
```

**with event trigger**

```hcl
module "lambda" {
  // see above

  event = {
    type                = "cloudwatch-event"
    schedule_expression = "rate(1 minute)"
  }
}
```

**in a VPC**

```hcl
module "lambda" {
  // see above

  vpc_config = {
    security_group_ids = ["sg-1"]
    subnet_ids         = ["subnet-1", "subnet-2"]
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

### Examples

- [container-image](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/container-image)
- [example-with-cloudwatch-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-cloudwatch-event)
- [example-with-dynamodb-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-dynamodb-event)
- [example-with-kinesis-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-kinesis-event)
- [example-with-s3-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-s3-event)
- [example-with-sns-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-sns-event)
- [example-with-sqs-event](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-sqs-event)
- [example-with-ssm-permissions](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-ssm-permissions)
- [example-with-vpc](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/example-with-vpc)
- [simple](https://github.com/moritzzimmer/terraform-aws-lambda/tree/master/examples/simple)

### bootstrap with func

In case you are using [go](https://golang.org/) for developing your Lambda functions, you can also use [func](https://github.com/moritzzimmer/func) to bootstrap your project and get started quickly.

## How do I contribute to this module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/moritzzimmer/terraform-aws-lambda/blob/master/CONTRIBUTING.md) for instructions.

## How is this module versioned?

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release in the [releases page](../../releases).

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR,
MINOR, and PATCH versions on each release to indicate any incompatibilities.
