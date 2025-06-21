data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "random_uuid" "test" {
}

resource "random_id" "server" {
  byte_length = 8
}

locals {
  AppLogBucket = "${var.AppAccessLogBucket}-${random_id.server.hex}"
}

# -------------------------------------------
# S3 Bucket for WAF Logs
# Will be used for HTTP FloodProtection 
# Access logs for this S3 bucket is stored in Accesslog bucket WAF_logs
# -------------------------------------------

resource "aws_s3_bucket" "WafLogBucket" {
  count         = local.HttpFloodProtectionLogParserActivated == "yes" ? 1 : 0
  bucket        = "${random_id.server.hex}-waflogbucket"
  acl           = "private"
  force_destroy = true
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.sse_algorithm
      }
    }
  }
  logging {
    target_bucket = aws_s3_bucket.accesslogbucket[0].bucket
    target_prefix = "WAF_Logs/"
  }
}

resource "aws_s3_bucket_public_access_block" "WafLogBucket" {
  count                   = local.HttpFloodProtectionLogParserActivated == "yes" ? 1 : 0
  bucket                  = aws_s3_bucket.WafLogBucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on = [
    aws_s3_bucket.WafLogBucket
  ]
}

resource "aws_s3_bucket_policy" "wafbucketpolicy" {
  count         = local.HttpFloodProtectionLogParserActivated == "yes" ? 1 : 0
  bucket = aws_s3_bucket.WafLogBucket[0].id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.s3bucketaccessrole.name}"
                ]
            },
            "Action": "s3:*",
            "Resource": [
                "${aws_s3_bucket.WafLogBucket[0].arn}",
                "${aws_s3_bucket.WafLogBucket[0].arn}/*"
            ]
        },
        {
            "Sid": "HttpsOnly",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "${aws_s3_bucket.WafLogBucket[0].arn}",
                "${aws_s3_bucket.WafLogBucket[0].arn}/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
  depends_on = [
    aws_s3_bucket.WafLogBucket
  ]
}


data "aws_iam_policy" "s3Access" {
  arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role" "s3bucketaccessrole" {
  name  = "s3-bucket-role-${random_id.server.hex}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "s3bucketaccessrole-policy-attach" {
  role       = "${aws_iam_role.s3bucketaccessrole.name}"
  policy_arn = "${data.aws_iam_policy.s3Access.arn}"
}

resource "aws_iam_role" "replication" {
  count = local.HttpFloodProtectionLogParserActivated == "yes" ? 1 : 0
  name  = "tf-iam-role-${random_id.server.hex}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  count = local.HttpFloodProtectionLogParserActivated == "yes" ? 1 : 0
  name  = "tf-iam-role-policy-${random_id.server.hex}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.WafLogBucket[0].arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.WafLogBucket[0].arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  count = local.HttpFloodProtectionLogParserActivated == "yes" ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

# ----------------------------------------------------------------
# AccessLoggingBucket for Parsing access logs
# Enabled if LogParser is set to Yes
# ----------------------------------------------------------------

resource "aws_s3_bucket" "accesslogbucket" {
  count         = local.LogParser == "yes" ? 1 : 0
  bucket        = "${random_id.server.hex}-accesslogging"
  acl           = "log-delivery-write"
  force_destroy = true
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.sse_algorithm
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "accesslogbucket" {
  count                   = local.LogParser == "yes" ? 1 : 0
  bucket                  = aws_s3_bucket.accesslogbucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on = [
    aws_s3_bucket.accesslogbucket
  ]
}

resource "aws_s3_bucket_policy" "b" {
  count  = local.LogParser == "yes" ? 1 : 0
  bucket = aws_s3_bucket.accesslogbucket[0].id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.s3bucketaccessrole.name}"
                ]
            },
            "Action": "s3:*",
            "Resource": [
                "${aws_s3_bucket.accesslogbucket[0].arn}",
                "${aws_s3_bucket.accesslogbucket[0].arn}/*"
            ]
        },
        {
            "Sid": "HttpsOnly",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "${aws_s3_bucket.accesslogbucket[0].arn}",
                "${aws_s3_bucket.accesslogbucket[0].arn}/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
  depends_on = [
    aws_s3_bucket.accesslogbucket
  ]
}

resource "aws_iam_role" "replicationaccesslog" {
  count = local.LogParser == "yes" ? 1 : 0
  name  = "tf-iam-role-replication-${random_id.server.hex}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replicationaccesslog" {
  count  = local.LogParser == "yes" ? 1 : 0
  name   = "tf-iam-role-policy-repl-${random_id.server.hex}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.accesslogbucket[0].arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.accesslogbucket[0].arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "test-attach-log" {
  count  = local.LogParser == "yes" ? 1 : 0
  role       = aws_iam_role.replicationaccesslog[0].name
  policy_arn = aws_iam_policy.replicationaccesslog[0].arn
}