variable "ami_id" {
  description = "The AMI ID to use for the instance."
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the instance."
  type        = string
}

variable "key_name" {
  description = "The key name to use for SSH access to the instance."
  type        = string
}

variable "instance_name" {
  description = "The name to assign to the instance."
  type        = string
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with the instance."
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "The subnet ID to launch the instance in."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID to launch the instance in."
  type        = string
}

variable "allowed_ssh_cidr_blocks" {
  description = "The list of CIDR blocks allowed to SSH into the instance."
  type        = list(string)
}

variable "root_volume_size" {
  description = "The size of the root volume in GB."
  type        = number
  default     = "30"
}

variable "log_retention_days" {
  description = "The number of days to retain CloudWatch logs."
  type        = number
  default     = "7"
}

variable "alarm_actions" {
  description = "The list of actions to take when the alarm state is triggered."
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to assign to the instance."
  type        = map(string)
  default     = {}
}
