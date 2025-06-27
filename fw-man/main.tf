provider "aws" {
  region = "eu-west-2"
}

# Variables
variable "organization_id" {default = ["o-HASH"]}
variable "delegated_admin_account_id" {default = ["1234"]}
variable "accounts" {
  description = "List of accounts and their application names"
  type = list(object({
    account_id       = string
    application_name = string
  }))
  default = [
    {
      account_id       = "4321"
      application_name = "Network"
    }
  ]
}


variable "firehose_delivery_stream_name" {
  description = "Name of the Kinesis Data Firehose delivery stream"
  default     = "gib-waf-logs-delivery-stream"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for Firehose delivery"
  default     = "gib-waf-logs-bucket"
}

# Create an S3 bucket for Firehose delivery
resource "aws_s3_bucket" "firehose_bucket" {
  bucket = var.s3_bucket_name
}

# Create the Kinesis Data Firehose delivery stream
resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = var.firehose_delivery_stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_delivery_role.arn
    bucket_arn = aws_s3_bucket.firehose_bucket.arn

    buffering_size = 64

    # https://docs.aws.amazon.com/firehose/latest/dev/dynamic-partitioning.html
    dynamic_partitioning_configuration {
      enabled = "true"
    }

    # Example prefix using partitionKeyFromQuery, applicable to JQ processor
    prefix              = "data/customer_id=!{partitionKeyFromQuery:customer_id}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    processing_configuration {
      enabled = "true"

      # Multi-record deaggregation processor example
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor example
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor example
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{customer_id:.customer_id}"
        }
      }
    }
  }
}




# IAM role for Firehose to write to S3
resource "aws_iam_role" "firehose_delivery_role" {
  name = "FirehoseDeliveryRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_policy_attachment" "firehose_delivery_policy_attachment" {
  name = "FirehoseDeliveryPolicyAttachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  roles      = [aws_iam_role.firehose_delivery_role.name]
}

# Example: Create a WAF WebACL and associate with ALB
resource "aws_wafv2_web_acl" "gib-web-acl" {
  name        = "gib-web-acl"
  scope       = "REGIONAL"
  description = "GIB WAFv2 Web ACL"
  
  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "gib-web-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "gib-web-acl"
  }
}


# Firewall Manager configuration
resource "aws_fms_policy" "waf_policy" {
  depends_on = [aws_iam_policy_attachment.firehose_delivery_policy_attachment]

  name   = "CentralizedWAFPolicy"
  resource_type = "AWS::ElasticLoadBalancingV2::LoadBalancer"
  security_service_policy_data {
    type = "WAFV2"
    managed_service_data = jsonencode({
      type = "WAFV2",
      pre_process_rule_groups = [
        {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      ],
      post_process_rule_groups = [],
      defaultAction = {
      type = "allow"
      },
      overrideCustomerWebACLAssociation = false,
      visibility_config = {
        cloudwatch_metrics_enabled  = true,
        metric_name                 = "waf-policy",
        sampled_requests_enabled    = true
      }
    })
  }

  exclude_resource_tags = false
  remediation_enabled   = true

  include_map {
    account = var.accounts[*].account_id
  }
}
