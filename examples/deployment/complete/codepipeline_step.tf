locals {
  codebuild_name = "custom-pipeline-step"
}

resource "aws_cloudwatch_log_group" "custom_step" {
  region = local.region

  name              = "/aws/codebuild/${local.codebuild_name}"
  retention_in_days = 1
}

resource "aws_codebuild_project" "custom_step" {
  region = local.region

  name         = local.codebuild_name
  service_role = aws_iam_role.custom_codepipeline_step.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.custom_step.name
      status     = "ENABLED"
    }

    s3_logs {
      status = "DISABLED"
    }
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/codepipeline_step/buildspec.yml", { script = file("${path.module}/codepipeline_step/step.py") })
  }
}

data "aws_iam_policy_document" "custom_codepipeline_step" {
  statement {
    sid = "Logging"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"]
  }

  # Required for code build to access the code pipeline artifact bucket
  # to be modified depending on input artifacts
  statement {
    sid = "S3BuildArtifactAccess"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]

    #trivy:ignore:AVD-AWS-0057
    resources = ["${module.deployment.codepipeline_artifact_storage_arn}/deploy/*"]
  }
}

resource "aws_iam_policy" "custom_codepipeline_step" {
  name   = "${local.codebuild_name}-${data.aws_region.current.region}"
  policy = data.aws_iam_policy_document.custom_codepipeline_step.json
}

resource "aws_iam_role_policy_attachment" "custom_codepipeline_step" {
  role       = aws_iam_role.custom_codepipeline_step.name
  policy_arn = aws_iam_policy.custom_codepipeline_step.arn
}

resource "aws_iam_role" "custom_codepipeline_step" {
  name = "${local.codebuild_name}-${data.aws_region.current.region}"

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

# Required for code pipeline to execute custom code build steps
data "aws_iam_policy_document" "codepipeline_execution" {
  statement {
    sid = "CustomCodeBuild"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = [aws_codebuild_project.custom_step.arn]
  }
}

resource "aws_iam_policy" "codepipeline_execution" {
  name   = "allow-${local.codebuild_name}-${data.aws_region.current.region}"
  policy = data.aws_iam_policy_document.codepipeline_execution.json
}

resource "aws_iam_policy_attachment" "codepipeline_execution" {
  name       = "allow-${local.codebuild_name}-${data.aws_region.current.region}"
  policy_arn = aws_iam_policy.codepipeline_execution.arn
  roles      = [module.deployment.codepipeline_role_name]
}
