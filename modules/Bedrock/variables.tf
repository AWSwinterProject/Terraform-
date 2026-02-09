variable "vpc_id" {
  description = "VPC ID from network module"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private APP subnet IDs from network module"
  type        = list(string)
}


