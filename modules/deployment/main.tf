locals {
  artifact_store_bucket     = var.codepipeline_artifact_store_bucket != "" ? var.codepipeline_artifact_store_bucket : aws_s3_bucket.pipeline[0].bucket
  artifact_store_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${local.artifact_store_bucket}"
  deploy_output             = "deploy"
  pipeline_name             = substr(var.function_name, 0, 100)  // AWS CodePipeline has a limit of 100 characters for the pipeline name, see https://docs.aws.amazon.com/codepipeline/latest/userguide/limits.html
  pipeline_artifacts_folder = substr(local.pipeline_name, 0, 20) // AWS CodePipeline truncates the name of the artifacts folder automatically

  // calculate the maximum length for default IAM role
  // names used in CodePipeline, CodeBuild and CodeDeploy
  // including the AWS Service and region suffix. Those role names
  // must not exceed 64 characters,see https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-quotas.html
  iam_role_name_max_prefix_length = 64 - length("-notifications-${data.aws_region.current.region}")
  iam_role_prefix                 = substr(var.function_name, 0, local.iam_role_name_max_prefix_length)

  // calculate the maximum length for the default pipeline artifact bucket which must not
  // exceed 63 characters, see https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
  bucket_name_max_prefix_length = 63 - length("-pipeline-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}")
  bucket_name_prefix            = substr(var.function_name, 0, local.bucket_name_max_prefix_length)
}

resource "aws_codepipeline" "this" {
  depends_on = [aws_iam_role.codepipeline_role]

  region = var.region

  name          = local.pipeline_name
  pipeline_type = var.codepipeline_type
  role_arn      = var.codepipeline_role_arn == "" ? aws_iam_role.codepipeline_role[0].arn : var.codepipeline_role_arn
  tags          = var.tags

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

  # add arbitrary post deployment stages like, e.g. a manual approval stage
  dynamic "stage" {
    for_each = var.codepipeline_post_deployment_stages
    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions
        content {
          name     = action.value.name
          category = action.value.category

          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          input_artifacts  = action.value.input_artifacts
          output_artifacts = action.value.output_artifacts

          configuration = action.value.configuration
        }
      }
    }
  }

  dynamic "variable" {
    for_each = var.codepipeline_variables
    content {
      name          = variable.value.name
      default_value = variable.value.default_value
      description   = variable.value.description
    }
  }
}

resource "aws_s3_bucket" "pipeline" {
  count = var.codepipeline_artifact_store_bucket == "" ? 1 : 0

  region = var.region

  bucket        = "${local.bucket_name_prefix}-pipeline-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
  force_destroy = true
  tags          = var.tags
}

#trivy:ignore:AVD-AWS-0135
#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline" {
  count = var.codepipeline_artifact_store_bucket == "" ? 1 : 0

  region = var.region

  bucket = aws_s3_bucket.pipeline[count.index].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "source" {
  count = var.codepipeline_artifact_store_bucket == "" ? 1 : 0

  region = var.region

  bucket                  = aws_s3_bucket.pipeline[count.index].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
