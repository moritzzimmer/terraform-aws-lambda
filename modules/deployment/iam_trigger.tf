resource "aws_iam_role" "trigger" {
  name = "${local.iam_role_prefix}-trigger-${data.aws_region.current.name}"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "trigger" {
  name = "codepipeline-permissions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["codepipeline:StartPipelineExecution"]
        Effect   = "Allow"
        Resource = aws_codepipeline.this.arn
      },
    ]
  })
  role = aws_iam_role.trigger.name
}
