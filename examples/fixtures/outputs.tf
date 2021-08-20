output "output_path" {
  value = data.archive_file.lambda.output_path
}

output "output_base64sha256" {
  value = data.archive_file.lambda.output_base64sha256
}

output "output_md5" {
  value = data.archive_file.lambda.output_md5
}