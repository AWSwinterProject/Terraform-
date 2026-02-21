locals {
  name = "coreon-dev"
  tags = {
    Project     = "coreon"
    Environment = "dev"
    ManagedBy   = "terraform"
  }

  # 서비스별 Target Group 설정 (컨테이너 포트 기준)
  all_tgs = {
    front  = { port = 80 }
    auth   = { port = 8081 }
    member = { port = 8082 }
    faq    = { port = 8083 }
    board  = { port = 8084 }
    notice = { port = 8085 }
  }

  # 경로 기반 라우팅 룰 (front은 default action이므로 제외)
  routing_rules = {
    auth   = { priority = 10, path_patterns = ["/api/auth*"] }
    member = { priority = 20, path_patterns = ["/api/member*"] }
    faq    = { priority = 30, path_patterns = ["/api/faq*"] }
    board  = { priority = 40, path_patterns = ["/api/board*"] }
    notice = { priority = 50, path_patterns = ["/api/notice*"] }
  }
}

# 1. ALB 전용 보안 그룹
resource "aws_security_group" "alb_sg" {
  name        = "${local.name}-alb-sg"
  description = "Security group for Internal API ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-alb-sg"
  })
}

# 2. Internal Application Load Balancer
resource "aws_lb" "this" {
  name               = "${local.name}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.private_app_subnet_ids

  tags = merge(local.tags, {
    Name = "${local.name}-alb"
  })
}

# 3. 서비스별 Target Group (IP 타입 — awsvpc 네트워크 모드 대응)
resource "aws_lb_target_group" "services" {
  for_each    = local.all_tgs
  name        = "${local.name}-${each.key}-tg"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path     = "/health"
    interval = 30
    matcher  = "200-399"
  }

  tags = merge(local.tags, {
    Name = "${local.name}-${each.key}-tg"
  })
}

# 4. 80포트 리스너 — 기본값: front(UI) 서비스로 포워드
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["front"].arn
  }
}

# 5. 경로 기반 라우팅 룰 (/api/<service>* → 각 서비스 TG)
resource "aws_lb_listener_rule" "services" {
  for_each     = local.routing_rules
  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.path_patterns
    }
  }
}
