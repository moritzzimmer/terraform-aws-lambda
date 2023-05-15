resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_at_edge ? "us-east-1." : ""}${var.function_name}"
  retention_in_days = var.cloudwatch_logs_retention_in_days
  kms_key_id        = var.cloudwatch_logs_kms_key_id
  tags              = var.tags
}

resource "aws_lambda_permission" "cloudwatch_logs" {
  for_each = var.cloudwatch_log_subscription_filters

  action        = "lambda:InvokeFunction"
  function_name = lookup(each.value, "destination_arn", null)
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.lambda.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_logs" {
  for_each   = var.cloudwatch_log_subscription_filters
  depends_on = [aws_lambda_permission.cloudwatch_logs]

  destination_arn = lookup(each.value, "destination_arn", null)
  distribution    = lookup(each.value, "distribution", null)
  filter_pattern  = lookup(each.value, "filter_pattern", "")
  log_group_name  = aws_cloudwatch_log_group.lambda.name
  name            = each.key
  role_arn        = lookup(each.value, "role_arn", null)
}
