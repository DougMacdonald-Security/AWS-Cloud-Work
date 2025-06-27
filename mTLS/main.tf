provider "aws" {
  region = "eu-west-2"
}


# IAM Role for Lambda to Access Secrets Manager (if Lambda is used)
resource "aws_iam_role" "lambda_execution_role" {
  name = "IncomingAPI_lambda_execution_role"

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

  tags = {
    Name = "Lambda Execution Role for mTLS"
  }
}

# IAM Policy for Lambda to Access Secrets Manager
resource "aws_iam_policy" "lambda_secrets_policy" {
  name        = "IncomingAPI_lambda_secrets_policy"
  description = "IAM policy to allow Lambda to access secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to the Role
resource "aws_iam_role_policy_attachment" "lambda_secrets_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}

# Create API Gateway with mTLS enabled using the existing certificate
resource "aws_api_gateway_domain_name" "mtls_domain" {
  domain_name = var.domain_name
  security_policy = "TLS_1_2"
  regional_certificate_arn = var.regional_certificate_arn
  ownership_verification_certificate_arn = var.ownership_verification_certificate_arn 
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  mutual_tls_authentication {
    truststore_uri = var.truststore_uri
    truststore_version = var.truststore_version
  }

  tags = {
    Name = "Incoming mTLS API Gateway"
    map-migrated = "Yup"
  }
}

# Create an API Gateway REST API
# Define the API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = "Incoming-api"
  description = "API acting as Thredd"
}

# Create the API Gateway resource
resource "aws_api_gateway_resource" "status_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "status"
}

# Create the GET method for the /status resource
resource "aws_api_gateway_method" "get_status" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.status_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Add the Mock Integration for the GET /status method
resource "aws_api_gateway_integration" "get_status_mock" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.status_resource.id
  http_method = aws_api_gateway_method.get_status.http_method
  type        = "MOCK"

  # Specify the mock response template
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Add Method Response for GET /status
resource "aws_api_gateway_method_response" "get_status_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.status_resource.id
  http_method = aws_api_gateway_method.get_status.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Add Integration Response for GET /status
resource "aws_api_gateway_integration_response" "get_status_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.status_resource.id
  http_method = aws_api_gateway_method.get_status.http_method
  status_code = aws_api_gateway_method_response.get_status_200.status_code

  response_templates = {
    "application/json" = jsonencode({
      message = "I'm OK"
    })
  }
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration_response.get_status_200,
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "test"
}

# Output the API Gateway endpoint
output "api_endpoint" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/status"
}


# Attach the domain name to the API
resource "aws_api_gateway_base_path_mapping" "mtls_mapping" {
  domain_name = aws_api_gateway_domain_name.mtls_domain.domain_name
  api_id      = aws_api_gateway_rest_api.api.id
}

