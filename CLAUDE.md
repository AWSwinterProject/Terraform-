# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform infrastructure project for AWS (ap-northeast-2, Seoul) named "coreon". Deploys a multi-tier VPC, Lambda-based PDF summarization via Bedrock, ECR repositories, and ECS services for a microservice-based intranet application.

## Common Commands

All Terraform commands must be run from the `stage/` directory:

```bash
cd stage && terraform init
cd stage && terraform validate
cd stage && terraform plan
cd stage && terraform apply
cd stage && terraform fmt -recursive ..
```

## Architecture

### Entry Point

`stage/main.tf` is the root configuration. It instantiates modules via relative paths (`source = "../modules/<name>"`), sets the AWS provider to ap-northeast-2, and passes variables (VPC CIDR, AZs, subnet CIDRs) to each module.

### Modules

**`modules/network/`** — VPC with 3-tier subnet architecture (public, private-app, private-db) across 2 AZs (ap-northeast-2a, 2c). Uses `count` based on `length(var.azs)` for subnet creation. Public subnets route through an IGW; private subnets share a separate route table. VPC CIDR: `10.0.0.0/16`.

**`modules/Bedrock/`** — Lambda function (`coreon-pdf-summarizer`, Node.js 18.x) triggered by S3 ObjectCreated events on the `coreon` bucket under `board/*.pdf`. Reads PDFs, sends to Bedrock Claude model for Korean-language summarization, writes JSON results to `summary/` prefix. Deployment package built via `archive_file` data source from `src/` directory. IAM role grants S3 read/write, Bedrock invoke, and CloudWatch Logs access.

**`modules/ECR/`** — 8 ECR repositories (auth, board, member, notice, faq, nginx, front, redis) created via `for_each`. Each has a lifecycle policy keeping the latest 10 images.

**`modules/ECS/`** — ECS cluster (`coreon-intranet-cluster`) with 8 task definitions/services for the microservice apps. Uses `awsvpc` network mode with Service Connect (namespace: `coreon.local`). Port mapping: nginx:80, redis:6379, front:5500, auth:8081, member:8082, faq:8083, board:8084, notice:8085. **Note:** This module references `aws_autoscaling_group.ecs_asg` and `aws_security_group.ecs_tasks_sg` that are not yet defined, and is not yet instantiated in `stage/main.tf`.

### Conventions

- Naming: `${project}-${environment}-${resource}` (e.g., `coreon-dev-vpc`)
- Tagging: All resources get `Project`, `Environment`, `ManagedBy` tags via locals
- State: Local backend in `stage/` (terraform.tfstate)

## Requirements

- Terraform >= 1.6.0
- AWS Provider ~> 5.0 (locked to 5.100.0)
