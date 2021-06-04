output "arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = local.function_arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group used by your Lambda function."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "function_name" {
  description = "The unique name of your Lambda Function."
  value       = var.function_name
}

output "invoke_arn" {
  description = "The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws_api_gateway_integration's uri"
  value       = var.ignore_external_function_updates ? aws_lambda_function.lambda_external_lifecycle[0].invoke_arn : aws_lambda_function.lambda[0].invoke_arn
}

output "role_name" {
  description = "The name of the IAM role attached to the Lambda Function."
  value       = aws_iam_role.lambda.name
}

output "version" {
  description = "Latest published version of your Lambda Function."
  value       = var.ignore_external_function_updates ? aws_lambda_function.lambda_external_lifecycle[0].version : aws_lambda_function.lambda[0].version
}
