provider "aws" {
  region = "eu-west-2"
}

resource "aws_s3_bucket" "secure_bucket" {
  bucket = var.bucket_name
}
resource "aws_s3_bucket_lifecycle_configuration" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
 id = "log"

    expiration {
      days = 90
    }

    filter {
      and {
        prefix = "log/"

        tags = {
          rule      = "log"
          autoclean = "true"
        }
      }
    }

    status = "Enabled"

  }
}

resource "aws_s3_bucket_public_access_block" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.bucket

  versioning_configuration {
    status = "Enabled"
    # MFA Delete (CIS 2.7)
    #mfa_delete = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.bucket

  target_bucket = var.logging_bucket
  target_prefix = "log/"
}

resource "aws_s3_bucket_policy" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.bucket

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "EnforceTLS",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}/*",
        "arn:aws:s3:::${var.bucket_name}"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }]
}
EOF
}

# Enable CloudTrail logging for bucket (CIS 3.1)
#resource "aws_cloudtrail" "trail" {
#  name                          = "${var.bucket_name}-trail"
#  s3_bucket_name                = var.logging_bucket
#  include_global_service_events = true
#  enable_logging                = true
#  is_multi_region_trail         = true

#  event_selector {
#    read_write_type           = "All"
#    include_management_events = true

#    data_resource {
#      type   = "AWS::S3::Object"
#      values = ["arn:aws:s3:::${aws_s3_bucket.secure_bucket.arn}/"]
#    }
#  }
#}
