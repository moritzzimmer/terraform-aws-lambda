# Copilot Review Instructions — terraform-aws-lambda

## Project context
Terraform module published to the Terraform Registry. See AGENTS.md for full project details.

## Review focus areas

### Terraform patterns (do NOT flag these as issues)
- `count = var.x ? 1 : 0` for conditional resources — this is intentional
- `for_each = var.x == null ? [] : [var.x]` for optional dynamic blocks
- `compileOnly` for AWS Lambda Java runtime dependencies — Lambda provides these at runtime
- `fileexists()` guards around `filebase64sha256()` — required for CI validation without build artifacts
- Alphabetical attribute ordering within resource blocks — this is enforced convention

### Dual resource blocks in main.tf
`main.tf` contains TWO `aws_lambda_function` resources (one normal, one with ignore_changes lifecycle).
This is intentional — both must be updated when adding new attributes. Do not suggest merging them.

### Do flag
- New variables missing explicit types or descriptions
- New variables added outside alphabetical order in the OPTIONAL section
- Changes to only one of the two `aws_lambda_function` resources when both need updating
- IAM permissions that are too broad (should follow least privilege)
- Missing `count` or `for_each` conditionals on new resources that should be optional

### Generated content
Do NOT suggest changes to text between `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` — auto-generated.

### Commit and PR style
- Conventional commits: feat:, fix:, chore:, refactor:, docs:, ci:
- Lowercase subject, no period at end
