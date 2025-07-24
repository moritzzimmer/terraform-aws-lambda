data "aws_iam_policy_document" "sns_codestar_policy" {
  count = var.codestar_notifications_enabled && var.codestar_notifications_target_arn == "" ? 1 : 0

  statement {
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    resources = [aws_sns_topic.notifications[count.index].arn]
  }
}

resource "aws_codestarnotifications_notification_rule" "notification" {
  count = var.codestar_notifications_enabled ? 1 : 0

  region = var.region

  detail_type    = var.codestar_notifications_detail_type
  event_type_ids = var.codestar_notifications_event_type_ids
  name           = "${local.iam_role_prefix}-notifications-${data.aws_region.current.region}"
  resource       = aws_codepipeline.this.arn
  tags           = var.tags

  target {
    address = var.codestar_notifications_target_arn == "" ? aws_sns_topic.notifications[count.index].arn : var.codestar_notifications_target_arn
  }
}

#trivy:ignore:AVD-AWS-0095
resource "aws_sns_topic" "notifications" {
  count = var.codestar_notifications_enabled && var.codestar_notifications_target_arn == "" ? 1 : 0

  region = var.region

  name = "${var.function_name}-notifications"
  tags = var.tags
}

resource "aws_sns_topic_policy" "notifications" {
  count = var.codestar_notifications_enabled && var.codestar_notifications_target_arn == "" ? 1 : 0

  region = var.region

  arn    = aws_sns_topic.notifications[count.index].arn
  policy = data.aws_iam_policy_document.sns_codestar_policy[count.index].json
}
