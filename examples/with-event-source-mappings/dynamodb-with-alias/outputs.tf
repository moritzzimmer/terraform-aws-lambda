output "alias_arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda alias."
  value       = aws_lambda_alias.example.arn
}

output "arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = module.lambda.arn
}

output "event_source_arns" {
  description = "The Amazon Resource Names (ARNs) identifying the event sources."
  value       = [aws_dynamodb_table.table_1.stream_arn, aws_dynamodb_table.table_2.stream_arn]
}

output "function_name" {
  description = "The unique name of your Lambda Function."
  value       = module.lambda.function_name
}

output "role_name" {
  description = "The name of the IAM role attached to the Lambda Function."
  value       = module.lambda.role_name
}
