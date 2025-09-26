locals {
  handler = "index.handler"
  runtime = "nodejs22.x"
}

module "fixtures" {
  source = "../fixtures"
}

module "logs_subscription" {
  source = "../../"

  description      = "Example usage for an AWS Lambda with CloudWatch logs subscription filters and advanced log configuration using a custom log group name."
  filename         = module.fixtures.output_path
  function_name    = module.fixtures.output_function_name
  handler          = local.handler
  runtime          = local.runtime
  source_code_hash = module.fixtures.output_base64sha256

  // configure module managed log group
  cloudwatch_logs_log_group_class   = "STANDARD"
  cloudwatch_logs_retention_in_days = 7
  cloudwatch_logs_skip_destroy      = false

  // advanced logging config including a custom CloudWatch log group managed by the module
  logging_config = {
    application_log_level = "INFO"
    log_format            = "JSON"
    log_group             = "/custom/${module.fixtures.output_function_name}"
    system_log_level      = "WARN"
  }

  // register log subscription filters for the functions log group
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

  description      = "Example usage of a log subscription Lambda function with advanced log configuration."
  filename         = data.archive_file.subscription_handler.output_path
  function_name    = "${module.fixtures.output_function_name}-sub-1"
  handler          = local.handler
  runtime          = local.runtime
  source_code_hash = data.archive_file.subscription_handler.output_base64sha256


  cloudwatch_logs_retention_in_days = 1
  create_cloudwatch_log_group       = false

  // advanced logging config using an external CloudWatch log group
  logging_config = {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.existing.name
  }
}

module "sub_2" {
  source = "../../"

  description      = "Example usage of a log subscription Lambda function with advanced log configuration."
  filename         = data.archive_file.subscription_handler.output_path
  function_name    = "${module.fixtures.output_function_name}-sub-2"
  handler          = local.handler
  runtime          = local.runtime
  source_code_hash = data.archive_file.subscription_handler.output_base64sha256

  cloudwatch_logs_retention_in_days = 1
  create_cloudwatch_log_group       = false

  // advanced logging config using an external CloudWatch log group
  logging_config = {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.existing.name
  }
}
