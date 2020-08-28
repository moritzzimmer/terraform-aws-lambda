provider "aws" {
  region = "eu-west-1"
}

module "source" {
  source = "../fixtures"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "bucketname"

  lambda_function {
    lambda_function_arn = module.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with a S3 bucket notification event trigger."
  filename         = module.source.output_path
  function_name    = "example-wth-s3-event"
  handler          = "handler"
  runtime          = "nodejs12.x"
  source_code_hash = module.source.output_base64sha256

  event = {
    type          = "s3"
    s3_bucket_arn = "arn:aws:s3:::bucketname"
    s3_bucket_id  = "bucketname"
  }
}
