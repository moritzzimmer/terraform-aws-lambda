data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

module "lambda" {
  source                         = "./modules/lambda"
  description                    = var.description
  environment                    = var.environment
  filename                       = var.filename
  function_name                  = var.function_name
  handler                        = var.handler
  kms_key_arn                    = var.kms_key_arn
  layers                         = var.layers
  memory_size                    = var.memory_size
  publish                        = var.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions
  runtime                        = var.runtime
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  s3_object_version              = var.s3_object_version
  source_code_hash               = var.source_code_hash
  timeout                        = var.timeout
  tags                           = var.tags
  vpc_config                     = var.vpc_config
}

module "event-cloudwatch" {
  source = "./modules/event/cloudwatch-event"
  enable = lookup(var.event, "type", "") == "cloudwatch-event" ? true : false

  lambda_function_arn = module.lambda.arn
  description         = lookup(var.event, "description", "")
  event_pattern       = lookup(var.event, "event_pattern", "")
  is_enabled          = lookup(var.event, "is_enabled", true)
  name                = lookup(var.event, "name", null)
  name_prefix         = lookup(var.event, "name_prefix", null)
  schedule_expression = lookup(var.event, "schedule_expression", "")
  tags                = var.tags
}

module "event-dynamodb" {
  source = "./modules/event/dynamodb"
  enable = lookup(var.event, "type", "") == "dynamodb" ? true : false

  batch_size                   = lookup(var.event, "batch_size", 100)
  event_source_mapping_enabled = lookup(var.event, "event_source_mapping_enabled", true)
  function_name                = module.lambda.function_name
  event_source_arn             = lookup(var.event, "event_source_arn", "")
  iam_role_name                = module.lambda.role_name
  starting_position            = lookup(var.event, "starting_position", "TRIM_HORIZON")
}

module "event-kinesis" {
  source = "./modules/event/kinesis"
  enable = lookup(var.event, "type", "") == "kinesis" ? true : false

  batch_size                   = lookup(var.event, "batch_size", 100)
  event_source_mapping_enabled = lookup(var.event, "event_source_mapping_enabled", true)
  function_name                = module.lambda.function_name
  event_source_arn             = lookup(var.event, "event_source_arn", "")
  iam_role_name                = module.lambda.role_name
  starting_position            = lookup(var.event, "starting_position", "TRIM_HORIZON")
}

module "event-s3" {
  source = "./modules/event/s3"
  enable = lookup(var.event, "type", "") == "s3" ? true : false

  lambda_function_arn = module.lambda.arn
  s3_bucket_arn       = lookup(var.event, "s3_bucket_arn", "")
  s3_bucket_id        = lookup(var.event, "s3_bucket_id", "")
}

module "event-sns" {
  source = "./modules/event/sns"
  enable = lookup(var.event, "type", "") == "sns" ? true : false

  endpoint      = module.lambda.arn
  function_name = module.lambda.function_name
  topic_arn     = lookup(var.event, "topic_arn", "")
}

module "event-sqs" {
  source = "./modules/event/sqs"
  enable = lookup(var.event, "type", "") == "sqs" ? true : false

  batch_size                   = lookup(var.event, "batch_size", 10)
  event_source_mapping_enabled = lookup(var.event, "event_source_mapping_enabled", true)
  function_name                = module.lambda.function_name
  event_source_arn             = lookup(var.event, "event_source_arn", "")
  iam_role_name                = module.lambda.role_name
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${module.lambda.function_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_lambda_permission" "cloudwatch_logs" {
  count = var.logfilter_destination_arn != "" ? 1 : 0

  action        = "lambda:InvokeFunction"
  function_name = var.logfilter_destination_arn
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  // workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/14630
  // in aws provider 3.x 'aws_cloudwatch_log_group.lambda.arn' interpolates to something like 'arn:aws:logs:eu-west-1:000000000000:log-group:/aws/lambda/my-group'
  // but we need 'arn:aws:logs:eu-west-1:000000000000:log-group:/aws/lambda/my-group:*'
  source_arn = length(regexall(":\\*$", aws_cloudwatch_log_group.lambda.arn)) == 1 ? aws_cloudwatch_log_group.lambda.arn : "${aws_cloudwatch_log_group.lambda.arn}:*"
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

data "aws_iam_policy_document" "ssm" {
  count = try((var.ssm != null && length(var.ssm.parameter_names) > 0), false) ? 1 : 0

  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = formatlist("arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter%s", var.ssm.parameter_names)
  }
}

resource "aws_iam_policy" "ssm" {
  count = try((var.ssm != null && length(var.ssm.parameter_names) > 0), false) ? 1 : 0

  description = "Provides minimum SSM read permissions."
  name        = "${var.function_name}-ssm-policy-${data.aws_region.current.name}"
  policy      = data.aws_iam_policy_document.ssm[count.index].json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = try((var.ssm != null && length(var.ssm.parameter_names) > 0), false) ? 1 : 0

  role       = module.lambda.role_name
  policy_arn = aws_iam_policy.ssm[count.index].arn
}


// Deprecated - will be removed in the next major version
data "aws_iam_policy_document" "ssm_policy_document" {
  count = length(var.ssm_parameter_names)

  statement {
    actions = [
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${element(var.ssm_parameter_names, count.index)}",
    ]
  }
}

// Deprecated - will be removed in the next major version
resource "aws_iam_policy" "ssm_policy" {
  count       = length(var.ssm_parameter_names)
  name        = "${var.function_name}-ssm-${count.index}-${data.aws_region.current.name}"
  description = "Provides minimum Parameter Store permissions for ${var.function_name}."
  policy      = data.aws_iam_policy_document.ssm_policy_document[count.index].json
}

// Deprecated - will be removed in the next major version
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  count      = length(var.ssm_parameter_names)
  role       = module.lambda.role_name
  policy_arn = aws_iam_policy.ssm_policy[count.index].arn
}

// Deprecated - will be removed in the next major version
data "aws_iam_policy_document" "kms_policy_document" {
  count = var.kms_key_arn != "" ? 1 : 0

  statement {
    actions = [
      "kms:Decrypt",
    ]

    resources = [
      var.kms_key_arn,
    ]
  }
}

// Deprecated - will be removed in the next major version
resource "aws_iam_policy" "kms_policy" {
  count = var.kms_key_arn != "" ? 1 : 0

  name        = "${var.function_name}-kms-${data.aws_region.current.name}"
  description = "Provides minimum KMS permissions for ${var.function_name}."
  policy      = data.aws_iam_policy_document.kms_policy_document[count.index].json
}

// Deprecated - will be removed in the next major version
resource "aws_iam_role_policy_attachment" "kms_policy_attachment" {
  count = var.kms_key_arn != "" ? 1 : 0

  role       = module.lambda.role_name
  policy_arn = aws_iam_policy.kms_policy[count.index].arn
}