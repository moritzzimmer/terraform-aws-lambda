output "arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = module.logs_subscription.arn
}

output "cloudwatch_custom_log_group_name" {
  description = "The name of the custom CloudWatch log group."
  value       = module.logs_subscription.cloudwatch_log_group_name
}

output "cloudwatch_custom_log_group_arn" {
  description = "The Amazon Resource Name (ARN) identifying the custom CloudWatch log group used by your Lambda function."
  value       = module.logs_subscription.cloudwatch_log_group_arn
}

output "cloudwatch_existing_log_group_name" {
  description = "The name of the existing CloudWatch log group."
  value       = module.sub_1.cloudwatch_log_group_name
}

output "cloudwatch_existing_log_group_arn" {
  description = "The Amazon Resource Name (ARN) identifying the existing CloudWatch log group used by your Lambda function."
  value       = module.sub_1.cloudwatch_log_group_arn
}

output "function_name" {
  description = "The unique name of your Lambda Function."
  value       = module.logs_subscription.function_name
}

output "role_name" {
  description = "The name of the IAM role attached to the Lambda Function."
  value       = module.logs_subscription.role_name
}
