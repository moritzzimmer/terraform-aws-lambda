module "fixtures" {
  source = "../../fixtures"
}

#trivy:ignore:AVD-AWS-0135
resource "aws_sqs_queue" "queue_1" {
  kms_master_key_id = "alias/aws/sqs"
  name              = "example-sqs-queue-1"
}

#trivy:ignore:AVD-AWS-0135
resource "aws_sqs_queue" "queue_2" {
  kms_master_key_id = "alias/aws/sqs"
  name              = "example-sqs-queue-2"
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
  function_name    = module.fixtures.output_function_name
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  source_code_hash = data.archive_file.sqs_handler.output_base64sha256

  event_source_mappings = {
    queue_1 = {
      event_source_arn = aws_sqs_queue.queue_1.arn

      // optionally overwrite function_name in case an alias should be used in the
      // event source mapping, see https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html
      // function_name    = aws_lambda_alias.example.arn

      // optionally overwrite arguments from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping
      batch_size = 5

      // Lambda event filtering, see https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventfiltering.html
      filter_criteria = [
        {
          pattern = jsonencode({
            body : {
              Key1 : ["Value1"]
            }
          })
        },
        {
          pattern = jsonencode({
            body : {
              Key2 : [{ "anything-but" : ["Value2"] }]
            }
          })
        }
      ]

      // Event source mapping metrics, see https://docs.aws.amazon.com/lambda/latest/dg/monitoring-metrics-types.html#event-source-mapping-metrics
      metrics_config = {
        metrics = ["EventCount"]
      }

      scaling_config = {
        maximum_concurrency = 2
      }
    }

    queue_2 = {
      event_source_arn = aws_sqs_queue.queue_2.arn
    }
  }
}
