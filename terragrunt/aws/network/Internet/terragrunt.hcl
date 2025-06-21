terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "SecurityGroupIngressChange"
  event_pattern  = <<PATTERN
{
  "source": ["aws.ec2"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["ec2.amazonaws.com"],
    "eventName": [
      "AuthorizeSecurityGroupIngress",
      "RevokeSecurityGroupIngress"
    ],
    "requestParameters": {
      "ipPermissions": {
        "items": {
          "ipRanges": {
            "items": {
              "cidrIp": ["0.0.0.0/0"]
            }
          }
        }
      }
    }
  }
}
PATTERN
}
