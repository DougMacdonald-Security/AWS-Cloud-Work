variable "AppAccessLogBucket" {
  description = "Application Access Log Bucket Name for WAF Deployment"
  type        = string
  default = ""
}


variable "ReputationListsProtectionActivated" {
  type        = string
  default     = "yes"
  description = ""
  validation {
    condition     = contains(["yes", "no"], var.ReputationListsProtectionActivated)
    error_message = "Invalid input, options: \"yes\",\"no\"."
  }
}

variable "ScannersProbesProtectionActivated" {
  type        = string
  default     = "yes"
  description = ""
}

variable "dev_alb_arn" {
  description = "ARN of the ALB to associate with the WAF web ACL"
  type        = string
}

variable "ENDPOINT" {
  description = "cloudfront or ALB for WAF deploy"
  type        = string
  default     = "ALB"
  validation {
    condition     = contains(["cloudfront", "ALB"], var.ENDPOINT)
    error_message = "Invalid input, options: \"cloudfront\",\"ALB\"."
  }
}

locals {
  LOG_TYPE = var.ENDPOINT == "ALB" ? "alb" : "cloudFront"
}

locals {
  SCOPE = var.ENDPOINT == "ALB" ? "REGIONAL" : "CLOUDFRONT"
}