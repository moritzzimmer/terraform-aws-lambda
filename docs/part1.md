# AWS Lambda Terraform module

![](https://github.com/moritzzimmer/terraform-aws-lambda/workflows/Terraform%20CI/badge.svg) [![Terraform Module Registry](https://img.shields.io/badge/Terraform%20Module%20Registry-6.1.0-blue.svg)](https://registry.terraform.io/modules/moritzzimmer/lambda/aws/6.1.0) ![Terraform Version](https://img.shields.io/badge/Terraform-0.12+-green.svg) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

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
- [CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html) Log group configuration including retention time and [subscription filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html) with required permissions
to stream logs to other Lambda functions (e.g. forwarding logs to Elasticsearch)
- Lambda@Edge support fulfilling [requirements for CloudFront triggers](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-requirements-limits.html#lambda-requirements-cloudfront-triggers). Functions need
to be deployed to US East (N. Virginia) region (`us-east-1`)
- configuration for [Amazon CloudWatch Lambda Insights](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-insights.html) including required
  permissions and Lambda Layer, see [details](#with-cloudwatch-lambda-insights)
- add-on [module](modules/deployment) for controlled blue/green deployments using AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)
  and [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps-lambda.html) including all required permissions (see [example](examples/deployment)).
  Optionally ignore terraform state changes resulting from those deployments (using `ignore_external_function_updates`).

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
the function role automatically. In addition, permissions to send discarded batches to SNS or SQS will be added automatically, if `destination_arn_on_failure` is configured.

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

      // optionally configure a SNS or SQS destination for discarded batches, required IAM
      // permissions will be added automatically by this module,
      // see https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html
      destination_arn_on_failure = aws_sqs_queue.errors.arn

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
for your Lambda function. It's retention period and [CloudWatch Logs subscription filters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter)
to stream logs to other Lambda functions (e.g. to forward logs to Amazon Elasticsearch Service) can be declared inline.

The module will create the required [Lambda permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) automatically.

see [example](examples/with-cloudwatch-logs-subscription) for details

```hcl
module "lambda" {
  // see above

  cloudwatch_logs_retention_in_days = 14

  cloudwatch_log_subscription_filters = {
    lambda_1 = {
      //see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter for available arguments
      destination_arn = module.destination_1.arn // required
    }

    lambda_2 = {
      destination_arn = module.destination_2.arn // required
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

COPY app.js /var/task/
```

## Deployments

Controlled, blue/green deployments of Lambda functions with (automatic) rollbacks and traffic shifting can be implemented using
Lambda [aliases](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html) and AWS [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html).

The optional [deployment](modules/deployment) submodule can be used to create the required AWS resources and permissions for creating and starting such
CodeDeploy deployments as part of an AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html), see [examples](examples/deployment) for details.

## Examples

- [container-image](examples/container-image)
- [deployment](examples/deployment)
- [simple](examples/simple)
- [with-cloudwatch-event-rules](examples/with-cloudwatch-event-rules)
- [with-cloudwatch-logs-subscription](examples/with-cloudwatch-logs-subscription)
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

## History

Implementation of this module started at [Spring Media/Welt](https://github.com/spring-media/terraform-aws-lambda). Users of `spring-media/lambda/aws`
should migrate to this module as a drop-in replacement to benefit from new features and bugfixes.
