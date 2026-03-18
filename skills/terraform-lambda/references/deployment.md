# Deployment Module Reference

The `moritzzimmer/lambda/aws//modules/deployment` submodule creates a
CodePipeline/CodeDeploy CI/CD pipeline for blue/green Lambda deployments.
Use it when the user wants automated deployments triggered by S3 uploads
or ECR image pushes.

## When to use

- User wants CI/CD for their Lambda (CodePipeline + CodeDeploy)
- User wants canary or linear deployment strategies
- User wants auto-rollback on deployment failures
- User deploys via S3 artifact or container image push

## Prerequisites on the main module

When using the deployment module, the main Lambda module **must** have:

```hcl
ignore_external_function_updates = true
```

This prevents Terraform from fighting CodeDeploy over function version updates.

## Lambda alias requirement

CodeDeploy operates on a Lambda alias. Create one alongside the main module:

```hcl
resource "aws_lambda_alias" "current" {
  function_name    = module.my_function.function_name
  function_version = module.my_function.version
  name             = "production"

  lifecycle {
    ignore_changes = [function_version]
  }
}
```

The `ignore_changes` on `function_version` is critical — CodeDeploy manages
version shifts, not Terraform.

---

## S3-based deployment (Zip)

The most common pattern. Pipeline triggers when a new zip is uploaded to S3.

### S3 bucket — name must be deterministic at plan time

The deployment module uses `count = var.s3_bucket != ""` which Terraform
evaluates during plan. The bucket name must be resolvable at plan time.

**All of these work:**

1. **Inline bucket with a deterministic name** (used in the module's own examples):
   ```hcl
   resource "aws_s3_bucket" "source" {
     bucket = "ci-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
   }
   # Then use: aws_s3_bucket.source.bucket
   ```

2. **Data source for an existing bucket:**
   ```hcl
   data "aws_s3_bucket" "artifacts" {
     bucket = "my-team-ci-artifacts"
   }
   # Then use: data.aws_s3_bucket.artifacts.bucket
   ```

3. **Literal string or variable:**
   ```hcl
   s3_bucket = "my-artifacts-bucket"
   # or: var.artifacts_bucket
   ```

**Common mistake:** use `.bucket` (the name), not `.id`. The `.id` attribute of
`aws_s3_bucket` can behave differently in count contexts and cause "Invalid
count argument" errors:
```hcl
s3_bucket = aws_s3_bucket.source.bucket  # correct — the bucket name string
s3_bucket = aws_s3_bucket.source.id      # wrong — can cause count errors
```

### Initial S3 upload — critical for first apply

The Lambda function needs the zip to exist in S3 before it can be created.
Without this, the first `terraform apply` fails with `S3 Error Code: NoSuchKey`.

Create an `aws_s3_object` resource that uploads the initial build artifact, and
reference its `version_id` in the main module via `s3_object_version`. This
ensures Terraform uploads the zip before creating the Lambda. Use
`lifecycle { ignore_changes = [etag] }` so subsequent CodePipeline deployments
don't conflict with Terraform state.

### Minimal example

```hcl
locals {
  artifact      = "../build/lambda.zip"
  function_name = "invoice-generator"
  s3_key        = "${local.function_name}/package/lambda.zip"
}

data "aws_s3_bucket" "artifacts" {
  bucket = "my-artifacts-bucket"
}

# Upload initial artifact — only used for first `terraform apply`,
# all further deployments run via CodePipeline
resource "aws_s3_object" "initial" {
  bucket = data.aws_s3_bucket.artifacts.bucket
  key    = local.s3_key
  source = local.artifact
  etag   = fileexists(local.artifact) ? filemd5(local.artifact) : null

  lifecycle {
    ignore_changes = [etag]
  }
}

module "my_function" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  architectures                    = ["arm64"]
  description                      = "Invoice generator"
  function_name                    = local.function_name
  handler                          = "app.main.handler"
  ignore_external_function_updates = true
  publish                          = true
  runtime                          = "<latest python runtime>"
  s3_bucket                        = data.aws_s3_bucket.artifacts.bucket
  s3_key                           = local.s3_key
  s3_object_version                = aws_s3_object.initial.version_id
  timeout                          = 30

  tags = {
    managed_by = "terraform"
  }
}

resource "aws_lambda_alias" "current" {
  function_name    = module.my_function.function_name
  function_version = module.my_function.version
  name             = "production"

  lifecycle {
    ignore_changes = [function_version]
  }
}

module "deployment" {
  source  = "moritzzimmer/lambda/aws//modules/deployment"
  version = "~> 8.6"

  alias_name                         = aws_lambda_alias.current.name
  codepipeline_artifact_store_bucket = data.aws_s3_bucket.artifacts.bucket
  function_name                      = module.my_function.function_name
  s3_bucket                          = data.aws_s3_bucket.artifacts.bucket
  s3_key                             = local.s3_key
}
```

### With canary deployment and auto-rollback

```hcl
module "deployment" {
  source  = "moritzzimmer/lambda/aws//modules/deployment"
  version = "~> 8.6"

  alias_name                         = aws_lambda_alias.current.name
  codepipeline_artifact_store_bucket = data.aws_s3_bucket.artifacts.bucket
  function_name                      = module.my_function.function_name
  s3_bucket                          = data.aws_s3_bucket.artifacts.bucket
  s3_key                             = local.s3_key

  # Canary: shift 10% of traffic, wait 5 minutes, then shift rest
  deployment_config_name = "CodeDeployDefault.LambdaCanary10Percent5Minutes"

  # Auto-rollback on any deployment failure
  codedeploy_deployment_group_auto_rollback_configuration_enabled = true
  codedeploy_deployment_group_auto_rollback_configuration_events  = ["DEPLOYMENT_FAILURE"]
}
```

### With alarm-based monitoring

```hcl
module "deployment" {
  source  = "moritzzimmer/lambda/aws//modules/deployment"
  version = "~> 8.6"

  alias_name                         = aws_lambda_alias.current.name
  codepipeline_artifact_store_bucket = data.aws_s3_bucket.artifacts.bucket
  function_name                      = module.my_function.function_name
  s3_bucket                          = data.aws_s3_bucket.artifacts.bucket
  s3_key                             = local.s3_key

  deployment_config_name = "CodeDeployDefault.LambdaCanary10Percent5Minutes"

  # Monitor CloudWatch alarms during deployment
  codedeploy_deployment_group_alarm_configuration_enabled = true
  codedeploy_deployment_group_alarm_configuration_alarms  = [
    aws_cloudwatch_metric_alarm.error_rate.alarm_name
  ]

  # Rollback on failure OR alarm breach
  codedeploy_deployment_group_auto_rollback_configuration_enabled = true
  codedeploy_deployment_group_auto_rollback_configuration_events  = [
    "DEPLOYMENT_FAILURE",
    "DEPLOYMENT_STOP_ON_ALARM"
  ]
}
```

---

## ECR-based deployment (Container Image)

Pipeline triggers when a new image is pushed to ECR with the specified tag.

```hcl
module "my_function" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  function_name                    = "my-container-function"
  ignore_external_function_updates = true
  image_uri                        = "${aws_ecr_repository.repo.repository_url}:latest"
  package_type                     = "Image"
  publish                          = true

  tags = {
    managed_by = "terraform"
  }
}

resource "aws_lambda_alias" "current" {
  function_name    = module.my_function.function_name
  function_version = module.my_function.version
  name             = "production"

  lifecycle {
    ignore_changes = [function_version]
  }
}

module "deployment" {
  source  = "moritzzimmer/lambda/aws//modules/deployment"
  version = "~> 8.6"

  alias_name          = aws_lambda_alias.current.name
  ecr_image_tag       = "latest"
  ecr_repository_name = aws_ecr_repository.repo.name
  function_name       = module.my_function.function_name
}
```

---

## Deployment config options

AWS provides these built-in deployment configurations:

| Config Name | Strategy |
|-------------|----------|
| `CodeDeployDefault.LambdaAllAtOnce` | Shift all traffic immediately (default) |
| `CodeDeployDefault.LambdaCanary10Percent5Minutes` | 10% for 5 min, then 100% |
| `CodeDeployDefault.LambdaCanary10Percent10Minutes` | 10% for 10 min, then 100% |
| `CodeDeployDefault.LambdaCanary10Percent15Minutes` | 10% for 15 min, then 100% |
| `CodeDeployDefault.LambdaCanary10Percent30Minutes` | 10% for 30 min, then 100% |
| `CodeDeployDefault.LambdaLinear10PercentEvery1Minute` | +10% every minute |
| `CodeDeployDefault.LambdaLinear10PercentEvery2Minutes` | +10% every 2 min |
| `CodeDeployDefault.LambdaLinear10PercentEvery3Minutes` | +10% every 3 min |
| `CodeDeployDefault.LambdaLinear10PercentEvery10Minutes` | +10% every 10 min |

---

## Key variables reference

### Required
| Variable | Type | Description |
|----------|------|-------------|
| `alias_name` | `string` | Lambda alias name used by CodeDeploy |
| `function_name` | `string` | Lambda function name |

### Source (one of these pairs is required)
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `s3_bucket` | `string` | `""` | S3 bucket for Zip packages |
| `s3_key` | `string` | `""` | S3 object key for Zip packages |
| `ecr_repository_name` | `string` | `""` | ECR repo name for container images |
| `ecr_image_tag` | `string` | `"latest"` | ECR image tag |

### Pipeline
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `codepipeline_artifact_store_bucket` | `string` | `""` | Existing S3 bucket for artifacts (creates new if empty) |
| `codepipeline_type` | `string` | `"V1"` | `V1` or `V2` |
| `deployment_config_name` | `string` | `"CodeDeployDefault.LambdaAllAtOnce"` | Deployment strategy |

### Rollback & monitoring
| Variable | Type | Default |
|----------|------|---------|
| `codedeploy_deployment_group_auto_rollback_configuration_enabled` | `bool` | `false` |
| `codedeploy_deployment_group_auto_rollback_configuration_events` | `list(string)` | `[]` |
| `codedeploy_deployment_group_alarm_configuration_enabled` | `bool` | `false` |
| `codedeploy_deployment_group_alarm_configuration_alarms` | `list(string)` | `[]` |

### Notifications
| Variable | Type | Default |
|----------|------|---------|
| `codestar_notifications_enabled` | `bool` | `true` |
| `codestar_notifications_target_arn` | `string` | `""` |

---

## Outputs

| Output | Description |
|--------|-------------|
| `codepipeline_arn` | CodePipeline ARN |
| `codepipeline_id` | CodePipeline ID |
| `codepipeline_artifact_storage_arn` | Artifact store ARN |
| `codebuild_project_arn` | CodeBuild project ARN |
| `codedeploy_app_name` | CodeDeploy application name |
| `codedeploy_deployment_group_arn` | CodeDeploy deployment group ARN |
