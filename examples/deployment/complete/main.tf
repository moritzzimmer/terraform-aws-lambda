data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "function" {
  source = "../../fixtures"
}

locals {
  environment   = "production"
  function_name = "deployment-hooks"
  s3_key        = "${local.function_name}/package/lambda.zip"
}

module "lambda" {
  source = "../../../"

  architectures                    = ["arm64"]
  description                      = "Example usage for an AWS Lambda deployed from S3 using CodePipeline and CodeDeploy with hooks."
  function_name                    = local.function_name
  handler                          = "index.handler"
  ignore_external_function_updates = true
  publish                          = true
  runtime                          = "nodejs18.x"
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

  alias_name                                                      = aws_lambda_alias.this.name
  create_codepipeline_cloudtrail                                  = true // it's recommended to create a central CloudTrail for all S3 based Lambda functions externally to this module
  codedeploy_appspec_hooks_after_allow_traffic_arn                = module.traffic_hook.arn
  codedeploy_appspec_hooks_before_allow_traffic_arn               = module.traffic_hook.arn
  codedeploy_deployment_group_auto_rollback_configuration_enabled = true
  codedeploy_deployment_group_auto_rollback_configuration_events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  codepipeline_artifact_store_bucket                              = aws_s3_bucket.source.bucket                // example to (optionally) use the same bucket for deployment packages and pipeline artifacts
  deployment_config_name                                          = aws_codedeploy_deployment_config.custom.id // optionally use custom deployment configuration or a different default deployment configuration like `CodeDeployDefault.LambdaLinear10PercentEvery1Minute` from https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html
  function_name                                                   = local.function_name
  s3_bucket                                                       = aws_s3_bucket.source.bucket
  s3_key                                                          = local.s3_key
}

resource "aws_codedeploy_deployment_config" "custom" {
  deployment_config_name = "custom-lambda-deployment-config"
  compute_platform       = "Lambda"

  traffic_routing_config {
    type = "TimeBasedLinear"

    time_based_linear {
      interval   = 1
      percentage = 50
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CodeDeploy hooks resources
# ---------------------------------------------------------------------------------------------------------------------

// see https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-lambda
module "traffic_hook" {
  source = "../../../"

  architectures    = ["arm64"]
  description      = "Lambda function executed by CodeDeploy before and/or after allow traffic to deployed version."
  filename         = data.archive_file.traffic_hook.output_path
  function_name    = "codedeploy-hook-example"
  handler          = "hook.handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.traffic_hook.output_base64sha256
}

data "archive_file" "traffic_hook" {
  output_path      = "${path.module}/function/traffic_hook.zip"
  output_file_mode = "0666"
  source_file      = "${path.module}/function/hook.py"
  type             = "zip"
}

data "aws_iam_policy_document" "traffic_hook" {
  statement {
    actions   = ["codedeploy:PutLifecycleEventHookExecutionStatus"]
    resources = [module.deployment.codedeploy_deployment_group_arn]
  }
}

resource "aws_iam_policy" "traffic_hook" {
  name   = "codedeploy-hook-policy"
  policy = data.aws_iam_policy_document.traffic_hook.json
}

resource "aws_iam_role_policy_attachment" "traffic_hook" {
  role       = module.traffic_hook.role_name
  policy_arn = aws_iam_policy.traffic_hook.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 source and pipeline bucket resources
# ---------------------------------------------------------------------------------------------------------------------

#tfsec:ignore:aws-s3-enable-bucket-encryption - configure bucket encryption in production!
resource "aws_s3_bucket" "source" {
  acl           = "private"
  bucket        = "ci-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = true

  versioning {
    enabled = true
  }
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
  source = module.function.output_path
  etag   = module.function.output_md5

  lifecycle {
    ignore_changes = [etag]
  }
}
