resource "aws_iam_role" "iam-dev-LambdaReputationListsParserRole" {
  count = var.ReputationListsProtectionActivated == "yes" ? 1 : 0
  name  = "iam-dev-LambdaReputationListsParserRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"     
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ec2reputation" {
  count  = var.ReputationListsProtectionActivated == "yes" ? 1 : 0
  name   = "ec2reputation"
  role   = aws_iam_role.iam-dev-LambdaReputationListsParserRole[0].id
  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:CreateNetworkInterface"
            ],
            "Resource": [
                "arn:aws:lambda:eu-central-1:1234:/*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOT
  depends_on = [
    aws_iam_role.iam-dev-LambdaReputationListsParserRole
  ]
}

resource "aws_iam_role_policy" "CloudWatchLogsListsParser" {
  count  = var.ReputationListsProtectionActivated == "yes" ? 1 : 0
  name   = "CloudWatchLogs1"
  role   = aws_iam_role.iam-dev-LambdaReputationListsParserRole[0].id
  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-central-1:1234:log-group:/aws/lambda/ReputationListsParserlog" 
            ],
            "Effect": "Allow"
        }
    ]
}
EOT
  depends_on = [
    aws_iam_role.iam-dev-LambdaReputationListsParserRole
  ]
}

resource "aws_iam_role_policy" "sqsreputation" {
  count  = var.ReputationListsProtectionActivated == "yes" ? 1 : 0
  name   = "sqsreputation"
  role   = aws_iam_role.iam-dev-LambdaReputationListsParserRole[0].id
  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sqs:SendMessage"
            ],
            "Resource": [
                "arn:aws:sqs:eu-central-1:1234:*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOT
  depends_on = [
    aws_iam_role.iam-dev-LambdaReputationListsParserRole
  ]
}

resource "aws_iam_role_policy" "CloudWatchAccessListsParser" {
  count  = var.ReputationListsProtectionActivated == "yes" ? 1 : 0
  name   = "CloudWatchAccessListsParser"
  role   = aws_iam_role.iam-dev-LambdaReputationListsParserRole[0].id
  policy = <<EOT
{
    "Statement": [
        {
            "Action": "cloudwatch:GetMetricStatistics",
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOT
  depends_on = [
    aws_iam_role.iam-dev-LambdaReputationListsParserRole
  ]
}

resource "aws_iam_role_policy" "WAFGetAndUpdateIPListsParser" {
  name   = "WAFGetAndUpdateIPSet1"
  role   = aws_iam_role.iam-dev-LambdaReputationListsParserRole[0].id
  policy = <<EOT
{
    "Statement": [
        {
            "Action": [
                "wafv2:GetIPSet",
                "wafv2:UpdateIPSet"
            ],
            "Resource": [
                "arn:aws:wafv2:eu-central-1:1234:regional/ipset/WAFReputationListsSetV41/6aaff27c-4baa-4f1f-a988-0de889dad722",
                "arn:aws:wafv2:eu-central-1:1234:regional/ipset/WAFReputationListsSetV61/c84aae18-a520-41f7-8102-173a52abde8e"
                ],
            "Effect": "Allow"
        }
    ]
}
EOT
  depends_on = [
    aws_iam_role.iam-dev-LambdaReputationListsParserRole
  ]
}
