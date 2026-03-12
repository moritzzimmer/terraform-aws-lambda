# Rust runtime example

Creates an AWS Lambda function from a Rust project using the `provided.al2023` custom runtime.

## Prerequisites

- Rust 1.85+
- [cargo-lambda](https://www.cargo-lambda.info/guide/installation.html)

## Usage

```shell
make tf MODE=apply
```

Run `make help` to see all available targets.

Note that this example may create resources which cost money. Run `make tf MODE=destroy` to destroy those resources.
