output "ecs_tasks_sg_id" {
  description = "ECS tasks security group ID"
  value       = aws_security_group.ecs_tasks_sg.id
}
