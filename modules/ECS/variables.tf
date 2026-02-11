
variable "ecr_url" {
  description = "ECR repository URL"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private app subnet IDs"
  type        = list(string)
}

variable "db_name" {
  description = "RDS database name"
  type        = string
}

variable "db_address" {
  description = "RDS instance hostname (address)"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "aws_access_key" {
  description = "AWS access key for ECS containers"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key for ECS containers"
  type        = string
  sensitive   = true
}