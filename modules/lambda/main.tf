data "aws_region" "current" {
}

resource "aws_lambda_function" "lambda" {
  description                    = var.description
  filename                       = var.filename
  function_name                  = var.function_name
  handler                        = var.package_type != "Zip" ? null : var.handler
  image_uri                      = var.image_uri
  kms_key_arn                    = var.kms_key_arn
  layers                         = var.layers
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

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.function_name}-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_attachment" {
  count      = var.vpc_config == null ? 0 : 1
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "tracing_attachment" {
  count      = var.tracing_config_mode == null ? 0 : 1
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
