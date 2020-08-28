provider "aws" {
  region = "eu-west-1"
}

module "source" {
  source = "../fixtures"
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with a Kinesis event trigger."
  filename         = module.source.output_path
  function_name    = "example-with-kinesis-event"
  handler          = "handler"
  runtime          = "nodejs12.x"
  source_code_hash = module.source.output_base64sha256

  event = {
    type             = "kinesis"
    event_source_arn = "arn:aws:kinesis:eu-west-1:647379381847:stream/my-stream"
  }
}
