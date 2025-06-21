

variable "log_group_name" {
  description = "CloudWatch Log Group receiving centralized logs"
  type        = string
  default     = "aws-controltower/CloudTrailLogs"
}

variable "alert_email" {
  description = "Email to receive alerts"
  type        = string
  default     = "dsml@gft.com"
}

variable "match_patterns" {
  description = "List of CloudWatch Logs filter patterns to monitor"
  type = list(object({
    name    = string
    pattern = string
  }))
  default = [
    {
      name    = "console-login-dsml"
      pattern = "{ ($.eventName = \"ConsoleLogin\") && ($.userIdentity.arn = \"*dsml@gft.com*\") }"
    }
  ]
}
