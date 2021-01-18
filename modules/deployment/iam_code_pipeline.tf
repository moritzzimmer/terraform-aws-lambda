resource "aws_iam_role" "code_pipeline_role" {
  count = var.code_pipeline_role_arn == "" ? 1 : 0

  name               = "${var.function_name}-pipeline-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.code_pipeline[count.index].json
  tags               = var.tags
}

data "aws_iam_policy_document" "code_pipeline" {
  count = var.code_pipeline_role_arn == "" ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "code_pipeline" {
  count = var.code_pipeline_role_arn == "" ? 1 : 0

  name   = "deployment-pipeline-${var.function_name}"
  policy = data.aws_iam_policy_document.code_pipeline_permissions[count.index].json
}

resource "aws_iam_role_policy_attachment" "code_pipepline_extra" {
  count = var.code_pipeline_role_arn == "" ? 1 : 0

  role       = aws_iam_role.code_pipeline_role[count.index].name
  policy_arn = aws_iam_policy.code_pipeline[count.index].arn
}

data "aws_iam_policy_document" "code_pipeline_permissions" {
  count = var.code_pipeline_role_arn == "" ? 1 : 0

  statement {
    actions = ["ecr:DescribeImages"]

    resources = [
      "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"
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
