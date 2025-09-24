resource "aws_iam_role" "github_actions" {
  name               = var.role_name != null ? var.role_name : "github-actions-${split("/", var.github_repository)[0]}-${data.aws_region.current.region}"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    sid     = "GithubOIDCAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      values   = [for ref in var.github_refs : "repo:${var.github_repository}:ref/refs/heads/${ref}"]
      variable = "token.actions.githubusercontent.com:sub"
    }

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.id]
    }
  }
}

resource "aws_iam_role_policy" "s3" {
  count  = var.s3_prefixes != null ? 1 : 0
  role   = aws_iam_role.github_actions.name
  name   = "s3-access"
  policy = data.aws_iam_policy_document.s3[0].json
}

data "aws_iam_policy_document" "s3" {
  count = var.s3_prefixes != null ? 1 : 0
  statement {
    sid       = "BucketLevelAccess"
    effect    = "Allow"
    resources = [for prefix in var.s3_prefixes : "arn:aws:s3:::${split("/", prefix)[0]}"]
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
  }

  statement {
    sid       = "ObjectLevelAccess"
    effect    = "Allow"
    resources = [for prefix in var.s3_prefixes : "arn:aws:s3:::${prefix}/*"]
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
  }
}

resource "aws_iam_role_policy" "ecr" {
  count  = var.ecr_repositories != null ? 1 : 0
  role   = aws_iam_role.github_actions.name
  name   = "ecr-access"
  policy = data.aws_iam_policy_document.ecr[0].json
}

data "aws_iam_policy_document" "ecr" {
  count = var.ecr_repositories != null ? 1 : 0
  statement {
    sid       = "GetAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PutImage"
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [
      for repo in var.ecr_repositories :
      "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${repo}"
    ]
  }
}
