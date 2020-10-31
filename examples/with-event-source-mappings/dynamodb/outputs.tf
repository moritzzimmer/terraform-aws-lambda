output "arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = module.lambda.arn
}

output "function_name" {
  description = "The unique name of your Lambda Function."
  value       = module.lambda.function_name
}
