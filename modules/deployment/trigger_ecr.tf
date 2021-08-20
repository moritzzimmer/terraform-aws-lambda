resource "aws_cloudwatch_event_rule" "this" {
  count = var.ecr_repository_name != "" ? 1 : 0

  name        = "${var.function_name}-ecr-trigger"
  description = "Amazon CloudWatch Events rule to automatically start the pipeline when a change occurs in the Elastic Container Registry."
  tags        = var.tags

  event_pattern = <<PATTERN
{
    "detail-type": [
        "ECR Image Action"
    ],
    "source": [
        "aws.ecr"
    ],
    "detail": {
        "action-type": [
            "PUSH"
        ],
        "image-tag": [
            "${var.ecr_image_tag}"
        ],
        "repository-name": [
            "${var.ecr_repository_name}"
        ],
        "result": [
            "SUCCESS"
        ]
    }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "trigger" {
  count = var.ecr_repository_name != "" ? 1 : 0

  arn       = aws_codepipeline.this.arn
  role_arn  = aws_iam_role.trigger.arn
  rule      = aws_cloudwatch_event_rule.this[count.index].name
  target_id = "CodePipeline"
}
