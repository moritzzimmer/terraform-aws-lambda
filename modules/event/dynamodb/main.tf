data "aws_region" "current" {
  count = var.enable ? 1 : 0
}

resource "aws_lambda_event_source_mapping" "stream_source" {
  count                               = var.enable ? 1 : 0
  batch_size                          = var.batch_size
  bisect_batch_on_function_error      = var.bisect_batch_on_function_error
  destination_config                  = var.destination_config
  enabled                             = var.event_source_mapping_enabled
  event_source_arn                    = var.event_source_arn
  function_name                       = var.function_name
  maximum_batching_window_in_seconds  = var.maximum_batching_window_in_seconds
  maximum_record_age_in_seconds       = var.maximum_record_age_in_seconds
  maximum_retry_attempts              = var.maximum_retry_attempts
  parallelization_factor              = var.parallelization_factor
  starting_position                   = var.starting_position
  starting_position_timestamp         = var.starting_position_timestamp
  topics                              = var.topics
}

// see https://github.com/awslabs/serverless-application-model/blob/develop/samtranslator/policy_templates_data/policy_templates.json
data "aws_iam_policy_document" "stream_policy_document" {
  count = var.enable ? 1 : 0

  statement {
    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetShardIterator",
      "dynamodb:GetRecords"
    ]

    resources = [
      var.event_source_arn
    ]
  }
}

resource "aws_iam_policy" "stream_policy" {
  count       = var.enable ? 1 : 0
  name        = "${var.function_name}-stream-consumer-${data.aws_region.current[count.index].name}"
  description = "Provides minimum DynamoDb stream processing permissions for ${var.function_name}."
  policy      = data.aws_iam_policy_document.stream_policy_document[count.index].json
}

resource "aws_iam_role_policy_attachment" "stream_policy_attachment" {
  count      = var.enable ? 1 : 0
  role       = var.iam_role_name
  policy_arn = aws_iam_policy.stream_policy[count.index].arn
}
