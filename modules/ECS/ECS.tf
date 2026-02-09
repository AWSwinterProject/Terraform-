# ECS 클러스터
resource "aws_ecs_cluster" "coreon" {
  name = "coreon-intranet-cluster"
}

# ECS 용량 제공자 (Capacity Provider) - 메모리 기반 스케일링 핵심
resource "aws_ecs_capacity_provider" "coreon_cp" {
  name = "coreon-mem-scaling-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 80
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "coreon" {
  cluster_name       = aws_ecs_cluster.coreon.name
  capacity_providers = [aws_ecs_capacity_provider.coreon_cp.name]
}

locals {
  apps = {
    "nginx"   = { port = 80,   cpu = 128, mem = 128 }
    "redis"   = { port = 6379, cpu = 128, mem = 128 }
    "front"   = { port = 5500, cpu = 256, mem = 256 }
    "auth"    = { port = 8081, cpu = 128, mem = 200 }
    "member"    = { port = 8082, cpu = 128, mem = 200 }
    "faq"    = { port = 8083, cpu = 128, mem = 200 }
    "board"    = { port = 8084, cpu = 128, mem = 200 }
    "notice"  = { port = 8085, cpu = 128, mem = 200 }
  }
}

resource "aws_ecs_task_definition" "coreon_tasks" {
  for_each = local.apps

  family                   = "coreon-${each.key}"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.mem # Hard Limit 설정

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = "${var.ecr_url}/coreon-${each.key}:latest"
      essential = true
      portMappings = [{ containerPort = each.value.port, hostPort = each.value.port }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/coreon"
          "awslogs-region"        = "ap-northeast-2"
          "awslogs-stream-prefix" = each.key
        }
      }
    }
  ])
}

resource "aws_ecs_service" "coreon_services" {
  for_each        = local.apps
  name            = "${each.key}-service"
  cluster         = aws_ecs_cluster.coreon.id
  task_definition = aws_ecs_task_definition.coreon_tasks[each.key].arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.coreon_cp.name
    weight            = 100
  }

  network_configuration {
    subnets         = var.private_app_subnet_ids
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.coreon.arn
    service {
      port_name      = each.key
      discovery_name = each.key
      client_alias {
        port     = each.value.port
        dns_name = "${each.key}.coreon.local"
      }
    }
  }
}

resource "aws_service_discovery_http_namespace" "coreon" {
  name = "coreon.local"
}