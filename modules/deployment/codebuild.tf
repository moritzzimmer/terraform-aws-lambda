resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/codebuild/${var.function_name}-deployment"
  retention_in_days = var.codebuild_cloudwatch_logs_retention_in_days
  tags              = var.tags
}

resource "aws_codebuild_project" "this" {
  name         = "${var.function_name}-deployment"
  service_role = var.codebuild_role_arn == "" ? aws_iam_role.codebuild_role[0].arn : var.codebuild_role_arn
  tags         = var.tags

  artifacts {
    type                = "CODEPIPELINE"
    artifact_identifier = "deploy_output"
    location            = "appspec.json"
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
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "ALIAS_NAME"
      value = var.alias_name
    }

    environment_variable {
      name  = "DEPLOYMENT_GROUP_NAME"
      value = aws_codedeploy_deployment_group.this.deployment_group_name
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
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2
phases:
  install:
    on-failure: ABORT
    runtime-versions:
      python: 3.9
  build:
    commands:
      - |
        cat << BUILD > build.py
        import boto3
        import json
        import os
        import hashlib

        print(f"boto3 version {boto3.__version__}")
        lambda_client = boto3.client("lambda", region_name=os.environ.get("REGION"))
        deploy_client = boto3.client("codedeploy", region_name=os.environ.get("REGION"))

        # common Lambda function vars
        lambda_function_name = os.environ.get("FUNCTION_NAME")
        lambda_alias = os.environ.get("ALIAS_NAME")
        deployment_group_name = os.environ.get("DEPLOYMENT_GROUP_NAME")

        if lambda_alias:
            current_version = lambda_client.get_alias(
                FunctionName=lambda_function_name, Name=lambda_alias)["FunctionVersion"]
        else:
            current_version = lambda_client.get_function(FunctionName=lambda_function_name)["Configuration"]["Version"]

        target_version = ""
        if ("Zip" == os.environ.get("PACKAGE_TYPE")):
          # S3 deployment
          s3_bucket = os.environ.get("S3_BUCKET")
          s3_key = os.environ.get("S3_KEY")
          versionId = os.environ.get("SOURCEVARIABLES_VERSIONID")
          print(f"starting S3 deployment: {s3_bucket}/{s3_key} (versionId={versionId})")

          update_response = lambda_client.update_function_code(FunctionName=lambda_function_name, S3Bucket=s3_bucket, S3Key=s3_key, S3ObjectVersion=versionId, Publish=True)
          target_version = update_response["Version"]
        else:
          # ECR/image deployment
          image_uri = os.environ.get("SOURCEVARIABLES_IMAGE_URI")

          print(f"starting ECR/image deployment: {image_uri}")
          update_response = lambda_client.update_function_code(FunctionName=lambda_function_name, ImageUri=image_uri, Publish=True)
          target_version = update_response["Version"]

        print(f"Updated function code. Triggering CodeDeploy with: current_version={current_version} target_version={target_version}")
        data = {
            "version": 0.0,
            "Resources": [{
                lambda_function_name: {
                    "Type": "AWS::Lambda::Function",
                    "Properties": {
                        "Name": lambda_function_name,
                        "CurrentVersion": current_version,
                        "TargetVersion": target_version
                    }
                }
            }],
            # "Hooks": [{
            #     "BeforeAllowTraffic": "LambdaFunctionToValidateBeforeTrafficShift"
            # },
            #     {
            #         "AfterAllowTraffic": "LambdaFunctionToValidateAfterTrafficShift"
            #     }
            # ]
        }
        if lambda_alias:
            data["Resources"][0][lambda_function_name]["Properties"].update(
                {"Alias": lambda_alias})

        revision = {
            "revisionType": "AppSpecContent",
            "appSpecContent": {
                "content": json.dumps(data),
                "sha256": hashlib.sha256(json.dumps(data).encode("utf-8")).hexdigest()
            }
        }

        # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/codedeploy.html#CodeDeploy.Client.create_deployment
        deployment_id = deploy_client.create_deployment(
            applicationName=lambda_function_name,
            deploymentGroupName=deployment_group_name,
            revision=revision
        )["deploymentId"]

        print(f"deployment was created. id = {deployment_id}")
        BUILD
        python build.py
EOF
  }
}
