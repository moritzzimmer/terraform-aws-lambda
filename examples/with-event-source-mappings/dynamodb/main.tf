resource "aws_dynamodb_table" "example" {
  name             = "example-dynamodb-table"
  hash_key         = "UserId"
  read_capacity    = 1
  stream_enabled   = true
  stream_view_type = "KEYS_ONLY"
  write_capacity   = 1

  attribute {
    name = "UserId"
    type = "S"
  }

}

data "archive_file" "dynamodb_handler" {
  output_path = "${path.module}/dynamodb.zip"
  type        = "zip"

  source {
    content  = "exports.handler = function(event, context, callback) { console.log(JSON.stringify(event, null, 2)); event.Records.forEach(function(record) { console.log(record.eventID); console.log(record.eventName); console.log('DynamoDB Record: %j', record.dynamodb);  }); callback(null, 'message');  };"
    filename = "index.js"
  }
}

module "lambda" {
  source = "../../.."

  description      = "Example usage for an AWS Lambda with a DynamoDb event source mapping"
  filename         = data.archive_file.dynamodb_handler.output_path
  function_name    = "example-with-dynamodb-event-source-mapping"
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.dynamodb_handler.output_base64sha256

  event_sources = {
    dynamodb = {
      batch_size        = 50 // optionally overwrite default 'batch_size'
      event_source_arn  = aws_dynamodb_table.example.stream_arn
      starting_position = "LATEST" // optionally overwrite default 'starting_position'

      // overwrite function_name in case an alias should be used in the
      // event source mapping, see https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html
      // function_name    = aws_lambda_alias.example.arn
    }
  }
}
