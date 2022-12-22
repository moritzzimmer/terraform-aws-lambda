resource "aws_iam_role" "codedeploy" {
  name = "${var.function_name}-codedeploy-${data.aws_region.current.name}"
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

  inline_policy {
    name = "${var.function_name}-codebuild-${data.aws_region.current.name}"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:GetObjectVersion"
          ]
          Effect   = "Allow"
          Resource = "${local.artifact_store_bucket_arn}/${local.pipeline_name}/${local.deploy_output}/*"
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.id
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
}
