module "fixtures" {
  source = "../../../fixtures"
}

module "lambda" {
  source = "../../../../"

  architectures    = ["arm64"]
  description      = "Example AWS Lambda function using the Java runtime."
  filename         = "${path.module}/../build/distributions/lambda.zip"
  function_name    = module.fixtures.output_function_name
  handler          = "example.Handler::handleRequest"
  memory_size      = 512
  runtime          = "java25"
  source_code_hash = fileexists("${path.module}/../build/distributions/lambda.zip") ? filebase64sha256("${path.module}/../build/distributions/lambda.zip") : null
  timeout          = 30
}
