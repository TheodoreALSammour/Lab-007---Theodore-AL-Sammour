variable "region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (must not be 10.0.0.0/16)"
  type        = string
}

variable "public_subnets" {
  description = "List of 2 CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of 2 CIDR blocks for the private subnets"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for all instances"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "full_name" {
  description = "Your full name — injected into the web and backend pages"
  type        = string
}

variable "db_password" {
  description = "Database password stored in SSM as a SecureString"
  type        = string
  sensitive   = true
}

variable "app_env" {
  description = "Application environment value stored in SSM (e.g. production)"
  type        = string
  default     = "production"
}
