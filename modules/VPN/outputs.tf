output "client_vpn_endpoint_id" {
  description = "Client VPN endpoint ID"
  value       = aws_ec2_client_vpn_endpoint.this.id
}

output "client_vpn_sg_id" {
  description = "Client VPN security group ID"
  value       = aws_security_group.client_vpn_sg.id
}
