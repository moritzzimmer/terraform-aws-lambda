resource "aws_iam_role" "code_pipeline_role" {
  name               = "code-pipeline-${var.function_name}"
  assume_role_policy = data.aws_iam_policy_document.code_pipeline.json
  tags               = var.tags
}

data "aws_iam_policy_document" "code_pipeline" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "code_pipeline" {
  name   = "deployment-pipeline-${var.function_name}"
  policy = data.aws_iam_policy_document.code_pipeline_permissions.json
}

resource "aws_iam_role_policy_attachment" "code_pipepline_extra" {
  role       = aws_iam_role.code_pipeline_role.name
  policy_arn = aws_iam_policy.code_pipeline.arn
}

data "aws_iam_policy_document" "code_pipeline_permissions" {
  statement {
    actions = ["ecr:DescribeImages"]

    resources = [
      "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${aws_ecr_repository.this.name}"
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]

    resources = [
      module.s3_bucket.this_s3_bucket_arn,
      "${module.s3_bucket.this_s3_bucket_arn}/*"
    ]
  }

  statement {
    actions = [
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds"
    ]

    resources = [aws_codebuild_project.this.arn]
  }
}
