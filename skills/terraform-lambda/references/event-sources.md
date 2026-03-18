# Event Source Reference

How to wire each event source type to a Lambda function using the
terraform-aws-lambda module. The module handles IAM permissions automatically
for all event source types listed here.

## Table of Contents

- [No event source (invoke manually / API Gateway)](#no-event-source)
- [SQS](#sqs)
- [SNS](#sns)
- [DynamoDB Streams](#dynamodb-streams)
- [Kinesis](#kinesis)
- [CloudWatch Events / EventBridge](#cloudwatch-events--eventbridge)
- [S3](#s3)
- [API Gateway](#api-gateway)

---

## No event source

The simplest case — no event trigger. The function is invoked via the AWS CLI,
SDK, or another service like API Gateway (configured separately).

```hcl
module "my_function" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  architectures    = ["arm64"]
  description      = "My Lambda function"
  filename         = local.artifact
  function_name    = "my-function"
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  source_code_hash = fileexists(local.artifact) ? filebase64sha256(local.artifact) : null
  timeout          = 30

  tags = {
    managed_by = "terraform"
  }
}
```

---

## SQS

The module creates the event source mapping and attaches SQS read permissions
(`sqs:ReceiveMessage`, `sqs:DeleteMessage`, etc.) automatically.

```hcl
resource "aws_sqs_queue" "orders" {
  name = "orders-queue"
}

module "order_processor" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  # ... core settings ...

  event_source_mappings = {
    orders = {
      event_source_arn = aws_sqs_queue.orders.arn
    }
  }
}
```

### SQS with batch settings and DLQ

```hcl
resource "aws_sqs_queue" "dlq" {
  name = "orders-dlq"
}

resource "aws_sqs_queue" "orders" {
  name = "orders-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

module "order_processor" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  # ... core settings ...

  event_source_mappings = {
    orders = {
      batch_size                         = 10
      event_source_arn                   = aws_sqs_queue.orders.arn
      maximum_batching_window_in_seconds = 60
    }
  }
}
```

---

## SNS

The module creates SNS subscriptions and Lambda invoke permissions.

```hcl
resource "aws_sns_topic" "notifications" {
  name = "user-notifications"
}

module "notifier" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  # ... core settings ...

  sns_subscriptions = {
    notifications = {
      topic_arn = aws_sns_topic.notifications.arn
    }
  }
}
```

### SNS with filter policy

```hcl
sns_subscriptions = {
  notifications = {
    topic_arn     = aws_sns_topic.notifications.arn
    filter_policy = jsonencode({
      event_type = ["order_placed", "order_shipped"]
    })
  }
}
```

---

## DynamoDB Streams

The module attaches DynamoDB Streams read permissions automatically.

```hcl
resource "aws_dynamodb_table" "users" {
  name             = "users"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "UserId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "UserId"
    type = "S"
  }
}

module "user_stream_processor" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  # ... core settings ...

  event_source_mappings = {
    users = {
      event_source_arn  = aws_dynamodb_table.users.stream_arn
      starting_position = "LATEST"
    }
  }
}
```

---

## Kinesis

The module attaches Kinesis read permissions. For enhanced fan-out,
it also adds `kinesis:SubscribeToShard`.

```hcl
resource "aws_kinesis_stream" "events" {
  name        = "events-stream"
  shard_count = 1
}

module "event_processor" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  # ... core settings ...

  event_source_mappings = {
    events = {
      event_source_arn  = aws_kinesis_stream.events.arn
      starting_position = "LATEST"
    }
  }
}
```

### Kinesis with batching and bisect-on-error

```hcl
event_source_mappings = {
  events = {
    batch_size                         = 100
    bisect_batch_on_function_error     = true
    event_source_arn                   = aws_kinesis_stream.events.arn
    maximum_batching_window_in_seconds = 15
    maximum_retry_attempts             = 3
    parallelization_factor             = 2
    starting_position                  = "LATEST"
  }
}
```

---

## CloudWatch Events / EventBridge

The module creates EventBridge rules and Lambda invoke permissions.

### Scheduled (cron/rate)

```hcl
module "cron_job" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  # ... core settings ...

  cloudwatch_event_rules = {
    every_5_minutes = {
      schedule_expression = "rate(5 minutes)"
    }
  }
}
```

### Event pattern

```hcl
cloudwatch_event_rules = {
  ec2_state_change = {
    event_pattern = jsonencode({
      source      = ["aws.ec2"]
      detail-type = ["EC2 Instance State-change Notification"]
      detail = {
        state = ["stopped", "terminated"]
      }
    })
  }
}
```

### Multiple rules on one function

```hcl
cloudwatch_event_rules = {
  hourly = {
    schedule_expression = "rate(1 hour)"
  }
  on_deploy = {
    event_pattern = jsonencode({
      source      = ["aws.codedeploy"]
      detail-type = ["CodeDeploy Deployment State-change Notification"]
    })
  }
}
```

---

## S3

S3 event notifications are not directly managed by the module's variables.
Create the notification resource yourself and grant invoke permission:

```hcl
resource "aws_lambda_permission" "s3" {
  action        = "lambda:InvokeFunction"
  function_name = module.image_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
  statement_id  = "AllowS3Invoke"
}

resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    events              = ["s3:ObjectCreated:*"]
    lambda_function_arn = module.image_processor.arn
  }

  depends_on = [aws_lambda_permission.s3]
}
```

---

## API Gateway

API Gateway integration is not part of the module — create it separately
and reference the module's `invoke_arn` output:

```hcl
resource "aws_apigatewayv2_api" "api" {
  name          = "my-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.my_function.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigw" {
  action        = "lambda:InvokeFunction"
  function_name = module.my_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
  statement_id  = "AllowAPIGatewayInvoke"
}
```
