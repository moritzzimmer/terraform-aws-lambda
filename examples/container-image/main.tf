locals {
  environment   = "production"
  function_name = "example-with-container-images"
}

resource "aws_ecr_repository" "this" {
  name = local.function_name
}

module "lambda" {
  source     = "../../"
  depends_on = [null_resource.initial_image]

  description   = "Example usage for an AWS Lambda using container images."
  function_name = local.function_name
  image_uri     = "${aws_ecr_repository.this.repository_url}:${local.environment}"
  package_type  = "Image"
}

resource "null_resource" "initial_image" {
  depends_on = [aws_ecr_repository.this]

  provisioner "local-exec" {
    command     = "docker build --tag ${aws_ecr_repository.this.repository_url}:${local.environment} ."
    working_dir = "${path.module}/../fixtures/context"
  }

  provisioner "local-exec" {
    command     = "docker push --all-tags ${aws_ecr_repository.this.repository_url}"
    working_dir = "${path.module}/../fixtures/context"
  }
}
