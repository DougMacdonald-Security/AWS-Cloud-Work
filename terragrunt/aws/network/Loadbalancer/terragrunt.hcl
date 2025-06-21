terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "SecurityGroupIngressUnencryptedPorts"
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
          "fromPort": [21, 23, 25, 80, 3306],
          "toPort": [21, 23, 25, 80, 3306]
        }
      }
    }
  }
}
PATTERN
}
