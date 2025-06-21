# ----------------------------------------------------------------------------------------------------------------------
# CloudWatch Dashboard
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "MonitoringDashboard-${data.aws_region.current.name}"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 15,
      "height": 10,
      "properties": {
        "metrics":[
                      ["WAF", "BlockedRequests", "WebACL", "WAFWebACLMetric", "Rule", "ALL", "Region", "${data.aws_region.current.name}" ],
                      ["WAF", "AllowedRequests", "WebACL", "WAFWebACLMetric", "Rule", "ALL", "Region", "${data.aws_region.current.name}" ]
            ],
        "view": "timeSeries",
        "stacked": false,
        "stat": "Sum",
        "period": 300,
        "region": "${data.aws_region.current.name}"
      }
    }
  ]
}
EOF
}