---
name: terraform-lambda
description: >
  Scaffold, configure, and maintain AWS Lambda functions using the terraform-aws-lambda Terraform module.
  Use this skill whenever the user wants to create a new Lambda function with Terraform, add event sources
  (SQS, SNS, Kinesis, DynamoDB, EventBridge) to a Lambda, configure VPC/EFS networking, set up
  CodeDeploy deployments, or troubleshoot Lambda infrastructure. Also use when the user mentions
  terraform-aws-lambda, moritzzimmer/lambda, or asks about Lambda packaging (zip, container image, S3).
  Trigger even if the user just says "create a Lambda" or "new serverless function" in a Terraform context.
---

# terraform-lambda

Create and maintain AWS Lambda functions using the [terraform-aws-lambda](https://registry.terraform.io/modules/moritzzimmer/lambda/aws) Terraform module (current version: **v8.6.0**).

## What this skill does

1. **Scaffold** — Generate complete Lambda projects: Terraform config, handler code, Makefile, and build tooling for any AWS-supported runtime
2. **Configure** — Add features to existing Lambdas: event sources, VPC, EFS, tracing, logging, SSM access
3. **Deploy** — Set up CodeDeploy/CodePipeline blue-green deployment pipelines
4. **Troubleshoot** — Diagnose common Lambda issues: permissions, networking, cold starts

## Core principles

Follow these throughout all generated code:

### Security — least privilege IAM
- The module manages IAM automatically. Never attach broad policies like `AWSLambdaFullAccess` or `AdministratorAccess`.
- The module conditionally attaches only the IAM policies needed for enabled features (VPC, tracing, Insights, SSM, event sources). Trust this mechanism.
- For SSM parameters, specify exact parameter names — never use wildcards like `/app/*`.
- For event source on-failure destinations, specify the exact SQS/SNS ARN.

### Cost optimization
- Default to `architectures = ["arm64"]` (Graviton) — ~20% cheaper, better performance for most workloads. Only use `x86_64` when a dependency requires it (e.g., some native compiled libraries).
- Set `reserved_concurrent_executions` to protect downstream services and control costs.
- Use `cloudwatch_logs_retention_in_days` — never leave logs accumulating forever.

### Observability
- Enable X-Ray tracing: `tracing_config_mode = "Active"`
- Use structured JSON logging: `logging_config = { log_format = "JSON" }`
- Consider `cloudwatch_lambda_insights_enabled = true` for production workloads.

## Scaffolding a new Lambda

When the user asks to create a new Lambda function, generate these files:

### 1. Determine the packaging type

| Packaging | When to use | Key variables |
|-----------|------------|---------------|
| **Local zip** | Source code built locally, deployed as zip | `filename`, `source_code_hash`, `handler`, `runtime` |
| **S3** | Zip stored in S3 (CI/CD pipelines) | `s3_bucket`, `s3_key`, `s3_object_version` |
| **Container image** | Docker/OCI image in ECR | `package_type = "Image"`, `image_uri`, `image_config` |

For container images, `handler` and `runtime` are set in the Dockerfile, not in Terraform — the module handles this automatically (sets them to `null`).

### 2. Generate the Terraform configuration

Use the Terraform Registry source with a pinned version:

```hcl
module "lambda" {
  source  = "moritzzimmer/lambda/aws"
  version = "~> 8.6"

  function_name = "<descriptive-name>"
  description   = "<what it does>"

  # Packaging — pick ONE approach
  filename         = "${path.module}/../build/lambda.zip"
  source_code_hash = fileexists("${path.module}/../build/lambda.zip") ? filebase64sha256("${path.module}/../build/lambda.zip") : null

  # Runtime config
  architectures = ["arm64"]
  handler       = "<runtime-specific>"
  runtime       = "<runtime-id>"
  memory_size   = 128
  timeout       = 30

  # Observability (always include)
  tracing_config_mode                = "Active"
  cloudwatch_logs_retention_in_days  = 14
  logging_config = {
    log_format = "JSON"
  }
}
```

The `fileexists()` guard on `source_code_hash` is important — it prevents `terraform validate` from failing when build artifacts haven't been created yet (e.g., in CI).

### 3. Generate runtime-specific files

Read `references/runtimes.md` for the complete handler code, Makefile, build config, and handler format for each runtime. The reference covers:

- **Go** — `provided.al2023`, bootstrap binary, `GOOS=linux GOARCH=arm64`
- **Python** — `python3.14`, uv packaging, aws-lambda-powertools
- **Java** — `java25`, Gradle buildZip, snap_start support
- **.NET** — `dotnet10`, `dotnet publish`, assembly handler format
- **Node.js** — `nodejs22.x`, npm/esbuild bundling
- **Rust** — `provided.al2023`, cargo-lambda, bootstrap binary
- **Container images** — Dockerfile patterns, ECR integration

### 4. Generate supporting Terraform files

Always generate these alongside the module block:

**versions.tf:**
```hcl
terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
```

**provider.tf** — only if the user doesn't already have one:
```hcl
provider "aws" {
  region = var.region
}
```

**variables.tf** — for user-configurable values like region, environment-specific settings.

**outputs.tf** — expose useful module outputs:
```hcl
output "function_name" {
  value = module.lambda.function_name
}

output "function_arn" {
  value = module.lambda.arn
}

output "invoke_arn" {
  value = module.lambda.invoke_arn
}
```

### 5. Makefile (for local zip packaging)

Follow this standardized pattern — read `references/runtimes.md` for the language-specific build commands:

```makefile
MODE ?= plan

.PHONY: help build package tf clean

help: ## Display this help screen
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Compile the Lambda function
	<language-specific-build>

package: build ## Package the Lambda function as a zip
	<language-specific-zip>

tf: package ## Run terraform init and MODE (default: plan)
	terraform -chdir=terraform init
	terraform -chdir=terraform $(MODE)

clean: ## Remove build artifacts
	<language-specific-clean>
```

The `tf` target chains: build -> package -> terraform. Users run `make tf MODE=apply` to deploy.

## Adding features to an existing Lambda

When the user wants to add capabilities, add the relevant variables to their existing module block. Read `references/event-sources.md` for event source patterns and `references/variables.md` for the full variable reference.

### Common feature additions

**VPC access** — for reaching RDS, ElastiCache, or other VPC resources:
```hcl
vpc_config = {
  security_group_ids = [aws_security_group.lambda.id]
  subnet_ids         = data.aws_subnets.private.ids
}
```

**EFS mount** — for shared file storage:
```hcl
file_system_config = {
  arn              = aws_efs_access_point.lambda.arn
  local_mount_path = "/mnt/data"
}
```
Requires VPC config. The security group must allow NFS (port 2049) to the EFS mount targets.

**Environment variables:**
```hcl
environment = {
  variables = {
    TABLE_NAME = aws_dynamodb_table.this.name
    BUCKET     = aws_s3_bucket.this.id
  }
}
```

**SSM Parameter Store access:**
```hcl
ssm = {
  parameter_names = ["/myapp/prod/db-password", "/myapp/prod/api-key"]
}
```

**Lambda layers:**
```hcl
layers = ["arn:aws:lambda:eu-west-1:123456789:layer:my-layer:1"]
```

**Snap Start (Java only, x86_64):**
```hcl
snap_start       = true
architectures    = ["x86_64"]  # snap_start requires x86_64
publish          = true        # auto-enabled by module, but explicit is clearer
```

## Setting up deployment pipelines

For blue-green deployments with CodeDeploy, read `references/deployment.md`. The key pattern:

1. Set `ignore_external_function_updates = true` on the main module (so Terraform doesn't fight CodeDeploy)
2. Set `publish = true` to enable versioning
3. Add the deployment submodule pointing to the Lambda function

## Troubleshooting guide

**"Lambda can't reach my RDS/ElastiCache"**
- Lambda must be in the same VPC with `vpc_config` set
- Security group must allow outbound to the target's port
- Target's security group must allow inbound from Lambda's security group
- Use private subnets (Lambda doesn't need a public IP for VPC access)

**"Lambda can't reach the internet from VPC"**
- Lambda in VPC loses default internet access
- Add a NAT Gateway in a public subnet, route private subnet traffic through it
- Or use VPC endpoints for AWS services (S3, DynamoDB, SQS, etc.)

**"Permission denied" errors**
- Check if the feature's IAM policy is being created. The module conditionally creates policies based on which features are enabled.
- For SQS/SNS/Kinesis/DynamoDB event sources, permissions are automatic — verify the `event_source_mappings` variable is set correctly.
- For resources the Lambda accesses at runtime (beyond what the module manages), add a custom IAM policy to `module.lambda.role_name`.

**"Cold start too slow" (Java)**
- Enable `snap_start = true` (requires `x86_64`, Java 11+)
- Increase `memory_size` — CPU scales linearly with memory
- Use `reserved_concurrent_executions` to keep warm instances

**source_code_hash not working**
- Always use the `fileexists()` guard pattern
- Ensure the hash points to the same file as `filename`
- For S3 deployments, use `s3_object_version` instead
