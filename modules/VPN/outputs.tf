output "vpn_instance_id" {
  description = "VPN EC2 instance ID"
  value       = aws_instance.vpn.id
}

output "vpn_public_ip" {
  description = "VPN Elastic IP (public)"
  value       = aws_eip.vpn.public_ip
}

output "vpn_sg_id" {
  description = "VPN security group ID"
  value       = aws_security_group.vpn_sg.id
}
