terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "GuardDutyHighSeverityFindings"
  event_pattern  = <<PATTERN
{
  "source": ["aws.guardduty"],
  "detail-type": ["GuardDuty Finding"],
  "detail": {
    "severity": [{
      "numeric": [">=", 9.0]
    }]
  }
}
PATTERN
}
