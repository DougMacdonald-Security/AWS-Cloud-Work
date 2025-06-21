terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "SecurityGroupIngressPort21_22"
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
          "fromPort": [21, 22],
          "toPort": [21, 22]
        }
      }
    }
  }
}
PATTERN
}
