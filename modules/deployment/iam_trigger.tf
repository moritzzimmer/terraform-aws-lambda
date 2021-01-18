resource "aws_iam_role" "trigger" {
  assume_role_policy = data.aws_iam_policy_document.trigger-assume-role-policy.json
  name               = "${var.function_name}-ecr-trigger-${data.aws_region.current.name}"
  tags               = var.tags

}

data "aws_iam_policy_document" "trigger-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "trigger" {
  name   = "${var.function_name}-${data.aws_region.current.name}-ecr-trigger"
  policy = data.aws_iam_policy_document.trigger-permissions.json
}

data "aws_iam_policy_document" "trigger-permissions" {
  statement {
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = [aws_codepipeline.this.arn]
  }
}

resource "aws_iam_role_policy_attachment" "trigger" {
  policy_arn = aws_iam_policy.trigger.arn
  role       = aws_iam_role.trigger.name
}
