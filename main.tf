data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  function_arn        = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.function_name}"
  handler             = var.package_type != "Zip" ? null : var.handler
  lambda_insights_arn = "arn:aws:lambda:${data.aws_region.current.name}:580247275435:layer:LambdaInsightsExtension:${var.cloudwatch_lambda_insights_extension_version}"
  layers              = var.cloudwatch_lambda_insights_enabled && var.package_type != "Image" ? concat(var.layers, [local.lambda_insights_arn]) : var.layers
  publish             = var.lambda_at_edge ? true : var.publish
  runtime             = var.package_type != "Zip" ? null : var.runtime
  timeout             = var.lambda_at_edge ? min(var.timeout, 5) : var.timeout
}

resource "aws_lambda_function" "lambda" {
  count = var.ignore_external_function_updates ? 0 : 1

  description                    = var.description
  filename                       = var.filename
  function_name                  = var.function_name
  handler                        = local.handler
  image_uri                      = var.image_uri
  kms_key_arn                    = var.kms_key_arn
  layers                         = local.layers
  memory_size                    = var.memory_size
  package_type                   = var.package_type
  publish                        = local.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = aws_iam_role.lambda.arn
  runtime                        = local.runtime
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  s3_object_version              = var.s3_object_version
  source_code_hash               = var.source_code_hash
  tags                           = var.tags
  timeout                        = local.timeout

  dynamic "environment" {
    for_each = var.environment == null ? [] : [var.environment]
    content {
      variables = environment.value.variables
    }
  }

  dynamic "image_config" {
    for_each = length(var.image_config) > 0 ? [true] : []
    content {
      command           = lookup(var.image_config, "command", null)
      entry_point       = lookup(var.image_config, "entry_point", null)
      working_directory = lookup(var.image_config, "working_directory", null)
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_config_mode == null ? [] : [true]
    content {
      mode = var.tracing_config_mode
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [var.vpc_config]
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }
}

// Copy of the original Lambda resource plus lifecycle configuration ignoring
// external changes executed by CodeDeploy, aws CLI and others.

// We need this copy workaround lifecycle configuration must be static,
// see https://github.com/hashicorp/terraform/issues/24188.
resource "aws_lambda_function" "lambda_external_lifecycle" {
  count = var.ignore_external_function_updates ? 1 : 0

  description                    = var.description
  filename                       = var.filename
  function_name                  = var.function_name
  handler                        = local.handler
  image_uri                      = var.image_uri
  kms_key_arn                    = var.kms_key_arn
  layers                         = local.layers
  memory_size                    = var.memory_size
  package_type                   = var.package_type
  publish                        = local.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = aws_iam_role.lambda.arn
  runtime                        = local.runtime
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  s3_object_version              = var.s3_object_version
  source_code_hash               = var.source_code_hash
  tags                           = var.tags
  timeout                        = local.timeout

  dynamic "environment" {
    for_each = var.environment == null ? [] : [var.environment]
    content {
      variables = environment.value.variables
    }
  }

  dynamic "image_config" {
    for_each = length(var.image_config) > 0 ? [true] : []
    content {
      command           = lookup(var.image_config, "command", null)
      entry_point       = lookup(var.image_config, "entry_point", null)
      working_directory = lookup(var.image_config, "working_directory", null)
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_config_mode == null ? [] : [true]
    content {
      mode = var.tracing_config_mode
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [var.vpc_config]
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  lifecycle {
    ignore_changes = [
      image_uri, last_modified, qualified_arn, version
    ]
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_at_edge ? "us-east-1." : ""}${var.function_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_lambda_permission" "cloudwatch_logs" {
  count = var.logfilter_destination_arn != "" ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = var.logfilter_destination_arn
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.lambda.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_logs_to_es" {
  count      = var.logfilter_destination_arn != "" ? 1 : 0
  depends_on = [aws_lambda_permission.cloudwatch_logs]

  name            = "elasticsearch-stream-filter"
  log_group_name  = aws_cloudwatch_log_group.lambda.name
  filter_pattern  = ""
  destination_arn = var.logfilter_destination_arn
  distribution    = "ByLogStream"
}
