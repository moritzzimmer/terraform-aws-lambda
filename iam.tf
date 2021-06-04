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
  name               = "${var.function_name}-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "vpc_attachment" {
  count = var.vpc_config == null ? 0 : 1

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "tracing_attachment" {
  count = var.tracing_config_mode == null ? 0 : 1

  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_lambda_insights" {
  count = var.cloudwatch_lambda_insights_enabled ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
  role       = aws_iam_role.lambda.name
}

data "aws_iam_policy_document" "ssm" {
  count = try((var.ssm != null && length(var.ssm.parameter_names) > 0), false) ? 1 : 0

  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = formatlist("arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter%s", var.ssm.parameter_names)
  }
}

resource "aws_iam_policy" "ssm" {
  count = try((var.ssm != null && length(var.ssm.parameter_names) > 0), false) ? 1 : 0

  description = "Provides minimum SSM read permissions."
  name        = "${var.function_name}-ssm-policy-${data.aws_region.current.name}"
  policy      = data.aws_iam_policy_document.ssm[count.index].json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = try((var.ssm != null && length(var.ssm.parameter_names) > 0), false) ? 1 : 0

  policy_arn = aws_iam_policy.ssm[count.index].arn
  role       = aws_iam_role.lambda.name
}
