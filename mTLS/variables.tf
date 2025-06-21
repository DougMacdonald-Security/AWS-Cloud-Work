variable "domain_name" {
  type    = string
  default = "api.gib53dev.com"
}

variable "regional_certificate_arn" {
  type    = string
  default = "arn:aws:acm:eu-west-2:905418475562:certificate/8ebcb5d5-6886-4083-a11e-06a2f65301ab"
  sensitive = true
}

variable "ownership_verification_certificate_arn" {
  type    = string
  default = "arn:aws:acm:eu-west-2:905418475562:certificate/502b3ca4-eba9-45db-bee1-81991a96a855"
  sensitive = true
}

variable "truststore_uri" {
  type    = string
  default = "s3://gib-sandbox-cert01/ca-cert.pem"
}

variable "truststore_version" {
  type    = string
  default = "56WvlDD5ubH0ojWLUlQcds8kRFHfrU9V"
}