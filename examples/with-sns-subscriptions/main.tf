#trivy:ignore:AVD-AWS-0135
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "topic_1" {
  kms_master_key_id = "alias/aws/sns"
  name              = "example-sns-topic-1"
}

#trivy:ignore:AVD-AWS-0135
#trivy:ignore:AVD-AWS-0136
resource "aws_sns_topic" "topic_2" {
  kms_master_key_id = "alias/aws/sns"
  name              = "example-sns-topic-2"
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
  function_name    = "example-with-sns-event"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.sns_handler.output_base64sha256

  sns_subscriptions = {
    topic_1 = {
      topic_arn = aws_sns_topic.topic_1.arn

      // optionally overwrite `endpoint` in case an alias should be used for the SNS subscription
      endpoint = aws_lambda_alias.example.arn
    }

    topic_2 = {
      topic_arn = aws_sns_topic.topic_2.arn
    }
  }
}
