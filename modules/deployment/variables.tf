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

variable "codepipeline_artifact_store_bucket" {
  description = "Name of an existing S3 bucket used by AWS CodePipeline to store pipeline artifacts. Use the same bucket name as in `s3_bucket` to store deployment packages and pipeline artifacts in one bucket for `package_type=Zip` functions. If empty, a dedicated S3 bucket for your Lambda function will be created."
  default     = ""
  type        = string
}

variable "codepipeline_artifact_store_encryption_key_id" {
  description = "The KMS key ARN or ID of a key block AWS CodePipeline uses to encrypt the data in the artifact store, such as an AWS Key Management Service (AWS KMS) key. If you don't specify a key, AWS CodePipeline uses the default key for Amazon Simple Storage Service (Amazon S3)."
  default     = ""
  type        = string
}

variable "codepipeline_type" {
  description = "Type of the CodePipeline. Possible values are: `V1` and `V2`."
  default     = "V1"
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

variable "codepipeline_variables" {
  description = "CodePipeline variables. Valid only when `codepipeline_type` is `V2`."
  default     = []
  type = list(object({
    name          = string
    default_value = optional(string)
    description   = optional(string)
  }))
}

variable "codebuild_cloudwatch_logs_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the CodeBuild log group."
  default     = 14
  type        = number
}

variable "codebuild_environment_compute_type" {
  description = "Information about the compute resources the build project will use."
  default     = "BUILD_LAMBDA_1GB"
  type        = string
}

variable "codebuild_environment_image" {
  description = "Docker image to use for this build project. The image needs to include python."
  default     = "aws/codebuild/amazonlinux-aarch64-lambda-standard:python3.12"
  type        = string
}

variable "codebuild_environment_type" {
  description = "Type of build environment to use for related builds."
  default     = "ARM_LAMBDA_CONTAINER"
  type        = string
}

variable "codedeploy_appspec_hooks_after_allow_traffic_arn" {
  description = "Lambda function ARN to run after traffic is shifted to the deployed Lambda function version."
  default     = ""
  type        = string
}

variable "codedeploy_appspec_hooks_before_allow_traffic_arn" {
  description = "Lambda function ARN to run before traffic is shifted to the deployed Lambda function version."
  default     = ""
  type        = string
}

variable "codedeploy_deployment_group_alarm_configuration_alarms" {
  description = "A list of alarms configured for the deployment group. A maximum of 10 alarms can be added to a deployment group."
  default     = []
  type        = list(string)
}

variable "codepipeline_post_deployment_stages" {
  type = list(object({
    name = string
    actions = list(object({
      name             = string
      category         = string
      owner            = string
      provider         = string
      version          = string
      input_artifacts  = optional(list(any))
      output_artifacts = optional(list(any))
      configuration    = optional(map(string))
    }))
  }))
  default     = []
  description = "A map of post deployment stages to execute after the Lambda function has been deployed. The following stages are supported: `CodeBuild`, `CodeDeploy`, `CodePipeline`, `CodeStarNotifications`."
}

variable "codedeploy_deployment_group_alarm_configuration_enabled" {
  description = "Indicates whether the alarm configuration is enabled. This option is useful when you want to temporarily deactivate alarm monitoring for a deployment group without having to add the same alarms again later."
  default     = false
  type        = bool
}

variable "codedeploy_deployment_group_alarm_configuration_ignore_poll_alarm_failure" {
  description = "Indicates whether a deployment should continue if information about the current state of alarms cannot be retrieved from CloudWatch."
  default     = false
  type        = bool
}

variable "codedeploy_deployment_group_auto_rollback_configuration_enabled" {
  description = "Indicates whether a defined automatic rollback configuration is currently enabled for this deployment group. If you enable automatic rollback, you must specify at least one event type."
  default     = false
  type        = bool
}

variable "codedeploy_deployment_group_auto_rollback_configuration_events" {
  description = "The event type or types that trigger a rollback. Supported types are `DEPLOYMENT_FAILURE` and `DEPLOYMENT_STOP_ON_ALARM`"
  default     = []
  type        = list(string)
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
  description = "A list of event types associated with this notification rule. For list of allowed events see https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#events-ref-pipeline."
  default = [
    "codepipeline-pipeline-pipeline-execution-succeeded", "codepipeline-pipeline-pipeline-execution-failed"
  ]
  type = list(string)
}

variable "codestar_notifications_target_arn" {
  description = "Use an existing ARN for a notification rule target (for example, a SNS Topic ARN). Otherwise a separate sns topic for this service will be created."
  default     = ""
  type        = string
}

variable "deployment_config_name" {
  description = "The name of the deployment config used in the CodeDeploy deployment group, see https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html for all available default configurations or provide a custom one."
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

variable "region" {
  description = "Alternative region used in all region-aware resources. If not set, the provider's region will be used."
  default     = null
  type        = string
}

variable "s3_bucket" {
  description = "Name of the bucket used for S3 based deployments, required for `package_type=Zip`. Make sure to enable S3 bucket notifications for this bucket for continuous deployment of your Lambda function, see https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventBridge.html."
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
