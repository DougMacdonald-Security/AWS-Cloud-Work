terraform {
  source = "../../../modules/cloudwatch-event-rule"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  rule_name      = "ECR_Scans"
  event_pattern  = <<PATTERN
{
  "source": ["aws.eks"],
  "detail-type": ["ECR Image Scan"],
  "detail": {
    "scan-status": ["COMPLETE"]

    
  }
}
PATTERN
}
