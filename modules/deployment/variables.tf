# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "alias_name" {
  description = "Name of the Lambda alias used in CodeDeploy."
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository source used for deployments."
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

variable "code_pipeline_role_arn" {
  description = "ARN of an existing IAM role for CodePipeline execution. If empty, a dedicated role for your Lambda function with minimal required permissions will be created."
  default     = ""
  type        = string
}

variable "code_build_role_arn" {
  description = "ARN of an existing IAM role for CodeBuild execution. If empty, a dedicated role for your Lambda function with minimal required permissions will be created."
  default     = ""
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
  description = "The tag used for the Lambda container image."
  default     = "latest"
  type        = string
}

variable "cloudwatch_logs_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group."
  default     = 14
  type        = number
}

variable "tags" {
  description = "A mapping of tags to assign to all resources supporting tags."
  default     = {}
  type        = map(string)
}