resource "aws_lambda_permission" "cloudwatch_events" {
  for_each = var.cloudwatch_event_rules

  region = var.region

  action        = "lambda:InvokeFunction"
  function_name = var.ignore_external_function_updates ? aws_lambda_function.lambda_external_lifecycle[0].function_name : aws_lambda_function.lambda[0].function_name
  principal     = "events.amazonaws.com"
  qualifier     = contains(keys(each.value), "cloudwatch_event_target_arn") ? trimprefix(each.value["cloudwatch_event_target_arn"], "${local.function_arn}:") : null
  source_arn    = aws_cloudwatch_event_rule.lambda[each.key].arn
}

resource "aws_cloudwatch_event_rule" "lambda" {
  for_each = var.cloudwatch_event_rules

  region = var.region

  description         = lookup(each.value, "description", null)
  event_bus_name      = lookup(each.value, "event_bus_name", null)
  event_pattern       = lookup(each.value, "event_pattern", null)
  name                = lookup(each.value, "name", null)
  name_prefix         = lookup(each.value, "name_prefix", null)
  role_arn            = lookup(each.value, "role_arn", null)
  schedule_expression = lookup(each.value, "schedule_expression", null)
  state               = lookup(each.value, "state", "ENABLED")
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  for_each = var.cloudwatch_event_rules

  region = var.region

  event_bus_name = lookup(each.value, "event_bus_name", null)
  arn            = lookup(each.value, "cloudwatch_event_target_arn", local.function_arn)
  rule           = aws_cloudwatch_event_rule.lambda[each.key].name
  input          = lookup(each.value, "cloudwatch_event_target_input", null)
}
