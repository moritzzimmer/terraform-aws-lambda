resource "aws_lambda_permission" "sns" {
  for_each      = var.sns_subscriptions

  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "sns.amazonaws.com"
  statement_id  = each.key
  source_arn    = lookup(each.value, "topic_arn")
}

resource "aws_sns_topic_subscription" "subscription" {
  for_each  = var.sns_subscriptions

  endpoint  = var.endpoint
  protocol  = "lambda"
  topic_arn = lookup(each.value, "topic_arn")
}
