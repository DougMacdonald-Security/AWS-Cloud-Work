variable "ReputationListsProtectionActivated" {
  type        = string
  default     = "yes"
  description = ""
  validation {
    condition     = contains(["yes", "no"], var.ReputationListsProtectionActivated)
    error_message = "Invalid input, options: \"yes\",\"no\"."
  }
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

variable "USER_AGENT_EXTRA" {
  description = "UserAgent"
  type        = string
  default     = "AwsSolution/SO0006/v3.2.0"
}

variable "LOG_LEVEL" {
  description = "Log level"
  type        = string
  default     = "INFO"
}

variable "SEND_ANONYMOUS_USAGE_DATA" {
  description = "Data collection parameter"
  type        = string
  default     = "yes"
}

variable "MetricsURL" {
  description = "Metrics URL"
  type        = string
  default     = "https://metrics.awssolutionsbuilder.com/generic"
}

variable "SolutionID" {
  description = "UserAgent id value"
  type        = string
  default     = "SO0006"
}

variable "SourceBucket" {
  description = "Lambda source code bucket not required for WAF Deployment"
  type        = string
  default     = "network-tfstate-backend"
}
variable "KeyPrefix" {
  description = "Keyprefix values for the lambda source code Automation Only"
  type        = string
  default     = "aws-waf-security-automations/v3.2.0"
}

variable "ActivateReputationListsProtectionParam" {
  type    = string
  default = "yes"

  # using contains()
  validation {
    condition     = contains(["yes", "no"], var.ActivateReputationListsProtectionParam)
    error_message = "Invalid input, options: \"yes\",\"no\"."
  }
}

locals {
  SCOPE = var.ENDPOINT == "ALB" ? "REGIONAL" : "CLOUDFRONT"
}

locals {
  LOG_TYPE = var.ENDPOINT == "ALB" ? "alb" : "cloudFront"
}
