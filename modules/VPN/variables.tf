variable "project" {
  description = "Project name"
  type        = string
  default     = "coreon"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private app subnet IDs"
  type        = list(string)
}

variable "client_vpn_cidr" {
  description = "Client VPN CIDR block"
  type        = string
  default     = "172.16.0.0/16"
}

variable "vpn_server_cert_arn" {
  description = "ACM server certificate ARN for VPN"
  type        = string
}

variable "client_vpn_ca_cert_arn" {
  description = "ACM CA certificate ARN for client authentication"
  type        = string
}

variable "app_subnet_cidrs" {
  type = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}