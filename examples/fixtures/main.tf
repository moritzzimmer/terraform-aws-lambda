data "archive_file" "lambda" {
  output_path      = "${path.module}/lambda.zip"
  output_file_mode = "0666"
  source_file      = "${path.module}/context/index.js"
  type             = "zip"
}

resource "random_pet" "this" {
  length = 2
}
