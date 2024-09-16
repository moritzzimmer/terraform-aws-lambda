# Example with Amazon EventBridge (CloudWatch Events)

Creates an AWS Lambda function triggered by Amazon EventBridge (CloudWatch Events) [rules](https://docs.aws.amazon.com/lambda/latest/dg/services-cloudwatchevents.html).

## Usage

To run this example execute:

```
$ terraform init
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` to destroy those resources.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.32 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.32 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda"></a> [lambda](#module\_lambda) | ../../ | n/a |
| <a name="module_source"></a> [source](#module\_source) | ../fixtures | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_lambda_alias.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_alias) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"eu-west-1"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->