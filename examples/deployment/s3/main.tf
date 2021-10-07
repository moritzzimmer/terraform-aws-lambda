data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "function" {
  source = "../../fixtures"
}

locals {
  cloudtrail_s3_prefix = "cloudtrail"
  environment          = "production"
  function_name        = "with-s3-codepipeline"
  s3_key               = "${local.function_name}/package/lambda.zip"
}

module "lambda" {
  source                           = "../../../"
  description                      = "Example usage for an AWS Lambda deployed from S3 using CodePipeline and CodeDeploy."
  function_name                    = local.function_name
  handler                          = "index.handler"
  ignore_external_function_updates = true
  publish                          = true
  runtime                          = "nodejs14.x"
  s3_bucket                        = aws_s3_bucket.source.bucket
  s3_key                           = local.s3_key
  s3_object_version                = aws_s3_bucket_object.initial.version_id
}

# ---------------------------------------------------------------------------------------------------------------------
# Deployment resources
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_alias" "this" {
  function_name    = module.lambda.function_name
  function_version = module.lambda.version
  name             = local.environment

  lifecycle {
    ignore_changes = [function_version]
  }
}

module "deployment" {
  source = "../../../modules/deployment"

  alias_name                         = aws_lambda_alias.this.name
  create_codepipeline_cloudtrail     = false                       // for brevity only, it's recommended to create a central CloudTrail for all S3 based Lambda functions externally to this module (see resources below)
  codepipeline_artifact_store_bucket = aws_s3_bucket.source.bucket // example to (optionally) use the same bucket for deployment packages and pipeline artifacts
  function_name                      = local.function_name
  s3_bucket                          = aws_s3_bucket.source.bucket
  s3_key                             = local.s3_key
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 source bucket resources
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "source" {
  acl           = "private"
  bucket        = "example-ci-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = true

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "source" {
  bucket = aws_s3_bucket.source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// this resource is only used for the initial `terraform apply` - all further
// deployments are running on CodePipeline
resource "aws_s3_bucket_object" "initial" {
  bucket = aws_s3_bucket.source.bucket
  key    = local.s3_key
  source = module.function.output_path
  etag   = module.function.output_md5

  lifecycle {
    ignore_changes = [etag, version_id]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CloudTrail resources - beware of the hard account limit of 5 trails/region!
#
# only necessary if the target AWS account doesn't contain a CloudTrail with S3 bucket
# policy as described here: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html
# ---------------------------------------------------------------------------------------------------------------------

//resource "aws_s3_bucket" "cloudtrail" {
//  acl           = "private"
//  bucket        = "cloudtrail-s3-operations"
//  force_destroy = true
//}
//
//resource "aws_s3_bucket_public_access_block" "source" {
//  bucket = aws_s3_bucket.cloudtrail.id
//
//  block_public_acls       = true
//  block_public_policy     = true
//  ignore_public_acls      = true
//  restrict_public_buckets = true
//}
//
//// AWS CodePipline with S3 sources integrates with CloudTrail to start pipelines
//// after S3 upload events, see https://docs.aws.amazon.com/codepipeline/latest/userguide/update-change-detection.html
////
//// Since AWS has a hard limit of 5 trails/region
//resource "aws_cloudtrail" "cloudtrail" {
//  depends_on = [aws_s3_bucket_policy.cloudtrail]
//
//  name                          = "s3-bucket-writeonly-trail"
//  include_global_service_events = false
//  s3_bucket_name                = aws_s3_bucket.cloudtrail.bucket
//
//  event_selector {
//    read_write_type           = "WriteOnly"
//    include_management_events = false
//
//    data_resource {
//      type   = "AWS::S3::Object"
//      values = ["arn:aws:s3:::"]
//    }
//  }
//}
//
//resource "aws_s3_bucket_policy" "cloudtrail" {
//  bucket = aws_s3_bucket.cloudtrail.bucket
//  policy = data.aws_iam_policy_document.cloudtrail.json
//}
//
//// see https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html
//data "aws_iam_policy_document" "cloudtrail" {
//  statement {
//    actions = ["s3:GetBucketAcl"]
//
//    principals {
//      identifiers = ["cloudtrail.amazonaws.com"]
//      type        = "Service"
//    }
//
//    resources = [
//      "arn:aws:s3:::${aws_s3_bucket.cloudtrail.bucket}"
//    ]
//  }
//
//  statement {
//    actions = ["s3:PutObject"]
//
//    condition {
//      test     = "StringEquals"
//      values   = ["bucket-owner-full-control"]
//      variable = "s3:x-amz-acl"
//    }
//
//    principals {
//      identifiers = ["cloudtrail.amazonaws.com"]
//      type        = "Service"
//    }
//
//    resources = [
//      "arn:aws:s3:::${aws_s3_bucket.cloudtrail.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
//    ]
//  }
