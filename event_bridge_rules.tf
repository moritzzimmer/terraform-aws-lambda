resource "aws_lambda_permission" "event_bridge" {
  for_each = var.event_bridge_rules

  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda[each.key].arn
  statement_id  = "AllowExecutionFromEventBridge"
}

resource "aws_cloudwatch_event_rule" "lambda" {
  for_each = var.event_bridge_rules

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
  for_each = var.event_bridge_rules

  arn  = module.lambda.arn
  rule = aws_cloudwatch_event_rule.lambda[each.key].name
}
