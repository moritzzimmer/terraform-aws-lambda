data "archive_file" "lambda" {
  output_path = "${path.module}/lambda.zip"
  type        = "zip"

  source {
    content  = "exports.handler = async function(event, context) { console.log(\"EVENT: \" + JSON.stringify(event, null, 2)); return context.awsRequestId; }"
    filename = "index.js"
  }
}
