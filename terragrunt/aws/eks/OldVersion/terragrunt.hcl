terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "EKSClusterUnsupportedVersion"
  event_pattern  = <<PATTERN
{
  "source": ["aws.eks"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["eks.amazonaws.com"],
    "eventName": [
      "CreateCluster",
      "UpdateClusterVersion"
    ],
    "requestParameters": {
      "version": [
        "1.18",
        "1.19",
        "1.20"
      ]
    },
    "userIdentity": {
      "accountId": ["533267118313","010928204850"]
    }
  }
}
PATTERN
}
