data "aws_iam_policy_document" "foo_bazz_codebuild" {
  statement {
    sid = "Logging"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
    ]
  }

  # Required for code build to access the code pipeline artifact bucket
  # to be modified depending on input artifacts
  statement {
    sid = "S3BuildArtifactAccess"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["${module.deployment.codepipeline_artifact_storage_bucket}/deploy/*"]
  }
}

resource "aws_iam_policy" "foo_bazz_codebuild" {
  name   = "${local.codebuild_name}-${data.aws_region.current.name}"
  policy = data.aws_iam_policy_document.foo_bazz_codebuild.json
}

resource "aws_iam_role_policy_attachment" "foo_bazz_codebuild" {
  role       = aws_iam_role.foo_bazz_codebuild.name
  policy_arn = aws_iam_policy.foo_bazz_codebuild.arn
}

resource "aws_iam_role" "foo_bazz_codebuild" {
  name = "${local.codebuild_name}-${data.aws_region.current.name}"

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

    resources = [aws_codebuild_project.foo_bazz_codebuild.arn]
  }
}

resource "aws_iam_policy" "codepipeline_execution" {
  name   = "AllowExecutionOf${local.codebuild_name}-${data.aws_region.current.name}"
  policy = data.aws_iam_policy_document.codepipeline_execution.json
}

resource "aws_iam_policy_attachment" "codepipeline_execution" {
  name       = "AllowExecutionOf${local.codebuild_name}-${data.aws_region.current.name}"
  policy_arn = aws_iam_policy.codepipeline_execution.arn
  roles      = [module.deployment.codepipeline_role_name]
}
