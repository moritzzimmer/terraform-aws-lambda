output "output_path" {
  value = data.archive_file.lambda.output_path
}

output "output_base64sha256" {
  value = data.archive_file.lambda.output_base64sha256
}