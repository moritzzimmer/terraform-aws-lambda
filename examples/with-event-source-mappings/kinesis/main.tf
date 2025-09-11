module "fixtures" {
  source = "../../fixtures"
}

resource "aws_kinesis_stream" "stream_1" {
  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"
  name            = "example-kinesis-stream-1"
  shard_count     = 1
}

resource "aws_kinesis_stream" "stream_2" {
  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"
  name            = "example-kinesis-stream-2"
  shard_count     = 1
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
  function_name    = module.fixtures.output_function_name
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  source_code_hash = data.archive_file.kinesis_handler.output_base64sha256

  event_source_mappings = {
    stream_1 = {
      event_source_arn = aws_kinesis_stream.stream_1.arn

      // optionally overwrite function_name in case an alias should be used in the
      // event source mapping, see https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html
      // function_name    = aws_lambda_alias.example.arn

      // optionally overwrite arguments from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping
      batch_size        = 50
      starting_position = "LATEST" // optionally overwrite default 'starting_position'

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

    stream_2 = {
      // To use a dedicated-throughput consumer with enhanced fan-out, specify the consumer's ARN instead of the stream's ARN, see https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html#services-kinesis-configure
      event_source_arn = aws_kinesis_stream_consumer.this.arn
    }
  }
}

resource "aws_kinesis_stream_consumer" "this" {
  name       = module.lambda.function_name
  stream_arn = aws_kinesis_stream.stream_2.arn
}

