# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "function_name" {
  description = "A unique name for your Lambda Function."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "cloudwatch_event_rules" {
  description = "Creates EventBridge (CloudWatch Events) rules invoking your Lambda function. Required Lambda invocation permissions will be generated."
  default     = {}
  type        = map(any)
}

variable "cloudwatch_lambda_insights_enabled" {
  description = "Enable CloudWatch Lambda Insights for your Lambda function."
  default     = false
  type        = bool
}

variable "cloudwatch_lambda_insights_extension_version" {
  description = "Version of the Lambda Insights extension for Lambda functions using `zip` deployment packages, see https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versions.html."
  default     = 14
  type        = number
}

variable "description" {
  description = "Description of what your Lambda Function does."
  default     = ""
  type        = string
}

variable "environment" {
  description = "Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries"
  default     = null
  type = object({
    variables = map(string)
  })
}

variable "event" {
  description = "(deprecated - use `cloudwatch_event_rules` [EventBridge/CloudWatch Events], `event_source_mappings` [DynamoDb, Kinesis, SQS] or `sns_subscriptions` [SNS] instead) Event source configuration which triggers the Lambda function. Supported events: cloudwatch-scheduled-event, dynamodb, kinesis, s3, sns, sqs"
  default     = {}
  type        = map(string)
}

variable "event_source_mappings" {
  description = "Creates event source mappings to allow the Lambda function to get events from Kinesis, DynamoDB and SQS. The IAM role of this Lambda function will be enhanced with necessary minimum permissions to get those events."
  default     = {}
  type        = any
}

variable "filename" {
  description = "The path to the function's deployment package within the local filesystem. If defined, The s3_-prefixed options and image_uri cannot be used."
  default     = null
  type        = string
}

variable "ignore_external_function_updates" {
  description = "Ignore updates to your Lambda function executed externally to the Terraform lifecycle. Set this to `true` if you're using CodeDeploy, aws CLI or other external tools to update your Lambda function code."
  default     = false
  type        = bool
}

variable "handler" {
  description = "The function entrypoint in your code."
  default     = ""
  type        = string
}

variable "image_config" {
  description = <<EOF
  The Lambda OCI [image configurations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#image_config) block with three (optional) arguments:

  - *entry_point* - The ENTRYPOINT for the docker image (type `list(string)`).
  - *command* - The CMD for the docker image (type `list(string)`).
  - *working_directory* - The working directory for the docker image (type `string`).
EOF
  default     = {}
  type        = any
}

variable "image_uri" {
  description = "The ECR image URI containing the function's deployment package. Conflicts with filename, s3_bucket, s3_key, and s3_object_version."
  default     = null
  type        = string
}

variable "kms_key_arn" {
  description = "Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. If this configuration is provided when environment variables are not in use, the AWS Lambda API does not save this configuration and Terraform will show a perpetual difference of adding the key. To fix the perpetual difference, remove this configuration."
  default     = ""
  type        = string
}

variable "lambda_at_edge" {
  description = "Enable Lambda@Edge for your Node.js or Python functions. Required trust relationship and publishing of function versions will be configured."
  default     = false
  type        = bool
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  default     = []
  type        = list(string)
}

variable "log_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group."
  default     = 14
  type        = number
}

variable "logfilter_destination_arn" {
  description = "The ARN of the destination to deliver matching log events to. Kinesis stream or Lambda function ARN."
  default     = ""
  type        = string
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime."
  default     = 128
  type        = number
}

variable "package_type" {
  description = "The Lambda deployment package type. Valid values are Zip and Image."
  default     = "Zip"
  type        = string
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version."
  default     = false
  type        = bool
}

variable "reserved_concurrent_executions" {
  description = "The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations."
  default     = -1
  type        = number
}

variable "runtime" {
  description = "The runtime environment for the Lambda function you are uploading."
  default     = ""
  type        = string
}

variable "s3_bucket" {
  description = "The S3 bucket location containing the function's deployment package. Conflicts with filename and image_uri. This bucket must reside in the same AWS region where you are creating the Lambda function."
  default     = null
  type        = string
}

variable "s3_key" {
  description = "The S3 key of an object containing the function's deployment package. Conflicts with filename and image_uri."
  default     = null
  type        = string
}

variable "s3_object_version" {
  description = "The object version containing the function's deployment package. Conflicts with filename and image_uri."
  default     = null
  type        = string
}

variable "sns_subscriptions" {
  description = "Creates subscriptions to SNS topics which trigger your Lambda function. Required Lambda invocation permissions will be generated."
  default     = {}
  type        = map(any)
}

variable "source_code_hash" {
  description = "Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3_key. The usual way to set this is filebase64sha256('file.zip') where 'file.zip' is the local filename of the lambda function source archive."
  default     = ""
  type        = string
}

variable "ssm" {
  description = "List of AWS Systems Manager Parameter Store parameter names. The IAM role of this Lambda function will be enhanced with read permissions for those parameters. Parameters must start with a forward slash and can be encrypted with the default KMS key."
  default     = null
  type = object({
    parameter_names = list(string)
  })
}

variable "ssm_parameter_names" {
  description = "DEPRECATED: use `ssm` object instead. This variable will be removed in version 6 of this module. (List of AWS Systems Manager Parameter Store parameters this Lambda will have access to. In order to decrypt secure parameters, a kms_key_arn needs to be provided as well.)"
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to the Lambda function and all resources supporting tags."
  default     = {}
  type        = map(string)
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds."
  default     = 3
  type        = number
}

variable "tracing_config_mode" {
  description = "Tracing config mode of the Lambda function. Can be either PassThrough or Active."
  default     = null
  type        = string
}

variable "vpc_config" {
  description = "Provide this to allow your function to access your VPC (if both 'subnet_ids' and 'security_group_ids' are empty then vpc_config is considered to be empty or unset, see https://docs.aws.amazon.com/lambda/latest/dg/vpc.html for details)."
  default     = null
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
  })
}
