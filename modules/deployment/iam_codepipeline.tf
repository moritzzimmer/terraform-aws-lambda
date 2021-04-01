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
      },
    ]
  })

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
          Action   = ["ecr:DescribeImages"]
          Effect   = "Allow"
          Resource = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"
        },
        {
          Action = [
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObject"
          ]
          Effect = "Allow"
          Resource = [
            module.s3_bucket.this_s3_bucket_arn,
            "${module.s3_bucket.this_s3_bucket_arn}/*"
          ]
        }
      ]
    })
  }
}
