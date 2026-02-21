# ─── ECS 태스크 보안그룹 ────────────────────────────────────────────
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "coreon-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all traffic within SG"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Allow front(5500) from ALB"
    from_port       = 5500
    to_port         = 5500
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  ingress {
    description     = "Allow backend services(8081-8085) from ALB"
    from_port       = 8081
    to_port         = 8085
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  ingress {
    description = "Allow all traffic from VPN (10.8.0.0/24)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.8.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
