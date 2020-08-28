provider "aws" {
  region = "eu-west-1"
}

module "source" {
  source = "../fixtures"
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda inside a VPC."
  filename         = module.source.output_path
  function_name    = "example-with-vpc"
  handler          = "handler"
  runtime          = "nodejs12.x"
  source_code_hash = module.source.output_base64sha256

  vpc_config = {
    subnet_ids         = ["subnet-123456", "subnet-123457"]
    security_group_ids = ["sg-123456"]
  }
}
