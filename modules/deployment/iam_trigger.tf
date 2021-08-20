resource "aws_iam_role" "trigger" {
  name = "${var.function_name}-trigger-${data.aws_region.current.name}"
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

  inline_policy {
    name = "${var.function_name}-trigger-${data.aws_region.current.name}"

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
  }
}
