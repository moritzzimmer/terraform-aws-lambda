locals {
  region = "eu-central-1"
}

module "fixtures" {
  source = "../fixtures"
}

module "lambda" {
  source = "../../"

  region = local.region

  architectures          = ["arm64"]
  description            = "Example AWS Lambda function without any triggers."
  ephemeral_storage_size = 512
  filename               = module.fixtures.output_path
  function_name          = module.fixtures.output_function_name
  handler                = "index.handler"
  memory_size            = 128
  runtime                = "nodejs22.x"
  publish                = false
  snap_start             = false
  source_code_hash       = module.fixtures.output_base64sha256
  timeout                = 3
  tracing_config_mode    = "Active"

  // logs and metrics
  cloudwatch_logs_enabled            = true
  cloudwatch_logs_retention_in_days  = 7
  cloudwatch_lambda_insights_enabled = true
  layers                             = ["arn:aws:lambda:${local.region}:580247275435:layer:LambdaInsightsExtension-Arm64:23"]

  environment = {
    variables = {
      key = "value"
    }
  }

  // AWS Systems Manager (SSM) Parameter Store
  ssm = {
    parameter_names = ["/internal/params", "/external/params"]
  }

  tags = {
    key = "value"
  }
}
