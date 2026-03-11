# Go runtime example

Creates an AWS Lambda function from a Go project using the `provided.al2023` custom runtime.

## Prerequisites

- Go 1.24+

## Usage

```shell
make tf MODE=apply
```

Run `make help` to see all available targets.

Note that this example may create resources which cost money. Run `make tf MODE=destroy` to destroy those resources.
