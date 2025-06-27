variable "domain_name" {
  type    = string
  default = "api.company.com"
}

variable "regional_certificate_arn" {
  type    = string
  default = "arn:aws:acm:eu-west-2:1234:certificate/8ebcb-301ab"
  sensitive = true
}

variable "ownership_verification_certificate_arn" {
  type    = string
  default = "arn:aws:acm:eu-west-2:1234:certificate/502b3ca4-eb91a96a855"
  sensitive = true
}

variable "truststore_uri" {
  type    = string
  default = "s3://gib-sandbox-cert01/ca-cert.pem"
}

variable "truststore_version" {
  type    = string
  default = "0987abc"
}
