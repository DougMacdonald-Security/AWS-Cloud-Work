terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "S3UnencryptedBucketCreation"
  event_pattern  = <<PATTERN
{
  "source": ["aws.s3"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["s3.amazonaws.com"],
    "eventName": ["CreateBucket", "PutBucketEncryption"],
    "requestParameters": {
      "serverSideEncryptionConfiguration": {
        "rules": {
          "applyServerSideEncryptionByDefault": {
            "sseAlgorithm": [null, "None"]
          }
        }
      }
    }
  }
}
PATTERN
}
