locals {
  create_codebuild_role = var.codebuild_role_arn == ""
}

resource "aws_iam_role" "codebuild_role" {
  count = local.create_codebuild_role ? 1 : 0

  name = "${local.iam_role_prefix}-codebuild-${data.aws_region.current.name}"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_s3_package_permissions" {
  count = var.s3_bucket != "" && local.create_codebuild_role ? 1 : 0

  name = "lambda-s3-package-permissions"
  role = aws_iam_role.codebuild_role[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObjectVersion"
        ]
        Effect = "Allow"
        Resource = [
          "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket}/${var.s3_key}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  count = local.create_codebuild_role ? 1 : 0
  role  = aws_iam_role.codebuild_role[0].name
  name  = "lambda-update-function-code-permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:GetAlias",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:PublishVersion",
          "lambda:UpdateFunctionCode"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.function_name}"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Effect   = "Allow"
        Resource = "${local.artifact_store_bucket_arn}/${local.pipeline_artifacts_folder}/source/*"
      },
      {
        Action = [
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "${local.artifact_store_bucket_arn}/${local.pipeline_artifacts_folder}/${local.deploy_output}/*"
      }
    ]
  })
}