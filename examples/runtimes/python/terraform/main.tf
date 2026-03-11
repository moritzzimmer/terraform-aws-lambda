module "fixtures" {
  source = "../../../fixtures"
}

module "lambda" {
  source = "../../../../"

  architectures    = ["arm64"]
  description      = "Example AWS Lambda function using Python runtime."
  filename         = "${path.module}/../build/lambda.zip"
  function_name    = module.fixtures.output_function_name
  handler          = "app.main.handler"
  memory_size      = 256
  runtime          = "python3.14"
  source_code_hash = fileexists("${path.module}/../build/lambda.zip") ? filebase64sha256("${path.module}/../build/lambda.zip") : null
  timeout          = 30
}
