provider "aws" {
  region = "eu-west-1"
}

module "source" {
  source = "../fixtures"
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with an Amazon EventBridge (scheduled) event rule."
  filename         = module.source.output_path
  function_name    = "example-with-eventbridge-scheduled-event"
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = module.source.output_base64sha256

  event_bridge_rules = {
    scheduled = {
      schedule_expression = "rate(1 minute)"
    }
  }
}