locals {
  # https://aws.amazon.com/about-aws/whats-new/2019/11/aws-lambda-supports-max-retry-attempts-event-age-asynchronous-invocations/
  default_cloudwatch_event_target_retry_policy_maximum_event_age_in_seconds = 6 * 60 * 60 # 6 hours
  default_cloudwatch_event_target_retry_policy_maximum_retry_attempts       = 2
}
resource "aws_lambda_permission" "cloudwatch_events" {
  for_each = var.cloudwatch_event_rules

  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "events.amazonaws.com"
  qualifier     = contains(keys(each.value), "cloudwatch_event_target_arn") ? trimprefix(each.value["cloudwatch_event_target_arn"], "${local.function_arn}:") : null
  source_arn    = aws_cloudwatch_event_rule.lambda[each.key].arn
}

resource "aws_cloudwatch_event_rule" "lambda" {
  for_each = var.cloudwatch_event_rules

  description         = lookup(each.value, "description", null)
  event_bus_name      = lookup(each.value, "event_bus_name", null)
  event_pattern       = lookup(each.value, "event_pattern", null)
  is_enabled          = lookup(each.value, "is_enabled", null)
  name                = lookup(each.value, "name", null)
  name_prefix         = lookup(each.value, "name_prefix", null)
  role_arn            = lookup(each.value, "role_arn", null)
  schedule_expression = lookup(each.value, "schedule_expression", null)
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  for_each = var.cloudwatch_event_rules

  event_bus_name = lookup(each.value, "event_bus_name", null)
  arn            = lookup(each.value, "cloudwatch_event_target_arn", local.function_arn)
  rule           = aws_cloudwatch_event_rule.lambda[each.key].name
  input          = lookup(each.value, "cloudwatch_event_target_input", null)

  retry_policy {
    maximum_event_age_in_seconds = lookup(each.value, "cloudwatch_event_target_retry_policy_maximum_event_age_in_seconds", local.default_cloudwatch_event_target_retry_policy_maximum_event_age_in_seconds)
    maximum_retry_attempts       = lookup(each.value, "cloudwatch_event_target_retry_policy_maximum_retry_attempts", local.default_cloudwatch_event_target_retry_policy_maximum_retry_attempts)
  }
}
