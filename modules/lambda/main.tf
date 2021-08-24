locals {
  lambda_insights_arn = "arn:aws:lambda:${data.aws_region.current.name}:580247275435:layer:LambdaInsightsExtension:${var.cloudwatch_lambda_insights_extension_version}"
  layers              = var.cloudwatch_lambda_insights_enabled && var.package_type != "Image" ? concat(var.layers, [local.lambda_insights_arn]) : var.layers
}

resource "aws_lambda_function" "lambda" {
  count = var.ignore_external_function_updates ? 0 : 1

  description                    = var.description
  filename                       = var.filename
  function_name                  = var.function_name
  handler                        = var.package_type != "Zip" ? null : var.handler
  image_uri                      = var.image_uri
  kms_key_arn                    = var.kms_key_arn
  layers                         = local.layers
  memory_size                    = var.memory_size
  package_type                   = var.package_type
  publish                        = var.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = aws_iam_role.lambda.arn
  runtime                        = var.package_type != "Zip" ? null : var.runtime
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  s3_object_version              = var.s3_object_version
  source_code_hash               = var.source_code_hash
  tags                           = var.tags
  timeout                        = var.timeout

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
  handler                        = var.package_type != "Zip" ? null : var.handler
  image_uri                      = var.image_uri
  kms_key_arn                    = var.kms_key_arn
  layers                         = local.layers
  memory_size                    = var.memory_size
  package_type                   = var.package_type
  publish                        = var.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = aws_iam_role.lambda.arn
  runtime                        = var.package_type != "Zip" ? null : var.runtime
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  s3_object_version              = var.s3_object_version
  source_code_hash               = var.source_code_hash
  tags                           = var.tags
  timeout                        = var.timeout

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
      image_uri, last_modified, qualified_arn, s3_object_version, version
    ]
  }
}
