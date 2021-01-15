output "arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = var.ignore_external_function_updates ? aws_lambda_function.lambda_external_lifecycle[0].arn : aws_lambda_function.lambda[0].arn
}

output "function_name" {
  description = "The unique name of your Lambda Function."
  value       = var.ignore_external_function_updates ? aws_lambda_function.lambda_external_lifecycle[0].function_name : aws_lambda_function.lambda[0].function_name
}

output "invoke_arn" {
  description = "The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws_api_gateway_integration's uri"
  value       = var.ignore_external_function_updates ? aws_lambda_function.lambda_external_lifecycle[0].invoke_arn : aws_lambda_function.lambda[0].invoke_arn
}

output "role_name" {
  description = "The name of the IAM attached to the Lambda Function."
  value       = aws_iam_role.lambda.name
}

output "version" {
  description = "Latest published version of your Lambda Function."
  value       = var.ignore_external_function_updates ? aws_lambda_function.lambda_external_lifecycle[0].version : aws_lambda_function.lambda[0].version
}