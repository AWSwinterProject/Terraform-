
output "rds_address" {
  description = "RDS instance hostname"
  value       = aws_db_instance.coreon_db.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.coreon_db.port
}
