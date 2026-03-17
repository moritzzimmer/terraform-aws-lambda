# Event Sources Reference

Patterns for connecting AWS event sources to Lambda functions using the terraform-aws-lambda module.

## Table of Contents
- [SQS Queue](#sqs-queue)
- [DynamoDB Stream](#dynamodb-stream)
- [Kinesis Stream](#kinesis-stream)
- [SNS Topic](#sns-topic)
- [EventBridge (CloudWatch Events)](#eventbridge)
- [CloudWatch Log Subscriptions](#cloudwatch-log-subscriptions)
- [API Gateway](#api-gateway)
- [S3 Notifications](#s3-notifications)

---

## SQS Queue

Managed via `event_source_mappings`. The module automatically grants SQS read/delete permissions.

```hcl
module "lambda" {
  # ... core config ...

  event_source_mappings = {
    sqs-orders = {
      event_source_arn                   = aws_sqs_queue.orders.arn
      batch_size                         = 10
      maximum_batching_window_in_seconds = 5
      function_response_types            = ["ReportBatchItemFailures"]
    }
  }
}
```

**With dead-letter queue for failed messages:**

```hcl
event_source_mappings = {
  sqs-orders = {
    event_source_arn                   = aws_sqs_queue.orders.arn
    batch_size                         = 10
    function_response_types            = ["ReportBatchItemFailures"]
    destination_arn_on_failure         = aws_sqs_queue.orders_dlq.arn
  }
}
```

**With message filtering (process only specific messages):**

```hcl
event_source_mappings = {
  sqs-orders = {
    event_source_arn = aws_sqs_queue.orders.arn
    batch_size       = 10

    filter_criteria = {
      filter = [
        {
          pattern = jsonencode({
            body = {
              type = ["order.created"]
            }
          })
        }
      ]
    }
  }
}
```

**IAM permissions granted automatically:**
- `sqs:ReceiveMessage`
- `sqs:DeleteMessage`, `sqs:DeleteMessageBatch`
- `sqs:ChangeMessageVisibility`, `sqs:ChangeMessageVisibilityBatch`
- `sqs:GetQueueAttributes`
- `sqs:SendMessage` (only if `destination_arn_on_failure` points to SQS)

---

## DynamoDB Stream

Managed via `event_source_mappings`. The module automatically grants DynamoDB Streams read permissions.

```hcl
module "lambda" {
  # ... core config ...

  event_source_mappings = {
    dynamodb-users = {
      event_source_arn  = aws_dynamodb_table.users.stream_arn
      starting_position = "TRIM_HORIZON"
      batch_size        = 100

      # Retry configuration
      maximum_retry_attempts         = 3
      maximum_record_age_in_seconds  = 86400
      bisect_batch_on_function_error = true

      destination_arn_on_failure = aws_sqs_queue.dlq.arn
    }
  }
}
```

**With a Lambda alias (for blue-green deployments):**

```hcl
event_source_mappings = {
  dynamodb-users = {
    event_source_arn  = aws_dynamodb_table.users.stream_arn
    function_name     = "${module.lambda.arn}:live"  # alias qualifier
    starting_position = "TRIM_HORIZON"
  }
}
```

**IAM permissions granted automatically:**
- `dynamodb:DescribeStream`
- `dynamodb:GetShardIterator`
- `dynamodb:GetRecords`
- `dynamodb:ListStreams`

---

## Kinesis Stream

Managed via `event_source_mappings`. The module automatically grants Kinesis read permissions.

```hcl
module "lambda" {
  # ... core config ...

  event_source_mappings = {
    kinesis-clickstream = {
      event_source_arn          = aws_kinesis_stream.clickstream.arn
      starting_position         = "TRIM_HORIZON"
      batch_size                = 100
      parallelization_factor    = 2

      maximum_retry_attempts        = 5
      maximum_record_age_in_seconds = 3600
      bisect_batch_on_function_error = true

      destination_arn_on_failure = aws_sns_topic.alerts.arn
    }
  }
}
```

**With enhanced fan-out (dedicated throughput):**

```hcl
event_source_mappings = {
  kinesis-clickstream = {
    event_source_arn  = aws_kinesis_stream_consumer.dedicated.arn
    starting_position = "TRIM_HORIZON"
    batch_size        = 100
  }
}
```

The module detects consumer ARNs and additionally grants `kinesis:SubscribeToShard`.

**With scaling limits:**

```hcl
event_source_mappings = {
  kinesis-clickstream = {
    event_source_arn  = aws_kinesis_stream.clickstream.arn
    starting_position = "TRIM_HORIZON"

    scaling_config = {
      maximum_concurrency = 10
    }
  }
}
```

**IAM permissions granted automatically:**
- `kinesis:ListStreams`, `kinesis:DescribeLimits`
- `kinesis:DescribeStream`, `kinesis:DescribeStreamSummary`
- `kinesis:GetRecords`, `kinesis:GetShardIterator`
- `kinesis:ListShards`
- `kinesis:SubscribeToShard` (only for enhanced fan-out consumers)

---

## SNS Topic

Managed via `sns_subscriptions`. Creates both the subscription and the Lambda invoke permission.

```hcl
module "lambda" {
  # ... core config ...

  sns_subscriptions = {
    notifications = {
      topic_arn = aws_sns_topic.notifications.arn
    }
  }
}
```

**Multiple subscriptions:**

```hcl
sns_subscriptions = {
  user-events = {
    topic_arn = aws_sns_topic.user_events.arn
  }
  system-alerts = {
    topic_arn = aws_sns_topic.system_alerts.arn
  }
}
```

**With a Lambda alias:**

```hcl
sns_subscriptions = {
  notifications = {
    topic_arn = aws_sns_topic.notifications.arn
    endpoint  = "${module.lambda.arn}:live"
  }
}
```

**With dead-letter queue:**

```hcl
sns_subscriptions = {
  notifications = {
    topic_arn      = aws_sns_topic.notifications.arn
    redrive_policy = jsonencode({
      deadLetterTargetArn = aws_sqs_queue.dlq.arn
    })
  }
}
```

---

## EventBridge

Managed via `cloudwatch_event_rules`. Creates the rule, target, and Lambda invoke permission.

**Scheduled execution (cron):**

```hcl
module "lambda" {
  # ... core config ...

  cloudwatch_event_rules = {
    daily-cleanup = {
      schedule_expression = "rate(1 day)"
      description         = "Run cleanup daily"
    }
  }
}
```

**Event pattern matching:**

```hcl
cloudwatch_event_rules = {
  ec2-state-change = {
    event_pattern = jsonencode({
      source      = ["aws.ec2"]
      detail-type = ["EC2 Instance State-change Notification"]
      detail = {
        state = ["stopped", "terminated"]
      }
    })
    description = "React to EC2 instance state changes"
  }
}
```

**With custom input to Lambda:**

```hcl
cloudwatch_event_rules = {
  hourly-check = {
    schedule_expression          = "rate(1 hour)"
    cloudwatch_event_target_input = jsonencode({
      action = "health-check"
      env    = "production"
    })
  }
}
```

**With a Lambda alias:**

```hcl
cloudwatch_event_rules = {
  daily-cleanup = {
    schedule_expression         = "rate(1 day)"
    cloudwatch_event_target_arn = "${module.lambda.arn}:live"
  }
}
```

**Common schedule expressions:**
- `rate(1 minute)`, `rate(5 minutes)`, `rate(1 hour)`, `rate(1 day)`
- `cron(0 12 * * ? *)` — daily at noon UTC
- `cron(0/15 * * * ? *)` — every 15 minutes
- `cron(0 8 ? * MON-FRI *)` — weekdays at 8am UTC

---

## CloudWatch Log Subscriptions

Managed via `cloudwatch_log_subscription_filters`. Sends log events from a CloudWatch Log Group to a Lambda function.

```hcl
module "lambda" {
  # ... core config ...

  cloudwatch_log_subscription_filters = {
    app-errors = {
      destination_arn = module.log_processor.arn
      filter_pattern  = "ERROR"
    }
  }
}
```

**Notes:**
- The `destination_arn` is the ARN of the *receiving* Lambda, not the one being configured
- `filter_pattern` uses CloudWatch Logs filter syntax
- Empty `filter_pattern` forwards all log events

---

## API Gateway

API Gateway integration is NOT managed by this module. Set it up separately and use the module's `invoke_arn` output:

```hcl
# API Gateway v2 (HTTP API)
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda.invoke_arn
  payload_format_version = "2.0"
}

# Grant API Gateway permission to invoke Lambda
resource "aws_lambda_permission" "apigw" {
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
```

---

## S3 Notifications

S3 event notifications are NOT managed by this module. Set them up separately:

```hcl
resource "aws_lambda_permission" "s3" {
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}

resource "aws_s3_bucket_notification" "lambda" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = module.lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.s3]
}
```
