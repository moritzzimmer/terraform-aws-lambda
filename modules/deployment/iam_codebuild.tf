resource "aws_iam_role" "codebuild_role" {
  count = var.codebuild_role_arn == "" ? 1 : 0

  name               = "${var.function_name}-build-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.allow_codebuild_assume[count.index].json
  tags               = var.tags
}

data "aws_iam_policy_document" "allow_codebuild_assume" {
  count = var.codebuild_role_arn == "" ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "codebuild" {
  count = var.codebuild_role_arn == "" ? 1 : 0

  name   = "${var.function_name}-build-${data.aws_region.current.name}"
  policy = data.aws_iam_policy_document.codebuild[count.index].json
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  count = var.codebuild_role_arn == "" ? 1 : 0

  role       = aws_iam_role.codebuild_role[count.index].name
  policy_arn = aws_iam_policy.codebuild[count.index].arn
}

data "aws_iam_policy_document" "codebuild" {
  count = var.codebuild_role_arn == "" ? 1 : 0

  statement {
    actions = [
      "codedeploy:CreateDeployment"
    ]

    resources = [
      "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${aws_codedeploy_app.this.name}/${aws_codedeploy_deployment_group.this.deployment_group_name}"
    ]
  }

  statement {
    actions = [
      "codedeploy:GetDeploymentConfig"
    ]

    resources = [
      "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentconfig:${var.deployment_config_name}"
    ]
  }

  statement {
    actions = [
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision"
    ]

    resources = [
      "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:application:${aws_codedeploy_app.this.name}"
    ]
  }

  statement {
    actions = [
      "lambda:GetAlias",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:PublishVersion",
      "lambda:UpdateFunctionCode"
    ]

    resources = [
      "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.function_name}"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
    ]
  }

  statement {
    actions = [
      "s3:Get*",
      "s3:PutObject"
    ]

    resources = ["${module.s3_bucket.this_s3_bucket_arn}/*"]
  }
}
