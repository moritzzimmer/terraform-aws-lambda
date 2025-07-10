data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "fixtures" {
  source = "../../fixtures"
}

locals {
  environment   = "production"
  function_name = module.fixtures.output_function_name
  s3_key        = "${local.function_name}/package/lambda.zip"
}

module "lambda" {
  source                           = "../../../"
  description                      = "Example usage for an AWS Lambda deployed from S3 using CodePipeline and CodeDeploy."
  function_name                    = local.function_name
  handler                          = "index.handler"
  ignore_external_function_updates = true
  publish                          = true
  runtime                          = "nodejs22.x"
  s3_bucket                        = aws_s3_bucket.source.bucket
  s3_key                           = local.s3_key
  s3_object_version                = aws_s3_object.initial.version_id
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
  codepipeline_artifact_store_bucket = aws_s3_bucket.source.bucket // example to (optionally) use the same bucket for deployment packages and pipeline artifacts
  function_name                      = local.function_name
  s3_bucket                          = aws_s3_bucket.source.bucket
  s3_key                             = local.s3_key
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 source bucket resources
# ---------------------------------------------------------------------------------------------------------------------

#trivy:ignore:AVD-AWS-0088
#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket" "source" {
  bucket        = "ci-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id

  versioning_configuration {
    status = "Enabled"
  }
}

// make sure to enable S3 bucket notifications to start continuous deployment pipeline
resource "aws_s3_bucket_notification" "source" {
  bucket      = aws_s3_bucket.source.id
  eventbridge = true
}

resource "aws_s3_bucket_public_access_block" "source" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.source.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// this resource is only used for the initial `terraform apply` - all further
// deployments are running on CodePipeline
resource "aws_s3_object" "initial" {
  bucket = aws_s3_bucket.source.bucket
  key    = local.s3_key
  source = module.fixtures.output_path
  etag   = module.fixtures.output_md5

  lifecycle {
    ignore_changes = [etag]
  }
}
