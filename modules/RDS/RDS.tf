
resource "aws_db_subnet_group" "coreon" {
  name       = "coreon-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = { Name = "coreon-db-subnet-group" }
}

# ─── RDS 인스턴스 (MySQL, t3.micro) ─────────────────────────────
resource "aws_db_instance" "coreon_db" {
  identifier            = "coreon-database"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.coreon.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
  publicly_accessible = false
  multi_az            = false

  tags = { Name = "coreon-db-instance" }
}
