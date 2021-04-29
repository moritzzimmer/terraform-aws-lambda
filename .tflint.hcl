config {
  module = true
}

plugin "aws" {
  enabled = true
}


rule "aws_lambda_function_invalid_runtime" {
  enabled = false
}

rule "aws_lambda_function_invalid_handler" {
  enabled = false
}