terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "CreateRoleWithExternalId"
  event_pattern  = <<PATTERN
{
  "detail": {
    "eventSource": ["iam.amazonaws.com"],
    "eventName": ["CreateRole"],
    "requestParameters": {
      "assumeRolePolicyDocument": {
        "Statement": {
          "Condition": {
            "StringEquals": {
              "sts:ExternalId": ["*"]
            }
          }
        }
      }
    }
  }
}
PATTERN
}
