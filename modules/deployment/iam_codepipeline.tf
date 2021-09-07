resource "aws_iam_role" "codepipeline_role" {
  count = var.codepipeline_role_arn == "" ? 1 : 0

  name = "${var.function_name}-codepipeline-${data.aws_region.current.name}"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  dynamic "inline_policy" {
    for_each = var.ecr_repository_name != "" ? [true] : []
    content {
      name = "${var.function_name}-codepipeline-ecr-${data.aws_region.current.name}"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action   = ["ecr:DescribeImages"]
            Effect   = "Allow"
            Resource = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"
          }
        ]
      })
    }
  }

  inline_policy {
    name = "${var.function_name}-codepipeline-${data.aws_region.current.name}"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "codebuild:StartBuild",
            "codebuild:BatchGetBuilds"
          ]
          Effect   = "Allow"
          Resource = aws_codebuild_project.this.arn
        },
        {
          Action = [
            "s3:Get*",
            "s3:PutObject*",
            "s3:ListBucket"
          ]
          Effect = "Allow"
          Resource = [
            data.aws_s3_bucket.artefacts.arn,
            "${data.aws_s3_bucket.artefacts.arn}/${substr(var.function_name, 0, 21)}/*"
          ]
        }
      ]
    })
  }
}
