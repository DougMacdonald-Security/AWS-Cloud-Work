provider "aws" {
  region = "eu-west-2"
}



resource "aws_kms_key" "truststore_kms_key" {
  description             = "KMS key for mTLS Truststore Prod"
  deletion_window_in_days = 30

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "EnableIAMUserPermissions",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "AllowTrustedAccountKMSAccess",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::1234:root" # Trusted Account
        },
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        Resource = "*"
      }
    ]
  })
}
# openssl genrsa -out PrivateCA.key 4096
# openssl req -new -x509 -days 3650 -key PrivateCA.key -out PrivateCA.pem -subj "/CN=sec.company.com"
# openssl genrsa -out client.key 2048
# openssl req -new -key client.key -out client.csr -subj "/CN=mtls.company.com"
# openssl x509 -req -in client.csr -CA PrivateCA.pem -CAkey PrivateCA.key -set_serial 01 -out client.pem -days 3650 -sha256
# aws s3 cp truststore-prod.pem s3://gib-inbound-mtls-truststore-prod  --sse aws:kms --sse-kms-key-id arn:aws:kms:eu-west-2:1234:key/cebe5601-19d62b19

resource "aws_lb_trust_store" "truststore" {
  depends_on = [aws_s3_bucket.secure_bucket]
  name = "mtls-truststore-prod"

  # Use the S3 bucket and key for the CA certificates bundle
  ca_certificates_bundle_s3_bucket = "inbound-mtls-truststore-prod"
  ca_certificates_bundle_s3_key    = "truststore.pem"
}

resource "aws_ram_resource_share" "truststore_share" {
  name                      = "mtls-truststore-prod"
  allow_external_principals = false

  tags = {
    Environment = "Production"
  }
}

# AWS RAM Principal Association for Trusted Account
resource "aws_ram_principal_association" "truststore_account" {
  resource_share_arn = aws_ram_resource_share.truststore_share.arn
  principal          = "1234" # Network Account
}

# AWS RAM Resource Association for ALB Trust Store
resource "aws_ram_resource_association" "truststore_resource" {
  resource_share_arn = aws_ram_resource_share.truststore_share.arn
  resource_arn       = aws_lb_trust_store.truststore.arn
}


# Data Block for Current AWS Account ID
data "aws_caller_identity" "current" {}
