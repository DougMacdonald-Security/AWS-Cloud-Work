terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "S3BucketPublicAccess"
  event_pattern  = <<PATTERN
{
  "source": ["aws.s3"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["s3.amazonaws.com"],
    "eventName": [
      "PutBucketAcl",
      "PutBucketPolicy",
      "PutObjectAcl"
    ],
    "requestParameters": {
      "AccessControlList": {
        "grants": {
          "grantee": {
            "uri": [
              "http://acs.amazonaws.com/groups/global/AllUsers",
              "http://acs.amazonaws.com/groups/global/AuthenticatedUsers"
            ]
          }
        }
      },
      "bucketPolicy": {
        "Statement": [
          {
            "Principal": {
              "AWS": "*"
            }
          }
        ]
      }
    }
  }
}
PATTERN
}
