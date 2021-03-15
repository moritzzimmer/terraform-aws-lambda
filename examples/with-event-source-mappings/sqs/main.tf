resource "aws_sqs_queue" "queue_1" {
  name = "example-sqs-queue-1"
}

resource "aws_sqs_queue" "queue_2" {
  name = "example-sqs-queue-2"
}

data "archive_file" "sqs_handler" {
  output_path = "${path.module}/sqs.zip"
  type        = "zip"

  source {
    content  = "exports.handler = async function(event, context) { event.Records.forEach(record => { const { body } = record; console.log(body);  }); return {}; }"
    filename = "index.js"
  }
}

module "lambda" {
  source = "../../.."

  description      = "Example usage for an AWS Lambda with a SQS event source mapping"
  filename         = data.archive_file.sqs_handler.output_path
  function_name    = "example-with-sqs-event-source-mapping"
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = data.archive_file.sqs_handler.output_base64sha256

  event_source_mappings = {
    queue_1 = {
      // optionally overwrite arguments like 'batch_size'
      // from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping
      batch_size       = 5
      event_source_arn = aws_sqs_queue.queue_1.arn

      // optionally overwrite function_name in case an alias should be used in the
      // event source mapping, see https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html
      // function_name    = aws_lambda_alias.example.arn
    }

    queue_2 = {
      event_source_arn = aws_sqs_queue.queue_2.arn
    }
  }
}
