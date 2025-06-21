variable "alert_email" {
  description = "Email to send certificate expiry alerts"
  type        = string
}

variable "dynamodb_table" {
  description = "Name of the DynamoDB table with certificate data"
  type        = string
}

variable "dynamodb_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}

