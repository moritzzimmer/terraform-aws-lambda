data "aws_iam_policy_document" "codedeploy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  assume_role_policy = data.aws_iam_policy_document.codedeploy.json
  name               = "${local.iam_role_prefix}-codedeploy-${data.aws_region.current.region}"
  tags               = var.tags
}

data "aws_iam_policy_document" "codedeploy_pipeline_artifacts" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "${local.artifact_store_bucket_arn}/${local.pipeline_artifacts_folder}/${local.deploy_output}/*"
    ]
  }
}

resource "aws_iam_role_policy" "codedeploy_pipeline_artifacts" {
  name   = "pipeline-artifacts-permissions"
  policy = data.aws_iam_policy_document.codedeploy_pipeline_artifacts.json
  role   = aws_iam_role.codedeploy.name
}

data "aws_iam_policy_document" "codedeploy_hooks_after_allow_traffic" {
  count = var.codedeploy_appspec_hooks_after_allow_traffic_arn != "" ? 1 : 0

  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [var.codedeploy_appspec_hooks_after_allow_traffic_arn]
  }
}

resource "aws_iam_role_policy" "codedeploy_hooks_after_allow_traffic" {
  count = var.codedeploy_appspec_hooks_after_allow_traffic_arn != "" ? 1 : 0

  name   = "hooks-after-allow-traffic"
  policy = data.aws_iam_policy_document.codedeploy_hooks_after_allow_traffic[0].json
  role   = aws_iam_role.codedeploy.name

}

data "aws_iam_policy_document" "codedeploy_hooks_after_before_traffic" {
  count = var.codedeploy_appspec_hooks_before_allow_traffic_arn != "" ? 1 : 0

  statement {
    actions = ["lambda:InvokeFunction"]
    effect  = "Allow"
    resources = [
      var.codedeploy_appspec_hooks_before_allow_traffic_arn
    ]
  }
}

resource "aws_iam_role_policy" "codedeploy_hooks_after_before_traffic" {
  count = var.codedeploy_appspec_hooks_before_allow_traffic_arn != "" ? 1 : 0

  name   = "hooks-after-before-traffic"
  policy = data.aws_iam_policy_document.codedeploy_hooks_after_before_traffic[0].json
  role   = aws_iam_role.codedeploy.name
}

data "aws_iam_policy" "codedeploy" {
  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
}

resource "aws_iam_role_policy" "codedeploy" {
  name   = "codedeploy-permissions"
  policy = data.aws_iam_policy.codedeploy.policy
  role   = aws_iam_role.codedeploy.id
}
