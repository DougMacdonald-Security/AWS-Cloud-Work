terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "EKSContainersNonRootEnforcement"
  event_pattern  = <<PATTERN
{
  "source": ["aws.eks"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["eks.amazonaws.com"],
    "eventName": [
      "CreatePod",
      "UpdatePod",
      "CreatePodSecurityPolicy",
      "UpdatePodSecurityPolicy"
    ],
    "requestParameters": {
      "spec": {
        "securityContext": {
          "runAsNonRoot": [false, null]
        }
      }
    }
  }
}
PATTERN
}
