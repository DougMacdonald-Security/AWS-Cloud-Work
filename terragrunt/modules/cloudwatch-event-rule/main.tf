provider "aws" {
  region = "eu-west-2"
}
resource "aws_cloudwatch_event_rule" "rule" {
  name        = var.rule_name
  description = "Event rule for filtering CloudWatch events"
  event_pattern = var.event_pattern
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule = aws_cloudwatch_event_rule.rule.name
  arn  = var.sns_topic_arn

  input_transformer {
    input_paths = {
      EventId           = "$.id"
      EventTime         = "$.detail.eventTime"
      EventName         = "$.detail.eventName"
      EventAccountId    = "$.account"
      EventSourceIp     = "$.detail.sourceIPAddress"
      EventRegion       = "$.region"
      EventBlame        = "$.detail.userIdentity.principalId"
      EventBlameDetails = "$.detail.userIdentity.sessionContext.sessionIssuer.userName"
    }

    input_template = <<TEMPLATE
{
  "🆔 EventId": "<EventId>",
  "🕑 EventTime": "<EventTime>",
  "👉 EventName": "<EventName>",
  "🧾 EventAccountId": "<EventAccountId>",
  "🌐 EventSourceIp": "<EventSourceIp>",
  "🌏 EventRegion": "<EventRegion>",
  "👤 EventBlame": "<EventBlame>",
  "📃 EventBlameDetails": "<EventBlameDetails>"
}
TEMPLATE
  }
}

resource "aws_sns_topic_policy" "cloudwatch_events_publish" {
  arn    = var.sns_topic_arn
  policy = data.aws_iam_policy_document.cloudwatch_events_sns_policy.json
}