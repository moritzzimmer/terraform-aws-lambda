# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "iam_role_name" {
  description = "The name of the IAM role to attach stream policy configuration."
}

variable "event_source_arn" {
  description = "Event source ARN of a KinesDynamoDb stream."
}

variable "function_name" {
  description = "The name or the ARN of the Lambda function that will be subscribing to events. "
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "batch_size" {
  default     = 100
  description = "The largest number of records that Lambda will retrieve from your event source at the time of invocation. Defaults to 100 for DynamoDB and Kinesis."
}

variable "bisect_batch_on_function_error" {
  default     = false
  description = "If the function returns an error, split the batch in two and retry. Only available for stream sources (DynamoDB and Kinesis). Defaults to false."
}

variable "destination_config" {
  default     = null
  description = "An Amazon SQS queue or Amazon SNS topic destination for failed records. Only available for stream sources (DynamoDB and Kinesis). Detailed below."
}

variable "enable" {
  default     = false
  description = "Conditionally enables this module (and all it's ressources)."
}

variable "event_source_mapping_enabled" {
  default     = true
  description = "Determines if the mapping will be enabled on creation. Defaults to true."
}

variable "maximum_batching_window_in_seconds" {
  default     = null
  description = "The maximum amount of time to gather records before invoking the function, in seconds (between 0 and 300). Records will continue to buffer (or accumulate in the case of an SQS queue event source) until either maximum_batching_window_in_seconds expires or batch_size has been met. For streaming event sources, defaults to as soon as records are available in the stream. If the batch it reads from the stream/queue only has one record in it, Lambda only sends one record to the function."
}

variable "maximum_record_age_in_seconds" {
  default     = 604800
  description = "The maximum age of a record that Lambda sends to a function for processing. Only available for stream sources (DynamoDB and Kinesis). Minimum of 60, maximum and default of 604800."
}

variable "maximum_retry_attempts" {
  default     = 10000
  description = "The maximum number of times to retry when the function returns an error. Only available for stream sources (DynamoDB and Kinesis). Minimum of 0, maximum and default of 10000."
}

variable "parallelization_factor" {
  default     = null
  description = "The number of batches to process from each shard concurrently. Only available for stream sources (DynamoDB and Kinesis). Minimum and default of 1, maximum of 10."
}

variable "starting_position" {
  default     = "TRIM_HORIZON"
  description = "The position in the stream where AWS Lambda should start reading. Must be one of either TRIM_HORIZON or LATEST. Defaults to TRIM_HORIZON."
}

variable "starting_position_timestamp" {
  default     = null
  description = "A timestamp in RFC3339 format of the data record which to start reading when using starting_position set to AT_TIMESTAMP. If a record with this exact timestamp does not exist, the next later record is chosen. If the timestamp is older than the current trim horizon, the oldest available record is chosen."
}

variable "topics" {
  default     = null
  description = "A timestamp in RFC3339 format of the data record which to start reading when using starting_position set to AT_TIMESTAMP. If a record with this exact timestamp does not exist, the next later record is chosen. If the timestamp is older than the current trim horizon, the oldest available record is chosen."
}
