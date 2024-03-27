resource "aws_lambda_permission" "sns" {
  for_each = var.sns_subscriptions

  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "sns.amazonaws.com"
  qualifier     = contains(keys(each.value), "endpoint") ? trimprefix(each.value["endpoint"], "${local.function_arn}:") : null
  source_arn    = each.value["topic_arn"]
}

resource "aws_sns_topic_subscription" "subscription" {
  for_each = var.sns_subscriptions

  endpoint       = lookup(each.value, "endpoint", local.function_arn)
  protocol       = "lambda"
  redrive_policy = lookup(each.value, "redrive_policy", null)
  topic_arn      = each.value["topic_arn"]
}
