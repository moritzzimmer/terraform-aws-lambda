locals {
  cloudtrail_s3_prefix = "cloudtrail"
}

resource "aws_cloudtrail" "cloudtrail" {
  count      = var.s3_bucket != "" && var.create_codepipeline_cloudtrail ? 1 : 0
  depends_on = [aws_s3_bucket_policy.cloudtrail]

  name                          = "${var.function_name}-s3-trail"
  include_global_service_events = false
  s3_bucket_name                = var.s3_bucket
  s3_key_prefix                 = local.cloudtrail_s3_prefix
  tags                          = var.tags

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket}/${var.s3_key}"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.s3_bucket != "" && var.create_codepipeline_cloudtrail ? 1 : 0

  bucket = var.s3_bucket
  policy = data.aws_iam_policy_document.cloudtrail[count.index].json
}

data "aws_iam_policy_document" "cloudtrail" {
  count = var.s3_bucket != "" && var.create_codepipeline_cloudtrail ? 1 : 0

  statement {
    actions = ["s3:GetBucketAcl"]

    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket}"
    ]
  }

  statement {
    actions = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }

    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket}/${local.cloudtrail_s3_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
  }
}

resource "aws_cloudwatch_event_rule" "s3_trigger" {
  count = var.s3_bucket != "" ? 1 : 0

  name        = "${var.function_name}-s3-trigger"
  description = "Amazon CloudWatch Events rule to automatically start the pipeline when a change occurs in the Amazon S3 object key or S3 folder."
  tags        = var.tags

  event_pattern = <<PATTERN
{
  "source": [
    "aws.s3"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "s3.amazonaws.com"
    ],
    "eventName": [
      "PutObject",
      "CompleteMultipartUpload",
      "CopyObject"
    ],
    "requestParameters": {
      "bucketName": [
        "${var.s3_bucket}"
      ],
      "key": [
        "${var.s3_key}"
      ]
    }
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "s3_trigger" {
  count = var.s3_bucket != "" ? 1 : 0

  arn       = aws_codepipeline.this.arn
  role_arn  = aws_iam_role.trigger.arn
  rule      = aws_cloudwatch_event_rule.s3_trigger[count.index].name
  target_id = "CodePipeline"
}
