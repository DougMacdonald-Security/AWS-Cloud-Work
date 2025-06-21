terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "UserCreateDelete"
  event_pattern  = <<PATTERN
{
  "detail": {
    "eventSource": ["iam.amazonaws.com"],
    "eventName": [
      {
        "prefix": "Delete"
      },
      {
        "prefix": "Create"
      }
    ]
  }
}
PATTERN
}
