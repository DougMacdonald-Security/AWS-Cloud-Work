variable "event_pattern" {
  description = "The event pattern used to filter events"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN to send events to"
  type        = string
}

variable "rule_name" {
  description = "Name of the CloudWatch Event Rule"
  type        = string
}
