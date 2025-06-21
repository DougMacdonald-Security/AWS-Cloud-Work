terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "CloudTrailAndGuardDutyChanges"
  event_pattern  = <<PATTERN
{
  "source": [
    "aws.cloudtrail",
    "aws.guardduty"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "cloudtrail.amazonaws.com",
      "guardduty.amazonaws.com"
    ],
    "eventName": [
      "CreateTrail",
      "UpdateTrail",
      "DeleteTrail",
      "StartLogging",
      "StopLogging",
      "CreateDetector",
      "UpdateDetector",
      "DeleteDetector"
    ]
  }
}
PATTERN
}
