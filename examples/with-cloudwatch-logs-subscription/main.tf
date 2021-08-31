module "source" {
  source = "../fixtures"
}

module "lambda" {
  source = "../../"

  cloudwatch_logs_retention_in_days = 14
  description                       = "Example usage for an AWS Lambda with a CloudWatch logs subscription filter."
  filename                          = module.source.output_path
  function_name                     = "example-without-cloudwatch-logs-subscription"
  handler                           = "index.handler"
  runtime                           = "nodejs14.x"
  source_code_hash                  = module.source.output_base64sha256

  cloudwatch_log_subscription_filters = {
    lambda_1 = {
      //see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter for available arguments
      destination_arn = module.destination_1.arn // required
    }

    lambda_2 = {
      destination_arn = module.destination_2.arn // required
    }
  }
}

module "destination_1" {
  source = "../../"

  cloudwatch_logs_retention_in_days = 1
  filename                          = module.source.output_path
  function_name                     = "cloudwatch-logs-subscription-destination-1"
  handler                           = "index.handler"
  runtime                           = "nodejs14.x"
  source_code_hash                  = module.source.output_base64sha256
}

module "destination_2" {
  source = "../../"

  cloudwatch_logs_retention_in_days = 1
  filename                          = module.source.output_path
  function_name                     = "cloudwatch-logs-subscription-destination-2"
  handler                           = "index.handler"
  runtime                           = "nodejs14.x"
  source_code_hash                  = module.source.output_base64sha256
}
