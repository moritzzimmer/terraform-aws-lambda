locals {
  // calculate the maximum length for default IAM role including
  // region suffix. Role name must not exceed 64 characters,
  // see https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-quotas.html
  iam_role_name_max_prefix_length = 64 - length("-${data.aws_region.current.region}")
  iam_role_prefix                 = substr(var.function_name, 0, local.iam_role_name_max_prefix_length)
  iam_role_name                   = coalesce(var.iam_role_name, "${local.iam_role_prefix}-${data.aws_region.current.region}")
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = slice(["lambda.amazonaws.com", "edgelambda.amazonaws.com"], 0, var.lambda_at_edge ? 2 : 1)
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = local.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy" "vpc" {
  count = var.vpc_config == null ? 0 : 1

  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}

resource "aws_iam_role_policy" "vpc" {
  count = var.vpc_config == null ? 0 : 1

  name   = "${var.function_name}-vpc"
  policy = data.aws_iam_policy.vpc[0].policy
  role   = aws_iam_role.lambda.id
}

data "aws_iam_policy" "tracing" {
  count = var.tracing_config_mode == null ? 0 : 1

  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "tracing" {
  count = var.tracing_config_mode == null ? 0 : 1

  name   = "${var.function_name}-tracing"
  policy = data.aws_iam_policy.tracing[0].policy
  role   = aws_iam_role.lambda.id
}

data "aws_iam_policy" "lambda_insights" {
  count = var.cloudwatch_lambda_insights_enabled ? 1 : 0

  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

resource "aws_iam_role_policy" "lambda_insights" {
  count = var.cloudwatch_lambda_insights_enabled ? 1 : 0

  name   = "${var.function_name}-insights"
  policy = data.aws_iam_policy.lambda_insights[0].policy
  role   = aws_iam_role.lambda.id
}

data "aws_iam_policy_document" "ssm" {
  count = try((var.ssm != null && length(var.ssm.parameter_names) > 0), false) ? 1 : 0

  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = formatlist("arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter%s", var.ssm.parameter_names)
  }
}

resource "aws_iam_role_policy" "ssm" {
  count = try((var.ssm != null && length(var.ssm.parameter_names) > 0), false) ? 1 : 0

  name   = "${var.function_name}-ssm"
  policy = data.aws_iam_policy_document.ssm[count.index].json
  role   = aws_iam_role.lambda.id
}

data "aws_iam_policy_document" "logs" {
  count = var.cloudwatch_logs_enabled ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    #trivy:ignore:AVD-AWS-0057
    resources = [
      "${local.log_group_arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "logs" {
  count = var.cloudwatch_logs_enabled ? 1 : 0

  name   = "${var.function_name}-logs"
  policy = data.aws_iam_policy_document.logs[count.index].json
  role   = aws_iam_role.lambda.id
}
