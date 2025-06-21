terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name        = "RootAccountActivity"
  event_pattern    = <<PATTERN
{
  "detail": {
    "userIdentity": {
      "type": ["Root"]
    }
  }
}
PATTERN
}
