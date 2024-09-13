# Example with CloudWatch logs configuration

Creates an AWS Lambda function with CloudWatch logs subscription filters and configured retention time.

## usage

```
terraform init
terraform plan
terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` to destroy those resources.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.32 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_destination_1"></a> [destination\_1](#module\_destination\_1) | ../../ | n/a |
| <a name="module_destination_2"></a> [destination\_2](#module\_destination\_2) | ../../ | n/a |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | ../../ | n/a |
| <a name="module_source"></a> [source](#module\_source) | ../fixtures | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"eu-west-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | The name of the CloudWatch log group used by your Lambda function. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | The unique name of your Lambda Function. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the IAM role attached to the Lambda Function. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->