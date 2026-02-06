# Minisource Infrastructure - Terraform

This directory contains Terraform configurations for deploying Minisource microservices.

## Structure

```
terraform/
├── environments/        # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/            # Reusable Terraform modules
│   ├── database/
│   ├── redis/
│   ├── service/
│   └── network/
└── global/             # Global resources (DNS, certificates, etc.)
```

## Prerequisites

- Terraform >= 1.0
- Docker (for local development)
- kubectl (for Kubernetes deployments)
- Cloud provider CLI (AWS, GCP, or Azure)

## Quick Start

### Local Development (Docker Compose)

```bash
# Use docker-compose directly
cd ..
docker-compose -f docker-compose.dev.yml up -d
```

### Cloud Deployment

```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file=terraform.tfvars

# Apply the configuration
terraform apply -var-file=terraform.tfvars
```

## Modules

### database

Provisions database resources:
- PostgreSQL for auth, log, scheduler, storage, notifier
- MongoDB for comment, feedback, ticket

### redis

Provisions Redis cache for rate limiting and caching.

### service

Provisions individual microservices with configurable:
- Container registry
- Kubernetes deployments
- Load balancers
- Auto-scaling

### network

Provisions network infrastructure:
- VPC/Virtual Network
- Subnets
- Security groups
- Load balancers

## Environment Variables

Each service requires specific environment variables. See individual service `.env.example` files.

## Outputs

After applying, Terraform will output:
- Service endpoints
- Database connection strings
- Redis connection URLs
- Load balancer URLs

## Cleanup

```bash
terraform destroy -var-file=terraform.tfvars
```
