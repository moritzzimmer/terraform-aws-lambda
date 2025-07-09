locals {
  create_codepipeline_role = var.codepipeline_role_arn == ""
}

data "aws_iam_policy_document" "codepipeline_role" {
  count = local.create_codepipeline_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  count = local.create_codepipeline_role ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.codepipeline_role[0].json
  name               = "${local.iam_role_prefix}-codepipeline-${data.aws_region.current.region}"
  tags               = var.tags
}

data "aws_iam_policy_document" "codepipeline_s3_source_package_permissions" {
  count = var.s3_bucket != "" && local.create_codepipeline_role ? 1 : 0

  statement {
    actions = [
      "s3:Get*",
      "s3:ListBucket"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket}/*"
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline_s3_source_package_permissions" {
  count = var.s3_bucket != "" && local.create_codepipeline_role ? 1 : 0

  name   = "s3-source-package-permissions"
  policy = data.aws_iam_policy_document.codepipeline_s3_source_package_permissions[0].json
  role   = aws_iam_role.codepipeline_role[0].name

}

data "aws_iam_policy_document" "codepipeline_ecr_source_image_permissions" {
  count = var.ecr_repository_name != "" && local.create_codepipeline_role ? 1 : 0

  statement {
    actions = ["ecr:DescribeImages"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline_ecr_source_image_permissions" {
  count = var.ecr_repository_name != "" && local.create_codepipeline_role ? 1 : 0

  name   = "ecr-source-image-permissions"
  policy = data.aws_iam_policy_document.codepipeline_ecr_source_image_permissions[0].json
  role   = aws_iam_role.codepipeline_role[0].name
}

data "aws_iam_policy_document" "codepipeline" {
  count = local.create_codepipeline_role ? 1 : 0

  statement {
    actions = [
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds"
    ]
    resources = [aws_codebuild_project.this.arn]
  }

  statement {
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:codedeploy:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${aws_codedeploy_app.this.name}/${aws_codedeploy_deployment_group.this.deployment_group_name}"
    ]
  }

  statement {
    actions = [
      "codedeploy:GetDeploymentConfig"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:codedeploy:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"
    ]
  }

  statement {
    actions = [
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:codedeploy:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:application:${aws_codedeploy_app.this.name}"
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]
    resources = [
      local.artifact_store_bucket_arn,
      "${local.artifact_store_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  count = local.create_codepipeline_role ? 1 : 0

  name   = "codepipeline-permissions"
  policy = data.aws_iam_policy_document.codepipeline[0].json
  role   = aws_iam_role.codepipeline_role[0].name
}
