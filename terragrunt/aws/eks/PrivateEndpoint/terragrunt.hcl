terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "EKSClusterPublicEndpoint"
  event_pattern  = <<PATTERN
{
  "source": ["aws.eks"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["eks.amazonaws.com"],
    "eventName": [
      "CreateCluster",
      "UpdateClusterConfig"
    ],
    "requestParameters": {
      "resourcesVpcConfig": {
        "endpointPublicAccess": [true]
      }
    },
    "userIdentity": {
      "accountId": ["533267118313","010928204850"]
    }
  }
}
PATTERN
}
