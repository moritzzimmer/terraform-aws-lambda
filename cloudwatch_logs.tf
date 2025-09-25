locals {
  log_group_name = coalesce(try(var.logging_config.log_group, null), "/aws/lambda/${var.lambda_at_edge ? "us-east-1." : ""}${var.function_name}")
  log_group_arn  = try(data.aws_cloudwatch_log_group.lambda[0].arn, aws_cloudwatch_log_group.lambda[0].arn, "")
}

data "aws_cloudwatch_log_group" "lambda" {
  count = var.create_cloudwatch_log_group ? 0 : 1

  region = var.region

  name = local.log_group_name
}

resource "aws_cloudwatch_log_group" "lambda" {
  count = var.create_cloudwatch_log_group ? 1 : 0

  region = var.region

  name              = local.log_group_name
  log_group_class   = var.cloudwatch_logs_log_group_class
  retention_in_days = var.cloudwatch_logs_retention_in_days
  kms_key_id        = var.cloudwatch_logs_kms_key_id
  skip_destroy      = var.cloudwatch_logs_skip_destroy
  tags              = var.tags
}

resource "aws_lambda_permission" "cloudwatch_logs" {
  for_each = var.cloudwatch_log_subscription_filters

  region = var.region

  action        = "lambda:InvokeFunction"
  function_name = lookup(each.value, "destination_arn", null)
  principal     = "logs.${data.aws_region.current.region}.amazonaws.com"
  source_arn    = "${local.log_group_arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_logs" {
  for_each   = var.cloudwatch_log_subscription_filters
  depends_on = [aws_lambda_permission.cloudwatch_logs]

  region = var.region

  destination_arn = lookup(each.value, "destination_arn", null)
  distribution    = lookup(each.value, "distribution", null)
  filter_pattern  = lookup(each.value, "filter_pattern", "")
  log_group_name  = local.log_group_name
  name            = each.key
  role_arn        = lookup(each.value, "role_arn", null)
}
