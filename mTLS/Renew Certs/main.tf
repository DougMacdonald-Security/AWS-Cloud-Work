provider "aws" {
  region = "eu-west-2"
}

resource "aws_iam_role" "lambda_acm_check_role" {
  name = "lambda_acm_check_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "acm_read_only_policy" {
  name        = "ACMReadOnlyPolicy"
  description = "Read-only access to ACM certificates"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "acm:ListCertificates",
          "acm:DescribeCertificate"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "acm_read_only_attachment" {
  role       = aws_iam_role.lambda_acm_check_role.name
  policy_arn = aws_iam_policy.acm_read_only_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_attachment" {
  role       = aws_iam_role.lambda_acm_check_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "sns_full_access_attachment" {
  role       = aws_iam_role.lambda_acm_check_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}


resource "aws_lambda_function" "acm_check_lambda" {
  function_name = "acm_check_lambda"
  role          = aws_iam_role.lambda_acm_check_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = "lambda.zip"  # Path to your zipped Lambda function

  environment {
    variables = {
      SNS_TOPIC_ARN = "arn:aws:sns:eu-west-2:891377009330:Security-Notifications"
    }
  }
}

resource "aws_cloudwatch_event_rule" "daily_acm_check" {
  name        = "daily_acm_check"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "target" {
  rule = aws_cloudwatch_event_rule.daily_acm_check.name
  arn  = aws_lambda_function.acm_check_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acm_check_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_acm_check.arn
}

