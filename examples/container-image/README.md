# Example without event

Creates an AWS Lambda function using a [container image](https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html).

## requirements

- [Terraform 0.12+](https://www.terraform.io/)
- authentication configuration for the [aws provider](https://www.terraform.io/docs/providers/aws/)

## usage

```
terraform init
terraform plan
terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` to destroy those resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| aws | >= 3.19 |
| docker | >= 2.8.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.19 |
| docker | >= 2.8.0 |

## Inputs

No input.

## Outputs

No output.
