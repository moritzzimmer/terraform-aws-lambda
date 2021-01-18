data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_codepipeline" "this" {
  name     = var.function_name
  role_arn = var.code_pipeline_role_arn == "" ? aws_iam_role.code_pipeline_role[0].arn : var.code_pipeline_role_arn
  tags     = var.tags

  artifact_store {
    location = module.s3_bucket.this_s3_bucket_id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "ECR"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["ecr_source"]

      configuration = {
        "ImageTag" : var.ecr_image_tag,
        "RepositoryName" : var.ecr_repository_name
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "CodeBuild"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["ecr_source"]

      configuration = {
        "ProjectName" : aws_codebuild_project.this.name
      }
    }
  }
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket        = "pipeline-${var.function_name}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = true
  tags          = var.tags
}

