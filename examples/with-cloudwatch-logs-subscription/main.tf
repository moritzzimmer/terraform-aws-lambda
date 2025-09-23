locals {
  handler = "index.handler"
  runtime = "nodejs22.x"
}

module "fixtures" {
  source = "../fixtures"
}

module "lambda" {
  source = "../../"

  description      = "Example usage for an AWS Lambda with a CloudWatch logs subscription filters and advanced logging."
  filename         = module.fixtures.output_path
  function_name    = module.fixtures.output_function_name
  handler          = local.handler
  runtime          = local.runtime
  source_code_hash = module.fixtures.output_base64sha256

  cloudwatch_logs_retention_in_days = 7

  cloudwatch_log_subscription_filters = {
    destination_1 = {
      destination_arn = module.destination_1.arn
      filter_pattern  = "%Lambda%"
    }

    destination_2 = {
      destination_arn = module.destination_2.arn
    }
  }
}

data "archive_file" "destination_handler" {
  type             = "zip"
  source_file      = "${path.module}/processor/index.js"
  output_path      = "${path.module}/processor.zip"
  output_file_mode = "0666"
}

module "destination_1" {
  source = "../../"

  cloudwatch_logs_retention_in_days = 1
  description                       = "Lambda destination 1 of '${module.lambda.cloudwatch_log_group_name}'"
  filename                          = data.archive_file.destination_handler.output_path
  function_name                     = "${module.fixtures.output_function_name}-destination-1"
  handler                           = local.handler
  runtime                           = local.runtime
  source_code_hash                  = data.archive_file.destination_handler.output_base64sha256
}

module "destination_2" {
  source = "../../"

  cloudwatch_logs_retention_in_days = 1
  description                       = "Lambda destination 2 of '${module.lambda.cloudwatch_log_group_name}'"
  filename                          = data.archive_file.destination_handler.output_path
  function_name                     = "${module.fixtures.output_function_name}-destination-2"
  handler                           = local.handler
  runtime                           = local.runtime
  source_code_hash                  = data.archive_file.destination_handler.output_base64sha256
}
