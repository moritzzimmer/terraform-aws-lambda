# Python runtime example

Creates an AWS Lambda function from a Python project using uv as the package manager and aws-lambda-powertools.

## Prerequisites

- Python 3.14+
- [uv](https://docs.astral.sh/uv/)

## Usage

```shell
make tf MODE=apply
```

Run `make help` to see all available targets.

Note that this example may create resources which cost money. Run `make tf MODE=destroy` to destroy those resources.
