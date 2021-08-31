output "arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = module.lambda.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group used by your Lambda function."
  value       = module.lambda.cloudwatch_log_group_name
}

output "function_name" {
  description = "The unique name of your Lambda Function."
  value       = module.lambda.function_name
}

output "role_name" {
  description = "The name of the IAM role attached to the Lambda Function."
  value       = module.lambda.role_name
}
