# GitHub Actions OIDC mapped role to trigger deployments

Terraform module to create an AWS IAM role that can be used with OpenID Connect[^1] to trigger [deployments](../deployment)
from GitHub Actions. The role can be used with `configure-aws-credentials`[^3].

# Prerequisites

The GitHub identity provider must already be added to the AWS account. See the GitHub documentation[^2].

# How to use

Create a role like this

```terraform
module "github_role" {
  source = "moritzzimmer/lambda/aws//modules/github-actions-role"

  github_repository = "moritzzimmer/my-lambda"

  # Both s3_prefixes and ecr_repositories are optional, but if neither are set the role can't do anything
  s3_prefixes      = ["my-deploy-bucket/my-lambda"]
  ecr_repositories = ["my-ecr-repository"]

  role_name   = "my-role" # Optional, will be github-actions-my-lambda-eu-central-1 otherwise
  github_refs = ["main", "production"] # Optional, defaults to ["main"]
}
```

It can then be used in a GitHub Action workflow like this

```yaml
name: My Workflow

on:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v5

      # Your build steps here

      - name: configure aws credentials
        uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: arn:aws:iam::$account-id:role/my-role
          role-session-name: GitHubActions
          aws-region: $region

      # Your steps using AWS, e.g. S3 put, ECR push
```

# References

[^1]: https://docs.github.com/en/actions/concepts/security/openid-connect
[^2]: https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws#adding-the-identity-provider-to-aws
[^3]: https://github.com/aws-actions/configure-aws-credentials
