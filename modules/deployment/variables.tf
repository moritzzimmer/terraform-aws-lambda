# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "alias_name" {
  description = "Name of the Lambda alias used in CodeDeploy."
  type        = string
}

variable "function_name" {
  description = "The name of your Lambda Function to deploy."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "create_codepipeline_cloudtrail" {
  description = "Create a CloudTrail to detect S3 package uploads. Since AWS has a hard limit of 5 trails/region, it's recommended to create one central trail for all S3 packaged Lambda functions external to this module."
  default     = false
  type        = bool
}

variable "codepipeline_artifact_store_bucket" {
  description = "Name of an existing S3 bucket used by AWS CodePipeline to store pipeline artifacts. Use the same bucket name as in `s3_bucket` to store deployment packages and pipeline artifacts in one bucket for `package_type=Zip` functions. If empty, a dedicated S3 bucket for your Lambda function will be created."
  default     = ""
  type        = string
}

variable "codepipeline_role_arn" {
  description = "ARN of an existing IAM role for CodePipeline execution. If empty, a dedicated role for your Lambda function with minimal required permissions will be created."
  default     = ""
  type        = string
}

variable "codebuild_role_arn" {
  description = "ARN of an existing IAM role for CodeBuild execution. If empty, a dedicated role for your Lambda function with minimal required permissions will be created."
  default     = ""
  type        = string
}

variable "codebuild_cloudwatch_logs_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the CodeBuild log group."
  default     = 14
  type        = number
}

variable "codebuild_environment_compute_type" {
  description = "Information about the compute resources the build project will use."
  default     = "BUILD_GENERAL1_SMALL"
  type        = string
}

variable "codebuild_environment_image" {
  description = "Docker image to use for this build project."
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
  type        = string
}

variable "codebuild_environment_type" {
  description = "Type of build environment to use for related builds."
  default     = "LINUX_CONTAINER"
  type        = string
}

variable "codestar_notifications_detail_type" {
  description = "The level of detail to include in the notifications for this resource. Possible values are BASIC and FULL."
  default     = "BASIC"
  type        = string
}

variable "codestar_notifications_enabled" {
  description = "Enable CodeStar notifications for your pipeline."
  default     = true
  type        = bool
}

variable "codestar_notifications_event_type_ids" {
  description = "A list of event types associated with this notification rule. For list of allowed events see https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#concepts-api."
  default     = ["codepipeline-pipeline-pipeline-execution-succeeded", "codepipeline-pipeline-pipeline-execution-failed"]
  type        = list(string)
}

variable "codestar_notifications_target_arn" {
  description = "Use an existing ARN for a notification rule target (for example, a SNS Topic ARN). Otherwise a separate sns topic for this service will be created."
  default     = ""
  type        = string
}

variable "deployment_config_name" {
  description = "The name of the deployment config used in the CodeDeploy deployment group."
  default     = "CodeDeployDefault.LambdaAllAtOnce"
  type        = string
}

variable "ecr_image_tag" {
  description = "The container tag used for ECR/container based deployments."
  default     = "latest"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository source used for ECR/container based deployments, required for `package_type=Image`."
  default     = ""
  type        = string
}

variable "s3_bucket" {
  description = "Name of the bucket used for S3 based deployments, required for `package_type=Zip`."
  default     = ""
  type        = string
}

variable "s3_key" {
  description = "Object key used for S3 based deployments, required for `package_type=Zip`."
  default     = ""
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to all resources supporting tags."
  default     = {}
  type        = map(string)
}
