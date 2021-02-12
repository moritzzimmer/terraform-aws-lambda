resource "aws_kinesis_stream" "stream_1" {
  name        = "example-kinesis-stream-1"
  shard_count = 1
}

resource "aws_kinesis_stream" "stream_2" {
  name        = "example-kinesis-stream-2"
  shard_count = 1
}

data "archive_file" "kinesis_handler" {
  output_path = "${path.module}/kinesis.zip"
  type        = "zip"

  source {
    content  = "exports.handler = function(event, context) { console.log(JSON.stringify(event, null, 2)); event.Records.forEach(function(record) { var payload = Buffer.from(record.kinesis.data, 'base64').toString('ascii'); console.log('Decoded payload:', payload); }); };"
    filename = "index.js"
  }
}

module "lambda" {
  source = "../../.."

  description      = "Example usage for an AWS Lambda with a Kinesis event source mapping"
  filename         = data.archive_file.kinesis_handler.output_path
  function_name    = "example-with-kinesis-event-source-mapping"
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = data.archive_file.kinesis_handler.output_base64sha256

  event_source_mappings = {
    stream_1 = {
      // optionally overwrite arguments like 'batch_size'
      // from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping
      batch_size       = 50
      event_source_arn = aws_kinesis_stream.stream_1.arn

      // optionally overwrite function_name in case an alias should be used in the
      // event source mapping, see https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html
      // function_name    = aws_lambda_alias.example.arn
    }

    stream_2 = {
      event_source_arn  = aws_kinesis_stream.stream_2.arn
      starting_position = "LATEST" // optionally overwrite default 'starting_position'
    }
  }
}
