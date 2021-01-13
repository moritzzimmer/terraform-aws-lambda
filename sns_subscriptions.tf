resource "aws_lambda_permission" "sns" {
  for_each = var.sns_subscriptions

  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "sns.amazonaws.com"
  qualifier     = contains(keys(each.value), "endpoint") ? trimprefix(lookup(each.value, "endpoint"), "${module.lambda.arn}:") : null
  source_arn    = lookup(each.value, "topic_arn")
}

resource "aws_sns_topic_subscription" "subscription" {
  for_each = var.sns_subscriptions

  endpoint  = lookup(each.value, "endpoint", module.lambda.arn)
  protocol  = "lambda"
  topic_arn = lookup(each.value, "topic_arn")
}
