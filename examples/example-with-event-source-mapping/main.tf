resource "aws_sqs_queue" "example" {
  name = "example-sqs-queue"
}

data "archive_file" "sqs_handler" {
  output_path = "${path.module}/sqs.zip"
  type        = "zip"

  source {
    content  = "exports.handler = async function(event, context) { event.Records.forEach(record => { const { body } = record; console.log(body);  }); return {}; }"
    filename = "index.js"
  }
}

module "sqs" {
  source = "../../"

  description      = "Example usage for an AWS Lambda with a SQS event source mapping"
  filename         = data.archive_file.sqs_handler.output_path
  function_name    = "example-with-sqs-event-source-mapping"
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.sqs_handler.output_base64sha256

  event_sources = {
    sqs = {
      batch_size       = 5 // optionally overwrite default 'batch_size'
      event_source_arn = aws_sqs_queue.example.arn

      // overwrite function_name in case an alias should be used in the
      // event source mapping, see https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html
      // function_name    = aws_lambda_alias.example.arn
    }
  }
}
