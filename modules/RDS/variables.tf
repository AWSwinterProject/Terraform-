# ─── Network (from VPC module) ────────────────────────────────────
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "Private DB subnet IDs"
  type        = list(string)
}

# variable "ecs_tasks_sg_id" {
#   description = "ECS tasks security group ID (for RDS ingress)"
#   type        = string
# }

# ─── RDS settings ─────────────────────────────────────────────────
variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# variable "client_vpn_sg_id"{
#   type        = string
# }