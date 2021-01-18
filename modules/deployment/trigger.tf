resource "aws_cloudwatch_event_rule" "this" {
  name        = "${var.function_name}-ecr-trigger"
  description = "Capture ECR push events."
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
            "production"
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
  arn       = aws_codepipeline.this.arn
  role_arn  = aws_iam_role.trigger.arn
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "CodePipeline"
}
