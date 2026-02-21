
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

variable "target_group_arns" {
  description = "서비스별 ALB Target Group ARN 맵 (front, auth, member, faq, board, notice)"
  type        = map(string)
}

variable "alb_sg_id" {
  description = "ALB Security Group ID (ECS SG 인그레스 허용용)"
  type        = string
}

variable "ec2_key_name" {
  description = "EC2 SSH 키 페어 이름 (natvpn.pem)"
  type        = string
}