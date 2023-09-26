data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  artifact_store_bucket     = var.codepipeline_artifact_store_bucket != "" ? var.codepipeline_artifact_store_bucket : aws_s3_bucket.pipeline[0].bucket
  artifact_store_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${local.artifact_store_bucket}"
  deploy_output             = "deploy"
  pipeline_name             = substr(var.function_name, 0, 20)
}

resource "aws_codepipeline" "this" {
  depends_on = [aws_iam_role.codepipeline_role]

  name     = local.pipeline_name
  role_arn = var.codepipeline_role_arn == "" ? aws_iam_role.codepipeline_role[0].arn : var.codepipeline_role_arn
  tags     = var.tags

  artifact_store {
    location = local.artifact_store_bucket
    type     = "S3"

    dynamic "encryption_key" {
      for_each = var.codepipeline_artifact_store_encryption_key_id != "" ? [true] : []

      content {
        id   = var.codepipeline_artifact_store_encryption_key_id
        type = "KMS"
      }
    }
  }

  stage {
    name = "Source"

    dynamic "action" {
      for_each = var.ecr_repository_name != "" ? [true] : []
      content {
        name             = "ECR"
        category         = "Source"
        owner            = "AWS"
        provider         = "ECR"
        version          = "1"
        namespace        = "SourceVariables"
        input_artifacts  = []
        output_artifacts = ["source"]

        configuration = {
          ImageTag : var.ecr_image_tag,
          RepositoryName : var.ecr_repository_name
        }
      }
    }

    dynamic "action" {
      for_each = var.s3_bucket != "" ? [true] : []
      content {
        name             = "S3"
        category         = "Source"
        owner            = "AWS"
        provider         = "S3"
        version          = "1"
        namespace        = "SourceVariables"
        input_artifacts  = []
        output_artifacts = ["source"]

        configuration = {
          S3Bucket : var.s3_bucket,
          S3ObjectKey : var.s3_key,
          PollForSourceChanges : "false"
        }
      }
    }
  }

  stage {
    name = "Update"

    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = [local.deploy_output]

      configuration = {
        ProjectName : aws_codebuild_project.this.name
        EnvironmentVariables = jsonencode([
          {
            name  = "SOURCEVARIABLES_VERSIONID"
            value = var.s3_bucket != "" ? "#{SourceVariables.VersionId}" : ""
            type  = "PLAINTEXT"
          },
          {
            name  = "SOURCEVARIABLES_IMAGE_URI"
            value = var.ecr_repository_name != "" ? "#{SourceVariables.ImageURI}" : ""
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      category        = "Deploy"
      name            = "CodeDeploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = [local.deploy_output]

      configuration = {
        ApplicationName : var.function_name
        DeploymentGroupName : var.alias_name
      }
    }
  }
}

resource "aws_s3_bucket" "pipeline" {
  count = var.codepipeline_artifact_store_bucket == "" ? 1 : 0

  bucket        = "${var.function_name}-pipeline-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline" {
  count = var.codepipeline_artifact_store_bucket == "" ? 1 : 0

  bucket = aws_s3_bucket.pipeline[count.index].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "pipeline" {
  count = var.codepipeline_artifact_store_bucket == "" ? 1 : 0

  acl    = "private"
  bucket = aws_s3_bucket.pipeline[count.index].id
}

resource "aws_s3_bucket_public_access_block" "source" {
  count = var.codepipeline_artifact_store_bucket == "" ? 1 : 0

  bucket                  = aws_s3_bucket.pipeline[count.index].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
