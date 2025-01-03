resource "aws_iam_role" "codedeploy" {
  name = "${local.iam_role_prefix}-codedeploy-${data.aws_region.current.name}"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "codedeploy_pipeline_artifacts" {
  name = "pipeline-artifacts-permissions"
  role = aws_iam_role.codedeploy.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Effect   = "Allow"
        Resource = "${local.artifact_store_bucket_arn}/${local.pipeline_artifacts_folder}/${local.deploy_output}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "codedeploy_hooks_after_allow_traffic" {
  count = var.codedeploy_appspec_hooks_after_allow_traffic_arn != "" ? 1 : 0

  name = "hooks-after-allow-traffic"
  role = aws_iam_role.codedeploy.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = var.codedeploy_appspec_hooks_after_allow_traffic_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "codedeploy_hooks_after_before_traffic" {
  count = var.codedeploy_appspec_hooks_before_allow_traffic_arn != "" ? 1 : 0

  name = "hooks-after-before-traffic"
  role = aws_iam_role.codedeploy.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = var.codedeploy_appspec_hooks_before_allow_traffic_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.id
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
}
