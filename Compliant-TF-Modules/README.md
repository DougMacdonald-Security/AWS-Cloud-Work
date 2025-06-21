# S3 Secure Bucket Terraform Module

This module creates an S3 bucket that adheres to AWS security best practices and the CIS AWS Foundations Benchmark v3 framework.

## Features

- Blocks public access (CIS 2.1, 2.2, 2.3, 2.4)
- Enables versioning (CIS 2.5)
- Enforces server-side encryption (CIS 2.8)
- Configures logging (CIS 2.9)
- Enforces TLS (CIS 2.6)
- Supports MFA delete (CIS 2.7)
- Logs object-level write events (CIS 3.1)
- Logs object-level read events (CIS 3.1)

## Usage

```hcl
module "s3_secure_bucket" {
  source          = "./s3_secure_bucket"
  region          = "eu-west-2"
  bucket_name     = "my-secure-bucket"
  logging_bucket  = "my-logging-bucket"
  mfa_delete      = true
}
