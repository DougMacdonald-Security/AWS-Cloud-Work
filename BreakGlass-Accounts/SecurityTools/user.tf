# Provider configuration
provider "aws" {
  region = "eu-west-2"
  alias  = "management"
}
data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
}
variable "emailAddress" {
  type        = string
  description = "Enter the email address to subscribe to the SNS notification"
  default = "doug.macdonald@gft.com"
}
# Break-glass IAM User
resource "aws_iam_user" "break_glass_user" {
  provider   = aws.management
  name       = "break-glass-user"
  force_destroy = true
}

# Attach an Admin Policy to the user (modify this as per least-privilege requirements)
resource "aws_iam_user_policy_attachment" "break_glass_user_policy" {
  provider     = aws.management
  user         = aws_iam_user.break_glass_user.name
  policy_arn   = "arn:aws:iam::aws:policy/AdministratorAccess"
}
resource "aws_iam_policy" "BreakGlassAssumeRole" {
  name        = "BreakGlassAssumeRole"
  description = "BreakGlassAssumeRole"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = "arn:aws:iam::*:role/BreakGlassRole"
      },
    ]
  })
}
resource "aws_iam_user_policy_attachment" "assume-role" {
  user       = aws_iam_user.break_glass_user.name
  policy_arn = aws_iam_policy.BreakGlassAssumeRole.arn
}

# Enable MFA for the break-glass user
#resource "aws_iam_user_mfa_device" "break_glass_user_mfa" {
#  provider    = aws.management
#  user        = aws_iam_user.break_glass_user.name
#  serial_number = "arn:aws:iam::891377009330:mfa/break-glass-user"  # MFA YubiKeys have been delivered
#}


resource "aws_cloudwatch_event_rule" "login-event" {
  name        = "capture-breakglass-user-sign-in"
  description = "Capture breakglass user AWS Console Sign In"

  event_pattern = <<EOF
{
  "detail-type": ["AWS Console Sign In via CloudTrail"],
  "source": ["aws.signin"],
  "detail": {
    "eventSource": ["signin.amazonaws.com"],
    "eventName": ["ConsoleLogin"],
    "userIdentity": {
      "type": ["IAMUser"],
      "userName": ["break-glass-user"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "login-target" {
  rule      = aws_cloudwatch_event_rule.login-event.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.aws_logins.arn
  input_transformer {
    input_paths = {
      EventTime         = "$.detail.eventTime"
      EventName         = "$.detail.eventName"
      EventAccountId    = "$.account"
      EventSourceIp     = "$.detail.sourceIPAddress"
      EventRegion       = "$.region"
      EventBlameDetails = "$.detail.userIdentity.userName"
    }

    input_template = <<EOF
{
  "🕑 EventTime": "<EventTime>",
  "👉 EventName": "<EventName>",
  "🧾 EventAccountId": "<EventAccountId>",
  "🌐 EventSourceIp": "<EventSourceIp>",
  "🌏 EventRegion": "<EventRegion>",
  "📃 EventBlameDetails": "<EventBlameDetails>"
}
EOF
  }
}

// Cloudwatch Alarm for breakglass user switch role

resource "aws_cloudwatch_event_rule" "switch-event" {
  name        = "capture-breakglass-user-switch-role"
  description = "Capture breakglass user switching roles"

  event_pattern = <<EOF
{
  "source": ["aws.signin"],
  "detail-type": ["AWS Console Sign In via CloudTrail"],
  "detail": {
    "eventSource": ["signin.amazonaws.com"],
    "eventName": ["SwitchRole"],
    "userIdentity": {
      "type": ["IAMUser"],
      "userName": ["break-glass-user"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "switch-target" {
  rule      = aws_cloudwatch_event_rule.switch-event.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.aws_logins.arn
  input_transformer {
    input_paths = {
      EventTime         = "$.detail.eventTime"
      EventName         = "$.detail.eventName"
      EventAccountId    = "$.account"
      EventSourceIp     = "$.detail.sourceIPAddress"
      EventRegion       = "$.region"
      EventBlameDetails = "$.detail.userIdentity.userName"
    }

    input_template = <<EOF
{
  "🕑 EventTime": "<EventTime>",
  "👉 EventName": "<EventName>",
  "🧾 EventAccountId": "<EventAccountId>",
  "🌐 EventSourceIp": "<EventSourceIp>",
  "🌏 EventRegion": "<EventRegion>",
  "📃 EventBlameDetails": "<EventBlameDetails>"
}
EOF
  }
}

// Cloudwatch Alarm for breakglass user assume role

resource "aws_cloudwatch_event_rule" "assume-event" {
  name        = "capture-breakglass-user-assume-role"
  description = "Capture breakglass user assuming roles via the CLI"

  event_pattern = <<EOF
{
  "source": ["aws.sts"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["sts.amazonaws.com"],
    "eventName": ["AssumeRole"],
    "userIdentity": {
      "type": ["IAMUser"],
      "userName": ["break-glass-user"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "assume-target" {
  rule      = aws_cloudwatch_event_rule.assume-event.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.aws_logins.arn
  input_transformer {
    input_paths = {
      EventTime         = "$.detail.eventTime"
      EventName         = "$.detail.eventName"
      EventAccountId    = "$.account"
      EventSourceIp     = "$.detail.sourceIPAddress"
      EventRegion       = "$.region"
      EventBlameDetails = "$.detail.userIdentity.userName"
    }

    input_template = <<EOF
{
  "🕑 EventTime": "<EventTime>",
  "👉 EventName": "<EventName>",
  "🧾 EventAccountId": "<EventAccountId>",
  "🌐 EventSourceIp": "<EventSourceIp>",
  "🌏 EventRegion": "<EventRegion>",
  "📃 EventBlameDetails": "<EventBlameDetails>"
}
EOF
  }
}

//SNS topic creation
resource "aws_sns_topic" "aws_logins" {
  name              = "breakglassuser-console-logins"
  kms_master_key_id = "alias/breakglassSNS"
}

resource "aws_sns_topic_subscription" "sns-topic" {
  topic_arn = aws_sns_topic.aws_logins.arn
  protocol  = "email"
  endpoint  = var.emailAddress
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.aws_logins.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.aws_logins.arn]
  }
}

resource "aws_kms_key" "kmskey" {
  description             = "BreakGlass SNS Topic"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.keypolicy.json
  enable_key_rotation     = true
}
resource "aws_kms_alias" "alias" {
  name          = "alias/breakglassSNS"
  target_key_id = aws_kms_key.kmskey.key_id
}

data "aws_iam_policy_document" "keypolicy" {
  statement {
    sid       = "allow_events_to_decrypt_key"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
    ]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }

  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }
}

