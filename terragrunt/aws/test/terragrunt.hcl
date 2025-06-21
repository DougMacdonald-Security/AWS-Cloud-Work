terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "IAMPolicyChangeAlert"
  event_pattern  = <<PATTERN
{
  "source": ["aws.iam"],
  "detail": {
    "eventSource": ["iam.amazonaws.com"]
  }
}
PATTERN
}