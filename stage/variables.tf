variable "db_name" {
  description = "RDS database name"
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

variable "vpn_server_cert_arn" {
  description = "ACM server certificate ARN for Client VPN"
  type        = string
}

variable "vpn_ca_cert_arn" {
  description = "ACM CA certificate ARN for Client VPN authentication"
  type        = string
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
