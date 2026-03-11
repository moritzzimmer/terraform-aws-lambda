package main

import (
	"context"
	"runtime"

	"github.com/aws/aws-lambda-go/lambda"
)

type response struct {
	StatusCode   int    `json:"statusCode"`
	Runtime      string `json:"runtime"`
	Architecture string `json:"architecture"`
	Message      string `json:"message"`
}

func handler(ctx context.Context) (*response, error) {
	return &response{
		StatusCode:   200,
		Runtime:      runtime.Version(),
		Architecture: runtime.GOARCH,
		Message:      "Hello from Go Lambda!",
	}, nil
}

func main() {
	lambda.Start(handler)
}
