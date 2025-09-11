module "fixtures" {
  source = "../../fixtures"
}

resource "aws_dynamodb_table" "table_1" {
  name             = "example-dynamodb-table-1"
  hash_key         = "UserId"
  read_capacity    = 1
  stream_enabled   = true
  stream_view_type = "KEYS_ONLY"
  write_capacity   = 1

  attribute {
    name = "UserId"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}

resource "aws_dynamodb_table" "table_2" {
  name             = "example-dynamodb-table-2"
  hash_key         = "UserId"
  read_capacity    = 1
  stream_enabled   = true
  stream_view_type = "KEYS_ONLY"
  write_capacity   = 1

  attribute {
    name = "UserId"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}

resource "aws_lambda_alias" "example" {
  function_name    = module.lambda.function_name
  function_version = module.lambda.version
  name             = "prod"
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
  function_name    = module.fixtures.output_function_name
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  source_code_hash = data.archive_file.dynamodb_handler.output_base64sha256

  event_source_mappings = {
    table_1 = {
      event_source_arn = aws_dynamodb_table.table_1.stream_arn

      // optionally overwrite function_name in case an alias should be used in the
      // event source mapping, see https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html
      function_name = aws_lambda_alias.example.arn

      // optionally overwrite arguments from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping
      batch_size             = 50
      maximum_retry_attempts = 3

      // optionally configure a SNS or SQS destination for discarded batches, required IAM
      // permissions will be added automatically by this module,
      // see https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html
      destination_arn_on_failure = aws_sqs_queue.errors.arn

      // Lambda event filtering, see https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventfiltering.html
      filter_criteria = [
        {
          pattern = jsonencode({
            data : {
              Key1 : ["Value1"]
            }
          })
        },
        {
          pattern = jsonencode({
            data : {
              Key2 : [{ "anything-but" : ["Value2"] }]
            }
          })
        }
      ]

      // Event source mapping metrics, see https://docs.aws.amazon.com/lambda/latest/dg/monitoring-metrics-types.html#event-source-mapping-metrics
      metrics_config = {
        metrics = ["EventCount"]
      }
    }

    table_2 = {
      event_source_arn = aws_dynamodb_table.table_2.stream_arn
      function_name    = aws_lambda_alias.example.arn
    }
  }
}

#trivy:ignore:AVD-AWS-0135
resource "aws_sqs_queue" "errors" {
  kms_master_key_id = "alias/aws/sqs"
  name              = "${module.lambda.function_name}-processing-errors"
}
