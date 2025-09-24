locals {
  handler = "index.handler"
  runtime = "nodejs22.x"
}

module "fixtures" {
  source = "../fixtures"
}

module "custom_log_group_name" {
  source = "../../"

  description      = "Example usage for an AWS Lambda using a custom log group name."
  filename         = module.fixtures.output_path
  function_name    = "${module.fixtures.output_function_name}-custom-log-group"
  handler          = local.handler
  runtime          = local.runtime
  source_code_hash = module.fixtures.output_base64sha256

  logging_config = {
    log_format = "JSON"
    log_group  = "/custom/${module.fixtures.output_function_name}"
  }
}

module "logs_subscription" {
  source = "../../"

  description      = "Example usage for an AWS Lambda with a CloudWatch logs subscription filters."
  filename         = module.fixtures.output_path
  function_name    = "${module.fixtures.output_function_name}-filter-source"
  handler          = local.handler
  runtime          = local.runtime
  source_code_hash = module.fixtures.output_base64sha256

  cloudwatch_log_subscription_filters = {
    sub_1 = {
      destination_arn = module.sub_1.arn
      filter_pattern  = "%Lambda%"
    }

    sub_2 = {
      destination_arn = module.sub_2.arn
    }
  }
}

data "archive_file" "subscription_handler" {
  type             = "zip"
  source_file      = "${path.module}/handler/index.js"
  output_path      = "${path.module}/handler.zip"
  output_file_mode = "0666"
}

resource "aws_cloudwatch_log_group" "existing" {
  name              = "/existing/${module.fixtures.output_function_name}"
  retention_in_days = 1
}

module "sub_1" {
  source = "../../"

  cloudwatch_logs_retention_in_days = 1
  description                       = "Subscriber function 1 using an existing log group."
  filename                          = data.archive_file.subscription_handler.output_path
  function_name                     = "${module.fixtures.output_function_name}-filter-sub-1"
  handler                           = local.handler
  runtime                           = local.runtime
  source_code_hash                  = data.archive_file.subscription_handler.output_base64sha256

  create_cloudwatch_log_group = false

  logging_config = {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.existing.name
  }
}

module "sub_2" {
  source = "../../"

  cloudwatch_logs_retention_in_days = 1
  description                       = "Subscriber function 2 using an existing log group."
  filename                          = data.archive_file.subscription_handler.output_path
  function_name                     = "${module.fixtures.output_function_name}-filter-sub-2"
  handler                           = local.handler
  runtime                           = local.runtime
  source_code_hash                  = data.archive_file.subscription_handler.output_base64sha256

  create_cloudwatch_log_group = false

  logging_config = {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.existing.name
  }
}
