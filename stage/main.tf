terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

module "vpc" {
  source = "../modules/network"

  # 변수 전달 (각자의 환경에 맞는 변수명을 사용하세요)
  region                   = "ap-northeast-2"
  vpc_cidr                 = "10.0.0.0/16"
  azs                      = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  private_db_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]
}


module "bedrock" {
  source = "../modules/Bedrock"

  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
}


module "ECR" {
  source = "../modules/ECR"
}

# module "ECS" {
#   source = "../modules/ECS"
#
#   ecr_url                = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com"
#   vpc_id                 = module.vpc.vpc_id
#   private_app_subnet_ids = module.vpc.private_app_subnet_ids
#
#   db_name     = var.db_name
#   db_address  = module.RDS.rds_address
#   db_username = var.db_username
#   db_password = var.db_password
#
#   aws_access_key = var.aws_access_key
#   aws_secret_key = var.aws_secret_key
# }

module "RDS" {
  source = "../modules/RDS"

  vpc_id                = module.vpc.vpc_id
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  # ecs_tasks_sg_id       = module.ECS.ecs_tasks_sg_id
  # client_vpn_sg_id       = module.VPN.client_vpn_sg_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

# module "VPN" {
#   source = "../modules/VPN"
#
#   vpc_id                 = module.vpc.vpc_id
#   private_app_subnet_ids = module.vpc.private_app_subnet_ids
#   vpn_server_cert_arn    = var.vpn_server_cert_arn
#   client_vpn_ca_cert_arn = var.vpn_ca_cert_arn
# }

data "aws_caller_identity" "current" {}
