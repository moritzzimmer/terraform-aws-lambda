module "fixtures" {
  source = "../fixtures"
}

module "lambda" {
  source = "../../"

  architectures    = ["arm64"]
  description      = "Example AWS Lambda durable function."
  filename         = module.fixtures.output_path
  function_name    = module.fixtures.output_function_name
  handler          = "index.handler"
  memory_size      = 128
  runtime          = "nodejs22.x"
  publish          = true
  snap_start       = false
  source_code_hash = module.fixtures.output_base64sha256
  timeout          = 30

  durable_config = {
    execution_timeout = 3600
    retention_period  = 7
  }

  timeouts = {
    delete = "60m"
  }
}
