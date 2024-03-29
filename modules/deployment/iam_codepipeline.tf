resource "aws_iam_role" "codepipeline_role" {
  count = var.codepipeline_role_arn == "" ? 1 : 0

  name = "${local.iam_role_prefix}-codepipeline-${data.aws_region.current.name}"
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
    for_each = var.s3_bucket != "" ? [true] : []
    content {
      name = "s3-source-package-permissions"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = [
              "s3:Get*",
              "s3:ListBucket"
            ]
            Effect = "Allow"
            Resource = [
              "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket}",
              "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket}/*",
            ]
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = var.ecr_repository_name != "" ? [true] : []
    content {
      name = "ecr-source-image-permissions"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action   = ["ecr:DescribeImages"]
            Effect   = "Allow"
            Resource = "arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"
          }
        ]
      })
    }
  }

  inline_policy {
    name = "codepipeline-permissions"

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
            "codedeploy:CreateDeployment",
            "codedeploy:GetDeployment"
          ]
          Effect   = "Allow"
          Resource = "arn:${data.aws_partition.current.partition}:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${aws_codedeploy_app.this.name}/${aws_codedeploy_deployment_group.this.deployment_group_name}"
        },
        {
          Action = [
            "codedeploy:GetDeploymentConfig"
          ]
          Effect   = "Allow"
          Resource = "arn:${data.aws_partition.current.partition}:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"
        },
        {
          Action = [
            "codedeploy:RegisterApplicationRevision"
          ]
          Effect   = "Allow"
          Resource = "arn:${data.aws_partition.current.partition}:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:application:${aws_codedeploy_app.this.name}"
        },
        {
          Action = [
            "s3:GetObject",
            "s3:GetObjectTagging",
            "s3:ListBucket",
            "s3:PutObject",
            "s3:PutObjectTagging"
          ]
          Effect = "Allow"
          Resource = [
            local.artifact_store_bucket_arn,
            "${local.artifact_store_bucket_arn}/*"
          ]
        }
      ]
    })
  }
}
