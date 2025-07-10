data "aws_iam_policy_document" "trigger" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "trigger" {
  assume_role_policy = data.aws_iam_policy_document.trigger.json
  name               = "${local.iam_role_prefix}-trigger-${data.aws_region.current.region}"
  tags               = var.tags
}

data "aws_iam_policy_document" "codepipeline_trigger" {
  statement {
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = [aws_codepipeline.this.arn]
  }
}

resource "aws_iam_role_policy" "trigger" {
  name   = "codepipeline-permissions"
  policy = data.aws_iam_policy_document.codepipeline_trigger.json
  role   = aws_iam_role.trigger.name
}
