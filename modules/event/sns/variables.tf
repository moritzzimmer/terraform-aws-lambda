variable "sns_subscriptions" {
  description = "SNS subscriptions to topics which trigger the Lambda function"
}

variable "endpoint" {
  description = "The endpoint to send data to (ARN of the Lambda function)"
}

variable "function_name" {
  description = "Name of the Lambda function whose resource policy should be allowed to subscribe to SNS topics."
}
