provider "aws" {
  region = "eu-west-1"
}

module "source" {
  source = "../fixtures"
}

module "lambda-scheduled" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with a CloudWatch (scheduled) event trigger."
  filename         = module.source.output_path
  function_name    = "example-with-cloudwatch-scheduled-event"
  handler          = "handler"
  runtime          = "nodejs12.x"
  source_code_hash = module.source.output_base64sha256

  event = {
    type                = "cloudwatch-event"
    schedule_expression = "rate(1 minute)"
  }
}

module "lambda-pattern" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with a CloudWatch event trigger."
  filename         = module.source.output_path
  function_name    = "example-with-cloudwatch-event"
  handler          = "handler"
  runtime          = "nodejs12.x"
  source_code_hash = module.source.output_base64sha256

  event = {
    type          = "cloudwatch-event"
    event_pattern = <<PATTERN
    {
      "detail-type": [
        "AWS Console Sign In via CloudTrail"
      ]
    }
    PATTERN
  }
}
