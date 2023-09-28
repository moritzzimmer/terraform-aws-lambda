locals {
  codebuild_name                     = "fooo-bazz-post-deployment"
  codebuild_environment_compute_type = "BUILD_GENERAL1_SMALL"
  codebuild_environment_image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
  codebuild_environment_type         = "LINUX_CONTAINER"

  codebuild_file     = file("${path.module}/codebuild/post_deployment.py")
  buildspec_template = templatefile("${path.module}/codebuild/post_deployment.buildspec.yml", { script = local.codebuild_file })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/codebuild/${local.codebuild_name}"
  retention_in_days = 1
}

resource "aws_codebuild_project" "foo_bazz_codebuild" {
  name         = local.codebuild_name
  service_role = aws_iam_role.foo_bazz_codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.this.name
      status     = "ENABLED"
    }

    s3_logs {
      status = "DISABLED"
    }
  }

  environment {
    compute_type = local.codebuild_environment_compute_type
    image        = local.codebuild_environment_image
    type         = local.codebuild_environment_type
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = local.buildspec_template
  }
}
