resource "aws_cloudwatch_event_rule" "s3_trigger" {
  count = var.s3_bucket != "" ? 1 : 0

  region = var.region

  name        = "${local.iam_role_prefix}-s3-trigger"
  description = "Amazon CloudWatch Events rule to automatically start the pipeline when a change occurs in the Amazon S3 object key or S3 folder."
  tags        = var.tags

  event_pattern = <<PATTERN
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["${var.s3_bucket}"]
    },
    "object":  {
      "key": ["${var.s3_key}"]
    }
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "s3_trigger" {
  count = var.s3_bucket != "" ? 1 : 0

  region = var.region

  arn       = aws_codepipeline.this.arn
  role_arn  = aws_iam_role.trigger.arn
  rule      = aws_cloudwatch_event_rule.s3_trigger[count.index].name
  target_id = "CodePipeline"
}
