terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "CreateRoleWithAction"
  event_pattern  = <<PATTERN
{
  "detail": {
    "eventSource": ["iam.amazonaws.com"],
    "eventName": ["CreateRole", "UpdateRole"],
    "requestParameters": {
      "assumeRolePolicyDocument": {
        "Statement": {
          "Action": ["*"]
        }
      }
    }
  }
}
PATTERN
}
