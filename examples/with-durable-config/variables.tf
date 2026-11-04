variable "region" {
  description = "AWS region in which to deploy the example. Must support Lambda durable functions."
  default     = "us-east-2"
  type        = string
}
