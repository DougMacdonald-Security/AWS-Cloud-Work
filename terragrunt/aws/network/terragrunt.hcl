

locals {
  log_group_name    = "aws-cloudtrail-logs-1234-5b64dd33"
  sns_topic_arn     = "arn:aws:sns:eu-west-2:1234:aws-security-survival-kit-alarm-topic-eu-west-2-global"
}

inputs = {
  log_group_name    = local.log_group_name
  sns_topic_arn     = local.sns_topic_arn
}
