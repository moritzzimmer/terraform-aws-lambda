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

resource "aws_iam_role" "trigger" {
  assume_role_policy = data.aws_iam_policy_document.trigger-assume-role-policy.json
  name               = "${var.function_name}-${data.aws_region.current.name}-ecr-trigger"
  tags               = var.tags

}

data "aws_iam_policy_document" "trigger-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "trigger" {
  name   = "${var.function_name}-${data.aws_region.current.name}-ecr-trigger"
  policy = data.aws_iam_policy_document.trigger-permissions.json
}

data "aws_iam_policy_document" "trigger-permissions" {
  statement {
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = [aws_codepipeline.this.arn]
  }
}

resource "aws_iam_role_policy_attachment" "trigger" {
  policy_arn = aws_iam_policy.trigger.arn
  role       = aws_iam_role.trigger.name
}
