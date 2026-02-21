output "alb_dns_name" {
  description = "ALB DNS 이름 (Route53 Alias 또는 CNAME 등록용)"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_sg_id" {
  description = "ALB 보안 그룹 ID"
  value       = aws_security_group.alb_sg.id
}

output "target_group_arns" {
  description = "서비스별 Target Group ARN 맵 (front, auth, member, faq, board, notice)"
  value       = { for k, tg in aws_lb_target_group.services : k => tg.arn }
}
