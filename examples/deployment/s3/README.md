# Example using CodePipeline deployment of S3 packaged function

Creates a S3 packaged AWS Lambda function deployed using AWS CodePipeline and CodeDeploy.

## usage

```
terraform init
terraform plan
```

Note that this example may create resources which cost money. Run `terraform destroy` to destroy those resources.

### deploy

Upload a new `zip` package to S3 to start the deployment pipeline:

```shell
aws s3api put-object --bucket example-ci-{account_id}-{region} --key with-s3-codepipeline/package/lambda.zip --body lambda.zip
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.19 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.55.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_deployment"></a> [deployment](#module\_deployment) | ../../../modules/deployment | n/a |
| <a name="module_function"></a> [function](#module\_function) | ../../fixtures | n/a |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | ../../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_lambda_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_alias) | resource |
| [aws_s3_bucket.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_object.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_public_access_block.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
