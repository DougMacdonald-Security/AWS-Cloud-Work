output "instance_id" {
  description = "The ID of the EC2 instance."
  value       = aws_instance.secure_instance.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance."
  value       = aws_instance.secure_instance.arn
}
