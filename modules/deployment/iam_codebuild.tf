resource "aws_iam_role" "codebuild_role" {
  count = var.codebuild_role_arn == "" ? 1 : 0

  name = "${var.function_name}-codebuild-${data.aws_region.current.name}"
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

  inline_policy {
    name = "${var.function_name}-codebuild-${data.aws_region.current.name}"

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
          Resource = "${local.artifact_store_bucket_arn}/${local.pipeline_name}/source/*"
        },
        {
          Action = [
            "s3:PutObject",
          ]
          Effect   = "Allow"
          Resource = "${local.artifact_store_bucket_arn}/${local.pipeline_name}/${local.deploy_output}/*"
        }
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = var.s3_bucket != "" ? [true] : []
    content {
      name = "${var.function_name}-codebuild-s3-${data.aws_region.current.name}"

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
  }
}
