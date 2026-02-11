resource "aws_security_group" "client_vpn_sg" {
  name   = "${var.project}-${var.env}-client-vpn-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = "${var.project}-${var.env}-client-vpn"
  vpc_id                 = var.vpc_id
  client_cidr_block      = var.client_vpn_cidr
  server_certificate_arn = var.vpn_server_cert_arn

  split_tunnel = true

  security_group_ids = [aws_security_group.client_vpn_sg.id]

  authentication_options {
    type = "certificate-authentication"
    root_certificate_chain_arn = var.client_vpn_ca_cert_arn
  }

  connection_log_options {
    enabled = false
  }
}

# VPC 연결(Private APP subnet 2개 연결)
resource "aws_ec2_client_vpn_network_association" "private_app" {
  count                  = length(var.private_app_subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.private_app_subnet_ids[count.index]
}


# VPN → VPC 라우트
# resource "aws_ec2_client_vpn_route" "to_app" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
#   destination_cidr_block = "10.0.0.0/16"
#   target_vpc_subnet_id   = var.private_app_subnet_ids[0]
#
#   depends_on = [aws_ec2_client_vpn_network_association.private_app]
# }
# 접근 허용(앱에만 접근할 수 있도록)
resource "aws_ec2_client_vpn_authorization_rule" "allow_app" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = "10.0.0.0/16"
  authorize_all_groups   = true
}