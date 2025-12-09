resource "aws_cloudwatch_log_group" "this" {
  region = var.region

  name              = "/aws/codebuild/${var.function_name}"
  retention_in_days = var.codebuild_cloudwatch_logs_retention_in_days
  tags              = var.tags
}

resource "aws_codebuild_project" "this" {
  region = var.region

  name         = var.function_name
  service_role = var.codebuild_role_arn == "" ? aws_iam_role.codebuild_role[0].arn : var.codebuild_role_arn
  tags         = var.tags

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
    compute_type = var.codebuild_environment_compute_type
    image        = var.codebuild_environment_image
    type         = var.codebuild_environment_type

    environment_variable {
      name  = "FUNCTION_NAME"
      value = var.function_name
    }

    environment_variable {
      name  = "REGION"
      value = data.aws_region.current.region
    }

    environment_variable {
      name  = "ALIAS_NAME"
      value = var.alias_name
    }

    environment_variable {
      name  = "S3_BUCKET"
      value = var.s3_bucket
    }

    environment_variable {
      name  = "S3_KEY"
      value = var.s3_key
    }

    environment_variable {
      name  = "PACKAGE_TYPE"
      value = var.ecr_repository_name != "" ? "Image" : "Zip"
    }

    environment_variable {
      name  = "HOOK_BEFORE_ALLOW_TRAFFIC"
      value = var.codedeploy_appspec_hooks_before_allow_traffic_arn
    }

    environment_variable {
      name  = "HOOK_AFTER_ALLOW_TRAFFIC"
      value = var.codedeploy_appspec_hooks_after_allow_traffic_arn
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2
phases:
  build:
    commands:
      - |
        cat << BUILD > build.py
        import boto3
        import json
        import os

        print(f"boto3 version {boto3.__version__}")
        lambda_client = boto3.client("lambda", region_name=os.environ.get("REGION"))

        # common Lambda function vars
        lambda_function_name = os.environ.get("FUNCTION_NAME")
        lambda_alias = os.environ.get("ALIAS_NAME")

        current_version = lambda_client.get_alias(FunctionName=lambda_function_name, Name=lambda_alias)["FunctionVersion"]
        target_version = ""
        if ("Zip" == os.environ.get("PACKAGE_TYPE")):
          # S3 deployment
          s3_bucket = os.environ.get("S3_BUCKET")
          s3_key = os.environ.get("S3_KEY")
          versionId = os.environ.get("SOURCEVARIABLES_VERSIONID")
          print(f"S3 deployment: {s3_bucket}/{s3_key} (versionId={versionId})")

          s3_client = boto3.client("s3", region_name=os.environ.get("REGION"))
          s3_attributes = s3_client.head_object(Bucket=s3_bucket, Key=s3_key, VersionId=versionId)

          if "description" in s3_attributes["Metadata"]:
            description = s3_attributes["Metadata"]["description"]
            # The description of a lambda version can be max 256 characters, so we need to ensure that here
            truncated_description = description[:256]
            update_response = lambda_client.update_function_code(FunctionName=lambda_function_name, S3Bucket=s3_bucket, S3Key=s3_key, S3ObjectVersion=versionId, Publish=False)
            waiter = lambda_client.get_waiter("function_updated_v2")
            waiter.wait(FunctionName=lambda_function_name)
            publish_response = lambda_client.publish_version(FunctionName=lambda_function_name, CodeSha256=update_response["CodeSha256"], Description=truncated_description)
            target_version = publish_response["Version"]
          else:
            update_response = lambda_client.update_function_code(FunctionName=lambda_function_name, S3Bucket=s3_bucket, S3Key=s3_key, S3ObjectVersion=versionId, Publish=True)
            target_version = update_response["Version"]
        else:
          # ECR/image deployment
          image_uri = os.environ.get("SOURCEVARIABLES_IMAGE_URI")

          print(f"ECR deployment: {image_uri}")
          update_response = lambda_client.update_function_code(FunctionName=lambda_function_name, ImageUri=image_uri, Publish=True)
          target_version = update_response["Version"]

        if (current_version == target_version):
          print(f"we should probably skip deployment: current_version={current_version} target_version={target_version}")

        data = {
            "version": 0.0,
            "Resources": [{
                lambda_function_name: {
                    "Type": "AWS::Lambda::Function",
                    "Properties": {
                        "Alias": lambda_alias,
                        "Name": lambda_function_name,
                        "CurrentVersion": current_version,
                        "TargetVersion": target_version
                    }
                }
            }],
            "Hooks": []
        }

        before_traffic = os.environ.get("HOOK_BEFORE_ALLOW_TRAFFIC")
        if before_traffic:
          print(f"adding before allow traffic hook={before_traffic}")
          data["Hooks"].append({"BeforeAllowTraffic": before_traffic})

        after_traffic = os.environ.get("HOOK_AFTER_ALLOW_TRAFFIC")
        if after_traffic:
          print(f"adding after allow traffic hook={after_traffic}")
          data["Hooks"].append({"AfterAllowTraffic": after_traffic})

        print(f"Updated function code, transitioning to CodeDeploy with: current_version={current_version} target_version={target_version}")
        with open('appspec.json','w') as spec:
          spec.write(json.dumps(data))
        BUILD
        python build.py
      - cat appspec.json
artifacts:
  files:
    - appspec.json
EOF
  }
}
