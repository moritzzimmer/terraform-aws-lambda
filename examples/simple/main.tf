provider "aws" {
  region = "eu-west-1"
}

module "source" {
  source = "../fixtures"
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda without an event trigger."
  filename         = module.source.output_path
  function_name    = "example-without-event"
  handler          = "handler"
  runtime          = "nodejs12.x"
  source_code_hash = module.source.output_base64sha256

  environment = {
    variables = {
      key = "value"
    }
  }

  tags = {
    key = "value"
  }
}
