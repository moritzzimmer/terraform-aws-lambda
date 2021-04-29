# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "function_name" {
  description = "A unique name for your Lambda Function."
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

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
}

variable "environment" {
  description = "Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries."
  type = object({
    variables = map(string)
  })
  default = null
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
}

variable "image_config" {
  description = "The Lambda OCI image configurations."
  default     = {}
  type        = any
}

variable "image_uri" {
  description = "The ECR image URI containing the function's deployment package. Conflicts with filename, s3_bucket, s3_key, and s3_object_version."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. If this configuration is provided when environment variables are not in use, the AWS Lambda API does not save this configuration and Terraform will show a perpetual difference of adding the key. To fix the perpetual difference, remove this configuration."
  default     = ""
}

variable "lambda_at_edge" {
  description = "Enable Lambda@Edge for your Node.js or Python functions. Required trust relationship and publishing of function versions will be configured."
  default     = false
  type        = bool
}

variable "layers" {
  default     = []
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  type        = list(string)
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime."
  default     = 128
}

variable "package_type" {
  description = "The Lambda deployment package type. Valid values are Zip and Image."
  default     = "Zip"
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version."
  default     = false
}

variable "reserved_concurrent_executions" {
  description = "The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations."
  default     = -1
  type        = number
}

variable "runtime" {
  description = "The runtime environment for the Lambda function you are uploading."
  default     = ""
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

variable "source_code_hash" {
  description = "Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3_key. The usual way to set this is filebase64sha256('file.zip') where 'file.zip' is the local filename of the lambda function source archive."
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the Lambda function."
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds."
  default     = 3
}

variable "tracing_config_mode" {
  description = "Tracing config mode of the Lambda function. Can be either PassThrough or Active."
  default     = null
  type        = string
}

variable "vpc_config" {
  default     = null
  description = "Provide this to allow your function to access your VPC (if both 'subnet_ids' and 'security_group_ids' are empty then vpc_config is considered to be empty or unset, see https://docs.aws.amazon.com/lambda/latest/dg/vpc.html for details)."
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
  })
}
