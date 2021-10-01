module "source" {
  source = "../fixtures"
}

module "lambda" {
  source = "../../"

  architectures    = ["arm64"]
  description      = "Example usage for an AWS Lambda without an event trigger."
  filename         = module.source.output_path
  function_name    = "example-without-event"
  handler          = "index.handler"
  runtime          = "nodejs14.x"
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
