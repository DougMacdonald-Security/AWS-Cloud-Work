provider "aws" {
  region = "eu-west-2"
}
terraform {
  backend "s3" {
    bucket         = "s3-tfstate-management-euw2"
    key            = "cloudwatch/cis-alerts.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}

resource "aws_sns_topic" "alert_topic" {
  name = "security-alert-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alert_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "cloudwatch_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_permissions" {
  name = "lambda-cloudwatch-sns"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.alert_topic.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda_function_payload.zip"
}

resource "aws_lambda_function" "parser_lambda" {
  function_name = "cloudwatch-log-parser"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  role    = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alert_topic.arn
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {

  statement_id  = "AllowExecutionFromLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.parser_lambda.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}:*"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_subscription_filter" "log_filter" {
  name                = "central-log-subscription"
  log_group_name      = var.log_group_name
  filter_pattern      = "" # Match all logs
  destination_arn     = aws_lambda_function.parser_lambda.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch]
}
