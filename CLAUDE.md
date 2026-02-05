# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform infrastructure project for AWS (ap-northeast-2 region) named "coreon". Deploys a multi-tier VPC architecture with Lambda-based PDF processing.

## Common Commands

```bash
# Initialize Terraform (run from stage/ directory)
cd stage && terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Format code
terraform fmt -recursive
```

## Architecture

### Directory Structure
- `stage/` - Environment configuration (entry point), references modules
- `modules/network/` - VPC module with 3-tier subnet architecture
- `modules/service/` - Lambda function for S3-triggered PDF processing

### Network Module (`modules/network/`)
Creates a VPC with:
- Public subnets (internet-facing via IGW)
- Private app subnets (for application workloads)
- Private DB subnets (for databases)
- Separate route tables for public/private traffic

All resources are tagged with Project, Environment, and ManagedBy tags.

### Service Module (`modules/service/`)
- Lambda function triggered by S3 uploads to `coreon` bucket
- Monitors `board/` prefix for PDF files
- Requires `lambda_function.zip` deployment package

### Module Usage
Modules are referenced via relative paths from stage/:
```hcl
module "vpc" {
  source = "../modules/network"
  # ...variables...
}
```

## Requirements

- Terraform >= 1.6.0
- AWS Provider ~> 5.0
