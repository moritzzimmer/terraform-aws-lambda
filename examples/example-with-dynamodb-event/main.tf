provider "aws" {
  region = "eu-west-1"
}

module "source" {
  source = "../fixtures"
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with a DynamoDb event trigger."
  filename         = module.source.output_path
  function_name    = "example-with-dynamodb-event"
  handler          = "handler"
  runtime          = "nodejs12.x"
  source_code_hash = module.source.output_base64sha256

  event = {
    type             = "dynamodb"
    event_source_arn = "arn:aws:dynamodb:eu-west-1:647379381847:table/some-table/stream/some-identifier"
  }
}
