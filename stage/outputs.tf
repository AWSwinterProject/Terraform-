# stage/network/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  # module.모듈명.모듈내부output명
  value       = module.vpc.vpc_id 
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  value       = module.vpc.private_app_subnet_ids
}