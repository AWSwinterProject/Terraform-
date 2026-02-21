variable "vpc_id" {
  description = "VPC ID (network 모듈 output)"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private app subnet ID 목록 (network 모듈 output)"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR — ALB SG 인그레스 허용 범위"
  type        = string
  default     = "10.0.0.0/16"
}
