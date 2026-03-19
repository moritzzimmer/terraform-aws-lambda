---
name: terraform-lambda
description: >
  Scaffold a complete AWS Lambda function project using the terraform-aws-lambda
  Terraform module (moritzzimmer/lambda/aws). Generates Terraform configuration,
  runtime-specific build tooling (Makefile), and minimal function code with
  correct event source wiring and IAM setup. Use this skill whenever the user
  wants to create a new Lambda function, scaffold a Lambda project, set up a
  serverless function with Terraform, or asks about using the terraform-aws-lambda
  module. Also trigger when the user mentions "new lambda", "lambda scaffold",
  "lambda boilerplate", or wants to add a Lambda function to their infrastructure.
argument-hint: "[function-name] [runtime] [event-source]"
---

# Create Lambda

Scaffold production-ready AWS Lambda functions using the
[terraform-aws-lambda](https://registry.terraform.io/modules/moritzzimmer/lambda/aws)
Terraform module.

## When to use this skill

- User wants to create a new Lambda function
- User wants to scaffold a Lambda project with Terraform
- User is setting up serverless infrastructure on AWS with Terraform
- User asks how to use the `moritzzimmer/lambda/aws` module

## Gather requirements

Before generating anything, establish what the user needs. If they provided
arguments via `/terraform-lambda`, parse them. Otherwise ask concisely:

1. **Function name** (required) — must be a valid Lambda function name
2. **Runtime** — Go, Python, Java, .NET, Node.js, or container image (default: Python)
3. **Event source** — what triggers the function: SQS, SNS, Kinesis, DynamoDB Streams, CloudWatch Events/schedule, API Gateway, S3, or none (default: none)
4. **Extra features** — VPC, EFS, X-Ray tracing, Lambda Insights, SSM parameters, CloudWatch log retention, snap_start (Java only)
5. **CI/CD pipeline** — does the user want CodeDeploy-based deployments? If so:
   - S3 or ECR source?
   - **S3 bucket**: Does an S3 bucket already exist (reference via `data` source
     or bucket name), or should the skill create a new one inline? This matters
     for the Terraform setup — ask explicitly.
   - Deployment strategy: canary, linear, or all-at-once?
   - Auto-rollback on failure?
6. **Target directory** — where to create the project (default: `./<function-name>/`)

If the user gives a one-liner like "create a Python Lambda triggered by SQS called order-processor", extract all info from that — don't ask again for things already stated.

## Generate the project

### Directory layout

```
<function-name>/
├── Makefile              # Build and deploy
├── terraform/
│   ├── main.tf           # Module usage + event source resources
│   ├── variables.tf      # Environment-specific variables
│   ├── outputs.tf        # Useful outputs from the module
│   ├── versions.tf       # Terraform and provider version constraints
│   └── provider.tf       # AWS provider configuration
└── <source code>         # Layout is runtime-specific (see references/runtimes.md)
```

Source code location varies by runtime — Go puts `main.go` and `go.mod` at the
project root (idiomatic Go), Python uses `app/` at the project root, .NET puts
source files at root, Java uses the standard Gradle `src/main/java/` layout.
Always consult [references/runtimes.md](references/runtimes.md) for the correct
layout.

### Terraform files

**versions.tf** — pin providers:
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

**provider.tf**:
```hcl
provider "aws" {
  region = var.region
}
```

**variables.tf** — always include `region`, add others as needed:
```hcl
variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}
```

**outputs.tf** — expose the most useful module outputs:
```hcl
output "function_arn" {
  value = module.<function_name>.arn
}

output "function_name" {
  value = module.<function_name>.function_name
}

output "role_arn" {
  value = module.<function_name>.role_arn
}

output "invoke_arn" {
  value = module.<function_name>.invoke_arn
}
```

**main.tf** — the module block plus any event source resources. Key rules:

- Module source: `"moritzzimmer/lambda/aws"`, version: `"~> 8.6"`
- Alphabetical attribute ordering inside the module block
- Guard `source_code_hash` with `fileexists()` so `terraform validate` works
  without build artifacts:
  ```hcl
  source_code_hash = fileexists(local.artifact) ? filebase64sha256(local.artifact) : null
  ```
- Default architecture: `["arm64"]` (Graviton — better price/performance)
- **Runtime versions**: Do not rely on your training data for Lambda runtime
  identifiers — they go stale quickly. Before generating code, look up the
  latest runtime by searching the web for "AWS Lambda supported runtimes" or
  checking `https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html`.
  If you cannot verify, leave a `# TODO: verify this is the latest runtime`
  comment next to the runtime value so the user knows to check.
- Always include `tags = { managed_by = "terraform" }`

For runtime-specific settings, event source patterns, and the full variable
reference, consult the reference files:

- [references/runtimes.md](references/runtimes.md) — runtime configs, Makefile
  templates, and sample function code for each supported language
- [references/event-sources.md](references/event-sources.md) — how to wire up
  each event source type with correct Terraform resources
- [references/variables.md](references/variables.md) — full variable reference
  grouped by feature area, with defaults and IAM implications
- [references/deployment.md](references/deployment.md) — CodePipeline/CodeDeploy
  CI/CD pipeline setup using the deployment submodule

### CI/CD with the deployment submodule

When the user wants CodeDeploy-based deployments, the setup changes:

1. The main module uses **S3-based packaging** (`s3_bucket`/`s3_key`) instead of
   local `filename`, and sets `ignore_external_function_updates = true`
2. An **`aws_s3_object` resource** uploads the initial build artifact to S3, and
   the main module references `s3_object_version` from it — this ensures the zip
   exists before the Lambda is created (without this, first apply fails with
   `NoSuchKey`). Use `lifecycle { ignore_changes = [etag] }` so CodePipeline
   deployments don't conflict.
3. A **Lambda alias** is created with `lifecycle { ignore_changes = [function_version] }`
   — CodeDeploy manages version shifts, not Terraform
4. The **deployment submodule** (`moritzzimmer/lambda/aws//modules/deployment`)
   creates a CodePipeline + CodeDeploy pipeline

For the full pattern with examples (canary, rollback, alarms), see
[references/deployment.md](references/deployment.md).

## Important guardrails

These matter because getting them wrong causes hard-to-debug issues:

- **fileexists() guard**: Always wrap `filebase64sha256()` — without it,
  `terraform validate` and `terraform plan` fail when the zip hasn't been built
  yet (e.g., in CI before the build step).

- **arm64 default**: Use `architectures = ["arm64"]` unless the user has a
  reason for x86_64 (e.g., native dependencies that don't support ARM). Graviton
  is ~20% cheaper and generally faster for Lambda.

- **Memory defaults by runtime**: Go/Node.js: 128MB. Python/.NET: 256MB.
  Java: 512MB. These reflect typical cold-start and memory needs — the user can
  always override.

- **snap_start is Java-only**: Setting it for other runtimes silently does
  nothing useful. Only suggest it when runtime is Java.

- **S3 bucket: use `.bucket`, not `.id`**: When passing an S3 bucket to the
  deployment module, always use `aws_s3_bucket.x.bucket` (the name string),
  not `aws_s3_bucket.x.id`. The `.id` attribute can cause "Invalid count
  argument" errors because the deployment module uses
  `count = var.s3_bucket != ""` at plan time.

- **lambda_at_edge + VPC are incompatible**: Lambda@Edge runs at CloudFront
  edge locations and cannot access a VPC.

- **reserved_concurrent_executions = 0 disables the function**: If the user
  wants to limit concurrency, suggest a positive number. Zero means "cannot run."

- **IAM is automatic**: The module attaches the right IAM policies based on
  which features are enabled (VPC, tracing, SSM, event sources, logs). Don't
  create separate IAM resources for these — it's already handled.

## After generation

**Verify the generated code builds.** After writing all files, run `make package`
(or the equivalent build command) to confirm the project compiles and packages
successfully. If it fails, fix the issue before presenting the result to the
user. Common causes: missing `using`/`import` statements, wrong package names
in build files, or mismatched handler signatures.

Once the files are written:

1. Suggest `make help` to see available targets
2. `make tf` runs `terraform init` + `terraform plan`
3. `make tf MODE=apply` to deploy
4. `make package` to just build the artifact without deploying

If the user wants to add features later (like adding an SQS trigger to an
existing function), read the current Terraform config and modify it — don't
regenerate from scratch.
