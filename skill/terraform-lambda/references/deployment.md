# Deployment Pipeline Reference

Set up blue-green deployments for Lambda using CodeDeploy and CodePipeline via the `modules/deployment/` submodule.

## Overview

The deployment submodule creates a full CI/CD pipeline:

1. **Source stage** — Triggered by ECR image push (container) or S3 object creation (zip)
2. **Update stage** — CodeBuild updates the Lambda function code
3. **Deploy stage** — CodeDeploy shifts traffic from old to new version using aliases

## Prerequisites

The Lambda module must be configured for external deployments:

```hcl
module "lambda" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  function_name                    = "my-function"
  ignore_external_function_updates = true  # Terraform won't fight CodeDeploy
  publish                          = true  # Required for versioning/aliases

  # ... rest of config
}
```

## Basic Setup

### Zip deployment (S3 source)

```hcl
module "deployment" {
  source = "moritzzimmer/lambda/aws//modules/deployment"

  alias_name    = "live"
  function_name = module.lambda.function_name

  s3_bucket = "my-deployment-bucket"
  s3_key    = "lambda/my-function.zip"
}
```

### Container image deployment (ECR source)

```hcl
module "deployment" {
  source = "moritzzimmer/lambda/aws//modules/deployment"

  alias_name    = "live"
  function_name = module.lambda.function_name

  ecr_image_uri = "${aws_ecr_repository.this.repository_url}:latest"
  ecr_repository_name = aws_ecr_repository.this.name
}
```

## Traffic Shifting Strategies

CodeDeploy supports several deployment configurations:

| Config | Behavior |
|--------|----------|
| `CodeDeployDefault.LambdaAllAtOnce` | Immediate shift (default) |
| `CodeDeployDefault.LambdaLinear10PercentEvery1Minute` | 10% every minute |
| `CodeDeployDefault.LambdaLinear10PercentEvery2Minutes` | 10% every 2 minutes |
| `CodeDeployDefault.LambdaLinear10PercentEvery3Minutes` | 10% every 3 minutes |
| `CodeDeployDefault.LambdaLinear10PercentEvery10Minutes` | 10% every 10 minutes |
| `CodeDeployDefault.LambdaCanary10Percent5Minutes` | 10% for 5min, then 100% |
| `CodeDeployDefault.LambdaCanary10Percent10Minutes` | 10% for 10min, then 100% |
| `CodeDeployDefault.LambdaCanary10Percent15Minutes` | 10% for 15min, then 100% |
| `CodeDeployDefault.LambdaCanary10Percent30Minutes` | 10% for 30min, then 100% |

## Auto-Rollback with Alarms

```hcl
module "deployment" {
  source = "moritzzimmer/lambda/aws//modules/deployment"

  alias_name    = "live"
  function_name = module.lambda.function_name

  deployment_config_name = "CodeDeployDefault.LambdaCanary10Percent5Minutes"

  # Rollback if error rate spikes during deployment
  alarm_configuration = {
    alarms  = [aws_cloudwatch_metric_alarm.lambda_errors.alarm_name]
    enabled = true
  }
}
```

## Event Sources with Aliases

When using deployment pipelines, point event sources at the alias (not `$LATEST`):

```hcl
module "lambda" {
  # ... core config ...

  event_source_mappings = {
    sqs-orders = {
      event_source_arn = aws_sqs_queue.orders.arn
      function_name    = "${module.lambda.arn}:live"  # alias
    }
  }

  cloudwatch_event_rules = {
    daily = {
      schedule_expression         = "rate(1 day)"
      cloudwatch_event_target_arn = "${module.lambda.arn}:live"
    }
  }

  sns_subscriptions = {
    notifications = {
      topic_arn = aws_sns_topic.this.arn
      endpoint  = "${module.lambda.arn}:live"
    }
  }
}
```

## Pipeline Notifications

```hcl
module "deployment" {
  # ... base config ...

  codestar_notifications = {
    detail_type = "FULL"
    event_type_ids = [
      "codepipeline-pipeline-pipeline-execution-started",
      "codepipeline-pipeline-pipeline-execution-failed",
      "codepipeline-pipeline-pipeline-execution-succeeded",
    ]
    target_address = aws_sns_topic.pipeline_notifications.arn
  }
}
```
