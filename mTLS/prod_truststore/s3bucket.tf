terraform {
  backend "s3" {
    bucket         = "security-bucket"
    key            = "tfstate/mtls.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}

resource "aws_s3_bucket" "secure_bucket" {
  bucket = "inbound-mtls-truststore-prod"
}

resource "aws_s3_bucket_ownership_controls" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
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
        "arn:aws:s3:::inbound-mtls-truststore-prod/*",
        "arn:aws:s3:::inbound-mtls-truststore-prod"
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
