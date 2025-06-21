# EC2 Secure Instance Terraform Module

This module creates an EC2 instance that adheres to AWS security best practices and the CIS AWS Foundations Benchmark v3 framework.

## Features

- Configures IAM roles and policies for least privilege
- Uses security groups to control inbound and outbound traffic
- Enforces monitoring and logging via CloudWatch
- Ensures root volume encryption
- Sets up CloudWatch alarms for high CPU utilization
- Enables verbose SSH logging

## Usage

```hcl
module "ec2_secure_instance" {
  source              = "./ec2_secure_instance"
  region              = "eu-west-2"
  ami_id              = "ami-0abcdef1234567890"
  instance_type       = "t3.micro"
  key_name            = "my-key-pair"
  instance_name       = "secure-instance"
  associate_public_ip = false
  subnet_id           = "subnet-0abcdef1234567890"
  vpc_id              = "vpc-0abcdef1234567890"
  allowed_ssh_cidr_blocks = ["203.0.113.0/24"]
  root_volume_size    = 30
  log_retention_days  = 90
  alarm_actions       = ["arn:aws:sns:eu-west-2:123456789012:my-sns-topic"]
  tags = {
    "Environment" = "production"
    "Owner"       = "team-security"
  }
}
