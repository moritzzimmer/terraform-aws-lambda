provider "aws" {
  region = "eu-west-1"
}

module "source" {
  source = "../fixtures"
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with a SQS event trigger."
  filename         = module.source.output_path
  function_name    = "example-with-sqs-event"
  handler          = "handler"
  runtime          = "nodejs12.x"
  source_code_hash = module.source.output_base64sha256

  event = {
    type             = "sqs"
    event_source_arn = "arn:aws:kinesis:eu-west-1:647379381847:queue-name"
  }
}
