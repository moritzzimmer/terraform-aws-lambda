module "fixtures" {
  source = "../../../fixtures"
}

module "lambda" {
  source = "../../../../"

  architectures    = ["arm64"]
  description      = "Example AWS Lambda function using Python 3.14 runtime."
  filename         = "${path.module}/../build/lambda.zip"
  function_name    = module.fixtures.output_function_name
  handler          = "handler.handler"
  memory_size      = 256
  runtime          = "python3.14"
  source_code_hash = filebase64sha256("${path.module}/../build/lambda.zip")
  timeout          = 30
}
