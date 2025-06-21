provider "aws" {
  region = "eu-west-2"
}

resource "aws_instance" "secure_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  monitoring                  = true
  associate_public_ip_address = var.associate_public_ip

  iam_instance_profile = aws_iam_instance_profile.secure_profile.name

  vpc_security_group_ids = [aws_security_group.secure_sg.id]
  subnet_id              = var.subnet_id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(
    var.tags,
    {
      "Name" = var.instance_name
    }
  )
}

resource "aws_iam_role" "secure_role" {
  name = "ec2_secure_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "secure_role_policy" {
  name   = "ec2_secure_policy"
  role   = aws_iam_role.secure_role.id
  policy = file("secure_role_policy.json")
}

resource "aws_iam_instance_profile" "secure_profile" {
  name = "ec2_secure_profile"
  role = aws_iam_role.secure_role.name
}

resource "aws_security_group" "secure_sg" {
  name        = "ec2_secure_sg"
  description = "Security group for secure EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "secure_log_group" {
  name              = "/aws/ec2/${var.instance_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "${var.instance_name}_cpu_utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  alarm_actions = var.alarm_actions

  dimensions = {
    InstanceId = aws_instance.secure_instance.id
  }
}

resource "aws_ssm_association" "enable_ssh_logging" {
  name       = "AWS-RunShellScript"
  targets    = [{ Key = "InstanceIds", Values = [aws_instance.secure_instance.id] }]
  parameters = {
    commands = [
      "echo 'LogLevel VERBOSE' >> /etc/ssh/sshd_config",
      "systemctl restart sshd"
    ]
  }
}
