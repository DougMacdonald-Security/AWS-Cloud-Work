data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# ----------------------------------------------------------------------------------------------------------------------
# IP set Creation for WAF
# Make it a seperate File with Deployment and folder WAFIPSET resources
# Scope is defined in Vars
# ----------------------------------------------------------------------------------------------------------------------

#IPV4 sets

resource "aws_wafv2_ip_set" "WAFWhitelistSetV4" {
  name               = "WAFWhitelistSetV41"
  description        = "Block Bad IPV4 addresses"
  scope              = local.SCOPE
  ip_address_version = "IPV4"
  addresses          = []
}

resource "aws_wafv2_ip_set" "WAFBlacklistSetV4" {
  name               = "WAFBlacklistSetV41"
  description        = "Block Bad IPV6 addresses"
  scope              = local.SCOPE
  ip_address_version = "IPV6"
  addresses          = []
}


resource "aws_wafv2_ip_set" "WAFReputationListsSetV4" {
  count              = var.ReputationListsProtectionActivated == "yes" ? 1 : 0
  name               = "WAFReputationListsSetV41"
  description        = "Block Reputation List IPV4 addresses"
  scope              = local.SCOPE
  ip_address_version = "IPV4"
  addresses          = []
  lifecycle {
    ignore_changes = [
      addresses
    ]
  }
}

resource "aws_wafv2_ip_set" "WAFScannersProbesSetV4" {
  count              = var.ScannersProbesProtectionActivated == "yes" ? 1 : 0
  name               = "WAFScannersProbesSetV41"
  description        = "Block IP addresses that are scanning and probing IPV4 addresses"
  scope              = local.SCOPE
  ip_address_version = "IPV4"
  addresses          = []
}

#IPV6 sets

resource "aws_wafv2_ip_set" "WAFWhitelistSetV6" {
  name               = "WAFWhitelistSetV61"
  description        = "Block Bad IPV4 addresses"
  scope              = local.SCOPE
  ip_address_version = "IPV4"
  addresses          = []
}

resource "aws_wafv2_ip_set" "WAFBlacklistSetV6" {
  name               = "WAFBlacklistSetV61"
  description        = "Block Bad IPV6 addresses"
  scope              = local.SCOPE
  ip_address_version = "IPV6"
  addresses          = []
}


resource "aws_wafv2_ip_set" "WAFReputationListsSetV6" {
  count              = var.ReputationListsProtectionActivated == "yes" ? 1 : 0
  name               = "WAFReputationListsSetV61"
  description        = "Block Reputation List IPV6 addresses"
  scope              = local.SCOPE
  ip_address_version = "IPV4"
  addresses          = []
  lifecycle {
    ignore_changes = [
      addresses
    ]
  }
}

resource "aws_wafv2_ip_set" "WAFScannersProbesSetV6" {
  count              = var.ScannersProbesProtectionActivated == "yes" ? 1 : 0
  name               = "WAFScannersProbesSetV61"
  description        = "Block HTTP Flood IPV6 addresses"
  scope              = local.SCOPE
  ip_address_version = "IPV6"
  addresses          = []
}



# ----------------------------------------------------------------------------------------------------------------------
#   WAFWebACL:
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "dev_waf_acl" {
  name        = "wafwebacl-dev-rules"
  description = "Custom WAFWebACL for Dev Environment point to dev ALB"
  scope       = local.SCOPE
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFWebACL-dev-metric"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFWebACL-metric"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "aws-AWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "MetricForAMRCRS"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "WAFWhitelistRule1"
    priority = 1
    action {
      allow {}
    }

    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.WAFWhitelistSetV4.arn
          }
        }
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.WAFWhitelistSetV4.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "MetricForWhitelistRule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "WAFBlacklistRule1"
    priority = 2
    action {
      block {}
    }

    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.WAFBlacklistSetV4.arn
          }
        }
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.WAFBlacklistSetV4.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "MetricForBlacklistRule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "ScannersAndProbesRule"
    priority = 5
    action {
      block {}
    }

    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.WAFScannersProbesSetV4[0].arn
          }
        }
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.WAFScannersProbesSetV6[0].arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "MetricForScannersProbesRulee"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "IPReputationListsRule"
    priority = 6
    action {
      block {}
    }

    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.WAFReputationListsSetV4[0].arn
          }
        }
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.WAFReputationListsSetV6[0].arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "MetricForIPReputationListsRule"
      sampled_requests_enabled   = true
    }
  }

# ----------------------------------
# SQL Injection Rule - looks for sqli for query_string, body, uri_path
# authorization and cookie headers
# ----------------------------------
  rule {
    name     = "SqlInjectionRule"
    priority = 20
    action {
      block {
        custom_response {
          response_code = 400
          response_header {
            name = "testingwaf"
            value = "WAF header"
          
          }          
        }
      }
    }

    statement {
      or_statement {
        statement {
          sqli_match_statement {
            field_to_match {
              query_string {}
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }

            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
        statement {
          sqli_match_statement {
            field_to_match {
              body {}
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }

            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
        statement {
          sqli_match_statement {
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }

            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
        statement {
          sqli_match_statement {
            field_to_match {
              single_header {
                name = "authorization"
              }
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }

            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
        statement {
          sqli_match_statement {
            field_to_match {
              single_header {
                name = "cookie"
              }
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }

            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "MetricForSqlInjectionRule"
      sampled_requests_enabled   = true
    }
  }
# ----------------------------------
# XSS Rule - looks for XSS in query_string, body, uri_path
# authorization and cookie headers
# ----------------------------------
  rule {
    name     = "XssRule"
    priority = 30
    action {
      block {
        custom_response {
          response_code = 400
          response_header {
            name = "testingwaf"
            value = "WAF header"
          
          }
        }
      }
    }

    statement {
      or_statement {
        statement {
          xss_match_statement {
            field_to_match {
              query_string {}
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
        statement {
          xss_match_statement {
            field_to_match {
              body {}
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }

            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
        statement {
          xss_match_statement {
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }

            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
        statement {
          xss_match_statement {
            field_to_match {
              single_header {
                name = "cookie"
              }
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }

            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "MetricForXssRule"
      sampled_requests_enabled   = true
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Associate the dev acl with dev ALb
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_wafv2_web_acl_association" "devalb" {
  resource_arn = var.dev_alb_arn
  web_acl_arn  = aws_wafv2_web_acl.dev_waf_acl.arn
}


# # Configure WAF Logging
# resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
#   resource_arn = aws_wafv2_web_acl.example.arn
#   log_destination_configs {
#     log_type     = "FULL"
#     log_destination {
#       s3 {
#         bucket_arn = aws_s3_bucket.waf_logs_bucket.arn
#         prefix     = "waf-logs/"
#       }
#     }
#   }
# }