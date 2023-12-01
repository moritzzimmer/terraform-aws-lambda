data "aws_region" "current" {}

module "source" {
  source = "../fixtures"
}

resource "random_pet" "this" {
  length = 2
}

module "lambda" {
  source = "../../"

  architectures          = ["arm64"]
  description            = "Example AWS Lambda function without any triggers."
  ephemeral_storage_size = 512
  filename               = module.source.output_path
  function_name          = random_pet.this.id
  handler                = "index.handler"
  memory_size            = 128
  runtime                = "nodejs18.x"
  publish                = false
  snap_start             = false
  source_code_hash       = module.source.output_base64sha256
  timeout                = 3

  // logs and metrics
  cloudwatch_logs_enabled            = true
  cloudwatch_logs_retention_in_days  = 7
  cloudwatch_lambda_insights_enabled = true
  layers                             = ["arn:aws:lambda:${data.aws_region.current.id}:580247275435:layer:LambdaInsightsExtension-Arm64:5"]

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
