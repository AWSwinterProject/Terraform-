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
    "nginx"  = { port = 80, cpu = 128, mem = 128 }
    "redis"  = { port = 6379, cpu = 128, mem = 128 }
    "front"  = { port = 5500, cpu = 256, mem = 256 }
    "auth"   = { port = 8081, cpu = 128, mem = 200 }
    "member" = { port = 8082, cpu = 128, mem = 200 }
    "faq"    = { port = 8083, cpu = 128, mem = 200 }
    "board"  = { port = 8084, cpu = 128, mem = 200 }
    "notice" = { port = 8085, cpu = 128, mem = 200 }
  }

  db_apps = toset(["auth", "member", "faq", "board", "notice"])

  aws_env = [
    { name = "AWS_ACCESS_KEY_ID", value = var.aws_access_key },
    { name = "AWS_SECRET_ACCESS_KEY", value = var.aws_secret_key },
    { name = "AWS_REGION", value = "ap-northeast-2" }
  ]

  db_env = [
    { name = "DB_NAME", value = var.db_name },
    { name = "DB_ADDRESS", value = var.db_address },
    { name = "DB_USERNAME", value = var.db_username },
    { name = "DB_PASSWORD", value = var.db_password },
    { name = "DB_PORT", value = "3306" }
  ]
}

# ─── ECS Task Execution Role (ECR pull + CloudWatch Logs) ─────────
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "coreon-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─── ECS Task Role (S3 + Bedrock) ─────────────────────────────────
resource "aws_iam_role" "ecs_task_role" {
  name = "coreon-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "ecs_task_s3_bedrock" {
  name = "coreon-ecs-task-s3-bedrock"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::coreon",
          "arn:aws:s3:::coreon/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3_bedrock" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_s3_bedrock.arn
}

# ─── Task Definitions ─────────────────────────────────────────────
resource "aws_ecs_task_definition" "coreon_tasks" {
  for_each = local.apps

  family                   = "coreon-${each.key}"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.mem # Hard Limit 설정
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    merge(
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
      },
      { environment = contains(local.db_apps, each.key) ? concat(local.aws_env, local.db_env) : local.aws_env }
    )
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

# ─── Amazon Linux 2 ECS Optimized AMI (SSM Parameter) ─────────────
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# ─── ECS EC2 인스턴스 IAM 역할 ──────────────────────────────────────
resource "aws_iam_role" "ecs_instance_role" {
  name = "coreon-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ec2" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "coreon-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# ─── Launch Template (t3.small, Amazon Linux 2 ECS Optimized) ─────
resource "aws_launch_template" "ecs" {
  name_prefix   = "coreon-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_tasks_sg.id]

  user_data = base64encode(<<-USERDATA
#!/bin/bash
echo "ECS_CLUSTER=coreon-intranet-cluster" >> /etc/ecs/ecs.config
USERDATA
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "coreon-ecs-instance"
    }
  }
}

# ─── Auto Scaling Group ─────────────────────────────────────────────
# 평상시 EC2 1대, Capacity Provider가 메모리 80% 이상 시 최대 2대로 확장
resource "aws_autoscaling_group" "ecs_asg" {
  name                = "coreon-ecs-asg"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
  vpc_zone_identifier = var.private_app_subnet_ids

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }
}

# ─── CloudWatch Log Group ───────────────────────────────────────────
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/coreon"
  retention_in_days = 30
}
