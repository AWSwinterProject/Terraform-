
# ─── RDS 보안 그룹 (ECS 태스크에서 오는 요청만 허용) ────────────────
resource "aws_security_group" "rds_sg" {
  name        = "coreon-rds-sg"
  description = "Allow inbound traffic from ECS tasks only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    # security_groups = [var.ecs_tasks_sg_id]
    # security_groups = [var.client_vpn_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "coreon-rds-sg" }
}
