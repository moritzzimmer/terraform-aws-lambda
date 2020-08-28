provider "aws" {
  region = "eu-west-1"
}

module "source" {
  source = "../fixtures"
}

resource "aws_ssm_parameter" "string" {
  name  = "/example/string"
  type  = "String"
  value = "changeme"
}

resource "aws_ssm_parameter" "secure_string" {
  name  = "/example/secure.string"
  type  = "SecureString"
  value = "changeme"
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with read permissions to SSM parameters."
  filename         = module.source.output_path
  function_name    = "example-without-event"
  handler          = "handler"
  runtime          = "nodejs12.x"
  source_code_hash = module.source.output_base64sha256

  ssm = {
    parameter_names = [aws_ssm_parameter.string.name, aws_ssm_parameter.secure_string.name]
  }
}
