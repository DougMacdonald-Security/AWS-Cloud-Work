terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "AccessKeyCreateDelete"
  event_pattern  = <<PATTERN
{
  "detail": {
    "eventSource": ["iam.amazonaws.com"],
    "eventName": ["CreateAccessKey", "DeleteAccessKey"]
  }
}
PATTERN
}
