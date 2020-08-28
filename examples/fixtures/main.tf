data "archive_file" "lambda" {
  output_path = "${path.module}/lambda.zip"
  type        = "zip"

  source {
    content  = "exports.handler =  async function(event, context) { \n   return context.logStreamName"
    filename = "index.js"
  }
}
