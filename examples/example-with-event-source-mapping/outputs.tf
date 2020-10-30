output "arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = module.sqs.arn
}

output "function_name" {
  description = "The unique name of your Lambda Function."
  value       = module.sqs.function_name
}
