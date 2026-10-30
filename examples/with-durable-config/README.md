# Example with durable configuration

Creates an AWS Lambda [durable function](https://docs.aws.amazon.com/lambda/latest/dg/durable-functions.html).
The module attaches the `AWSLambdaBasicDurableExecutionRolePolicy` managed policy to the function role.

Durable functions are only available in some regions. This example uses `us-east-2`.
The example deploys the shared fixture handler. A real durable function uses the durable execution SDK in its handler code.

## usage

```
terraform init
terraform plan
```

Note that this example may create resources which cost money. Run `terraform destroy` to destroy those resources.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.25.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_fixtures"></a> [fixtures](#module\_fixtures) | ../fixtures | n/a |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-east-2"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
