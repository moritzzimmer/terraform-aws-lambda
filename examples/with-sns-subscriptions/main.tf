data "aws_caller_identity" "current" {}

module "fixtures" {
  source = "../fixtures"
}

// see https://docs.aws.amazon.com/sns/latest/dg/sns-dead-letter-queues.html
// for using encrypted SNS topics with SQS DLQs
resource "aws_kms_key" "kms_key_sqs_sns" {
  description = "Customer KMS key for SQS and SNS"
  policy      = data.aws_iam_policy_document.kms_sqs_sns.json
}

resource "aws_kms_alias" "kms_alias_sqs_sns" {
  target_key_id = aws_kms_key.kms_key_sqs_sns.key_id
  name          = "alias/sns_sqs"
}

data "aws_iam_policy_document" "kms_sqs_sns" {
  statement {
    sid       = "Allow access for Key Administrators"
    effect    = "Allow"
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com", "sqs.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]

  }

  statement {
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

#trivy:ignore:AVD-AWS-0135
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "topic_1" {
  kms_master_key_id = aws_kms_alias.kms_alias_sqs_sns.name
  name              = "example-sns-topic-1"
}

#trivy:ignore:AVD-AWS-0135
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "topic_2" {
  kms_master_key_id = "alias/aws/sns"
  name              = "example-sns-topic-2"
}

resource "aws_sqs_queue" "sqs_dlq_topic_1" {
  name              = "example-sqs-dlq-topic-1"
  kms_master_key_id = aws_kms_alias.kms_alias_sqs_sns.name
}

resource "aws_sqs_queue_policy" "sqs_dlq_topic_1" {
  policy    = data.aws_iam_policy_document.sqs_access_policy.json
  queue_url = aws_sqs_queue.sqs_dlq_topic_1.id
}

// see https://docs.aws.amazon.com/sns/latest/dg/sns-configure-dead-letter-queue.html
data "aws_iam_policy_document" "sqs_access_policy" {
  statement {
    actions   = ["sqs:SendMessage"]
    effect    = "Allow"
    resources = [aws_sqs_queue.sqs_dlq_topic_1.arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_sns_topic.topic_1.arn
      ]
    }
  }
}

resource "aws_lambda_alias" "example" {
  function_name    = module.lambda.function_name
  function_version = module.lambda.version
  name             = "prod"
}

data "archive_file" "sns_handler" {
  output_path = "${path.module}/sns.zip"
  type        = "zip"

  source {
    content  = "exports.handler = function(event, context, callback) { var message = event.Records[0].Sns.Message; console.log('Message received from SNS:', message); callback(null, 'Success');};"
    filename = "index.js"
  }
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with a SNS event trigger."
  filename         = data.archive_file.sns_handler.output_path
  function_name    = module.fixtures.output_function_name
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  source_code_hash = data.archive_file.sns_handler.output_base64sha256

  sns_subscriptions = {
    topic_1 = {
      topic_arn = aws_sns_topic.topic_1.arn

      // optionally overwrite `endpoint` in case an alias should be used for the SNS subscription
      endpoint = aws_lambda_alias.example.arn

      // optionally configure a dead letter queue for the SNS subscription
      redrive_policy = jsonencode({
        deadLetterTargetArn = aws_sqs_queue.sqs_dlq_topic_1.arn,
      })
    }

    topic_2 = {
      topic_arn = aws_sns_topic.topic_2.arn
    }
  }
}
