locals {
  function_arn = "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${var.function_name}"
  handler      = var.package_type != "Zip" ? null : var.handler
  publish      = var.lambda_at_edge || var.snap_start ? true : var.publish
  runtime      = var.package_type != "Zip" ? null : var.runtime
  timeout      = var.lambda_at_edge ? min(var.timeout, 5) : var.timeout
}

resource "aws_lambda_function" "lambda" {
  count = var.ignore_external_function_updates ? 0 : 1

  region = var.region

  architectures                      = var.architectures
  description                        = var.description
  filename                           = var.filename
  function_name                      = var.function_name
  handler                            = local.handler
  image_uri                          = var.image_uri
  kms_key_arn                        = var.kms_key_arn
  layers                             = var.layers
  memory_size                        = var.memory_size
  package_type                       = var.package_type
  publish                            = local.publish
  replace_security_groups_on_destroy = var.replace_security_groups_on_destroy
  replacement_security_group_ids     = var.replacement_security_group_ids
  reserved_concurrent_executions     = var.reserved_concurrent_executions
  role                               = aws_iam_role.lambda.arn
  runtime                            = local.runtime
  s3_bucket                          = var.s3_bucket
  s3_key                             = var.s3_key
  s3_object_version                  = var.s3_object_version
  source_code_hash                   = var.source_code_hash
  tags                               = var.tags
  timeout                            = local.timeout

  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  dynamic "environment" {
    for_each = var.environment == null ? [] : [var.environment]
    content {
      variables = environment.value.variables
    }
  }

  dynamic "file_system_config" {
    for_each = var.file_system_config == null ? [] : [var.file_system_config]
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
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
      ipv6_allowed_for_dual_stack = vpc_config.value.ipv6_allowed_for_dual_stack
      security_group_ids          = vpc_config.value.security_group_ids
      subnet_ids                  = vpc_config.value.subnet_ids
    }
  }

  dynamic "snap_start" {
    for_each = var.snap_start ? [true] : []
    content {
      apply_on = "PublishedVersions"
    }
  }

  dynamic "logging_config" {
    for_each = var.logging_config == null ? [] : [var.logging_config]
    content {
      application_log_level = logging_config.value.application_log_level
      log_format            = logging_config.value.log_format
      log_group             = logging_config.value.log_group
      system_log_level      = logging_config.value.system_log_level
    }
  }

  // create the CloudWatch log group first so it's not automatically created by AWS Lambda
  depends_on = [aws_cloudwatch_log_group.lambda]
}

// Copy of the original Lambda resource plus lifecycle configuration ignoring
// external changes executed by CodeDeploy, aws CLI and others.

// We need this copy workaround, since lifecycle configuration must be static,
// see https://github.com/hashicorp/terraform/issues/24188.
resource "aws_lambda_function" "lambda_external_lifecycle" {
  count = var.ignore_external_function_updates ? 1 : 0

  region = var.region

  architectures                      = var.architectures
  description                        = var.description
  filename                           = var.filename
  function_name                      = var.function_name
  handler                            = local.handler
  image_uri                          = var.image_uri
  kms_key_arn                        = var.kms_key_arn
  layers                             = var.layers
  memory_size                        = var.memory_size
  package_type                       = var.package_type
  publish                            = local.publish
  replace_security_groups_on_destroy = var.replace_security_groups_on_destroy
  replacement_security_group_ids     = var.replacement_security_group_ids
  reserved_concurrent_executions     = var.reserved_concurrent_executions
  role                               = aws_iam_role.lambda.arn
  runtime                            = local.runtime
  s3_bucket                          = var.s3_bucket
  s3_key                             = var.s3_key
  s3_object_version                  = var.s3_object_version
  source_code_hash                   = var.source_code_hash
  tags                               = var.tags
  timeout                            = local.timeout

  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  dynamic "environment" {
    for_each = var.environment == null ? [] : [var.environment]
    content {
      variables = environment.value.variables
    }
  }

  dynamic "file_system_config" {
    for_each = var.file_system_config == null ? [] : [var.file_system_config]
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
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
      ipv6_allowed_for_dual_stack = vpc_config.value.ipv6_allowed_for_dual_stack
      security_group_ids          = vpc_config.value.security_group_ids
      subnet_ids                  = vpc_config.value.subnet_ids
    }
  }

  dynamic "snap_start" {
    for_each = var.snap_start ? [true] : []
    content {
      apply_on = "PublishedVersions"
    }
  }

  dynamic "logging_config" {
    for_each = var.logging_config == null ? [] : [var.logging_config]
    content {
      application_log_level = logging_config.value.application_log_level
      log_format            = logging_config.value.log_format
      log_group             = logging_config.value.log_group
      system_log_level      = logging_config.value.system_log_level
    }
  }

  // create the CloudWatch log group first so it's not automatically created by AWS Lambda
  depends_on = [aws_cloudwatch_log_group.lambda]

  lifecycle {
    ignore_changes = [image_uri, last_modified, qualified_arn, qualified_invoke_arn, s3_object_version, version]
  }
}
