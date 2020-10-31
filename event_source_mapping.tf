locals {
  dynamodb_event_sources = [for k, v in var.event_sources : lookup(v, "event_source_arn", null) if length(regexall(".*:dynamodb:.*", lookup(v, "event_source_arn", null))) > 0]
  kinesis_event_sources  = [for k, v in var.event_sources : lookup(v, "event_source_arn", null) if length(regexall(".*:kinesis:.*", lookup(v, "event_source_arn", null))) > 0]
  sqs_event_sources      = [for k, v in var.event_sources : lookup(v, "event_source_arn", null) if length(regexall(".*:sqs:.*", lookup(v, "event_source_arn", null))) > 0]
}

resource "aws_lambda_event_source_mapping" "event_source" {
  for_each = var.event_sources

  batch_size                         = lookup(each.value, "batch_size", null)
  bisect_batch_on_function_error     = lookup(each.value, "bisect_batch_on_function_error", null)
  enabled                            = lookup(each.value, "enabled", null)
  event_source_arn                   = lookup(each.value, "event_source_arn", null)
  function_name                      = lookup(each.value, "function_name", var.function_name)
  maximum_batching_window_in_seconds = lookup(each.value, "maximum_batching_window_in_seconds", null)
  maximum_retry_attempts             = lookup(each.value, "maximum_retry_attempts", null)
  maximum_record_age_in_seconds      = lookup(each.value, "maximum_record_age_in_seconds", null)
  parallelization_factor             = lookup(each.value, "parallelization_factor", null)
  starting_position                  = lookup(each.value, "starting_position", length(regexall(".*:dynamodb:.*", lookup(each.value, "event_source_arn", null))) > 0 ? "TRIM_HORIZON" : null)
  starting_position_timestamp        = lookup(each.value, "starting_position_timestamp", null)
}

// type specific minimal permissions for supported event_sources,
// see https://github.com/awslabs/serverless-application-model/blob/develop/samtranslator/policy_templates_data/policy_templates.json
data "aws_iam_policy_document" "event_sources" {
  count = length(var.event_sources) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = local.sqs_event_sources
    content {
      actions = [
        "sqs:ChangeMessageVisibility",
        "sqs:ChangeMessageVisibilityBatch",
        "sqs:DeleteMessage",
        "sqs:DeleteMessageBatch",
        "sqs:GetQueueAttributes",
        "sqs:ReceiveMessage"
      ]

      resources = [statement.value]
    }
  }

  dynamic "statement" {
    for_each = local.dynamodb_event_sources
    content {
      actions = [
        "dynamodb:DescribeStream",
        "dynamodb:GetShardIterator",
        "dynamodb:GetRecords",
        "dynamodb:ListStreams"
      ]

      resources = [statement.value]
    }
  }

  dynamic "statement" {
    for_each = local.kinesis_event_sources
    content {
      actions = [
        "kinesis:ListStreams",
        "kinesis:DescribeLimits"
      ]

      resources = [
        // extracting 'arn:${Partition}:kinesis:${Region}:${Account}:stream/' from the kinesis stream ARN
        // see https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonkinesis.html#amazonkinesis-resources-for-iam-policies
        length(regexall("arn.*\\/", statement.value)) > 0 ? "${regex("arn.*\\/", statement.value)}*" : ""
      ]
    }
  }

  dynamic "statement" {
    for_each = local.kinesis_event_sources
    content {
      actions = [
        "kinesis:DescribeStream",
        "kinesis:DescribeStreamSummary",
        "kinesis:GetRecords",
        "kinesis:GetShardIterator"
      ]

      resources = [statement.value]
    }
  }
}

resource "aws_iam_policy" "event_sources" {
  count  = length(var.event_sources) > 0 ? 1 : 0
  policy = data.aws_iam_policy_document.event_sources[count.index].json
}

resource "aws_iam_role_policy_attachment" "event_sources" {
  count      = length(var.event_sources) > 0 ? 1 : 0
  role       = module.lambda.role_name
  policy_arn = aws_iam_policy.event_sources[count.index].arn
}
