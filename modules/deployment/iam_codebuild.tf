locals {
  create_codebuild_role = var.codebuild_role_arn == ""
}

data "aws_iam_policy_document" "codebuild_role" {
  count = local.create_codebuild_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_role" {
  count = local.create_codebuild_role ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.codebuild_role[0].json
  name               = "${local.iam_role_prefix}-codebuild-${data.aws_region.current.region}"
  tags               = var.tags
}

data "aws_iam_policy_document" "codebuild_s3_package_permissions" {
  count = var.s3_bucket != "" && local.create_codebuild_role ? 1 : 0

  statement {
    actions = ["s3:GetObjectVersion"]
    effect  = "Allow"

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket}/${var.s3_key}"
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_s3_package_permissions" {
  count = var.s3_bucket != "" && local.create_codebuild_role ? 1 : 0

  name   = "lambda-s3-package-permissions"
  policy = data.aws_iam_policy_document.codebuild_s3_package_permissions[0].json
  role   = aws_iam_role.codebuild_role[0].name
}

data "aws_iam_policy_document" "codebuild" {
  count = local.create_codebuild_role ? 1 : 0

  statement {
    actions = [
      "lambda:GetAlias",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:PublishVersion",
      "lambda:UpdateFunctionCode"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${var.function_name}"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "${local.artifact_store_bucket_arn}/${local.pipeline_artifacts_folder}/source/*"
    ]
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${local.artifact_store_bucket_arn}/${local.pipeline_artifacts_folder}/${local.deploy_output}/*"
    ]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  count = local.create_codebuild_role ? 1 : 0

  name   = "lambda-update-function-code-permissions"
  policy = data.aws_iam_policy_document.codebuild[0].json
  role   = aws_iam_role.codebuild_role[0].name
}