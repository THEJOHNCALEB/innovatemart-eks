# InnovateMart EKS Deployment - Project Bedrock

## Project Overview

This repository contains Infrastructure as Code (IaC) and deployment configurations for InnovateMart's microservices application on Amazon EKS.

## Technology Stack

- Cloud Provider: AWS
- Orchestration: Amazon EKS (Kubernetes v1.28)
- IaC Tool: Terraform
- CI/CD: GitHub Actions
- Application: [Retail Store Sample App](https://github.com/aws-containers/retail-store-sample-app)

## Project Structure
```
.
├── terraform/              # Terraform IaC code
│   ├── modules/
│   │   ├── vpc/           # VPC module
│   │   ├── eks/           # EKS cluster module
│   │   └── iam/           # IAM roles and policies
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── k8s-manifests/         # Kubernetes manifests
├── scripts/               # Deployment scripts
├── .github/workflows/     # CI/CD pipeline
├── DEPLOYMENT_GUIDE.md    # Deployment documentation
├── ARCHITECTURE.md        # Architecture documentation
└── README.md
```

## Prerequisites
- AWS CLI configured with credentials
- Terraform >= 1.0
- kubectl
- Git

### Deploy Infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS region

terraform init
terraform plan
terraform apply
```

### Configure kubectl
```bash
aws eks update-kubeconfig --name innovatemart-production-eks --region us-east-1
```

### Deploy Application
```bash
./scripts/deploy-app.sh
```

## Core Requirements Status

- VPC with public and private subnets
- EKS cluster provisioned
- IAM roles and policies configured
- Retail store app deployment ready
- In-cluster dependencies configured
- Read-only IAM user automated
- CI/CD pipeline implemented

## Access

### Application Access
```bash
kubectl port-forward -n retail-store-sample svc/ui 8080:80
```
Then open http://localhost:8080

### Developer Credentials
Retrieve read-only IAM user credentials:
```bash
cd terraform
terraform output developer_access_key_id
terraform output -raw developer_secret_access_key
```

## Notes
- All AWS credentials are managed through GitHub Secrets
- No sensitive data is committed to the repository
- Follow GitFlow branching strategy

## License
MIT
