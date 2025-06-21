
variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "logging_bucket" {
  description = "The name of the S3 bucket to send access logs to."
  type        = string
  default     = "arn:aws:s3:::aws-cloudtrail-logs-381491825821-19f0d353"
}
