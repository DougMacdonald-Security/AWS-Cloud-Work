terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "NoMFA"
  event_pattern  = <<PATTERN
{
  "detail": {
    "eventName": ["ConsoleLogin"],
    "additionalEventData": {
      "MFAUsed": ["No"]
    }
  }
}
PATTERN
}
