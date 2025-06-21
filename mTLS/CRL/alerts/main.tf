provider "aws" {
  region = "eu-west-2"
}

resource "aws_sns_topic" "cert_expiry_alerts" {
  name = "mTLSCertExpiryAlerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.cert_expiry_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_iam_role" "lambda_exec" {
  name = "cert-expiry-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "cert-expiry-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Scan"
        ],
        Resource = var.dynamodb_arn
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.cert_expiry_alerts.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/check_expiry.py"
  output_path = "${path.module}/lambda/check_expiry.zip"
}

resource "aws_lambda_function" "cert_expiry_check" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "cert-expiry-check"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "check_expiry.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DDB_TABLE      = var.dynamodb_table
      SNS_TOPIC_ARN  = aws_sns_topic.cert_expiry_alerts.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "daily-cert-expiry-check"
  schedule_expression = "cron(0 8 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "cert-expiry-lambda"
  arn       = aws_lambda_function.cert_expiry_check.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cert_expiry_check.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
}

