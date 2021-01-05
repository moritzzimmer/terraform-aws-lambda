provider "aws" {
  region = "eu-west-1"
}

module "source" {
  source = "../fixtures"
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with a SNS event trigger."
  filename         = module.source.output_path
  function_name    = "example-with-sns-event"
  handler          = "handler"
  runtime          = "nodejs12.x"
  source_code_hash = module.source.output_base64sha256

  sns_subscriptions = {
    sub_test-topic = {
      topic_arn = "arn:aws:sns:eu-west-1:123456789123:test-topic"
    }

    sub_final-topic = {
      topic_arn = "arn:aws:sns:eu-west-1:123456789123:final-topic"
    }
  }
}
