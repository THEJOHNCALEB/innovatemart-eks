# Deployment Guide

## Architecture Overview

This project deploys a microservices-based retail application on Amazon EKS with the following components:

### Infrastructure
- **VPC**: Custom VPC with public and private subnets across 2 availability zones
- **EKS Cluster**: Managed Kubernetes cluster (v1.28)
- **Node Group**: Auto-scaling group of t3.medium instances (1-4 nodes)
- **IAM**: Roles for EKS cluster, node groups, and read-only developer access

### Application Components
- **UI Service**: Frontend (port 80)
- **Catalog Service**: Product catalog with MySQL
- **Cart Service**: Shopping cart with DynamoDB Local
- **Orders Service**: Order management with PostgreSQL
- **Checkout Service**: Payment processing
- **Assets Service**: Static assets

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Terraform >= 1.0
- kubectl installed
- Git for version control

### Required AWS Permissions

- EC2 (VPC, Subnets, Security Groups)
- EKS (Cluster, Node Groups)
- IAM (Roles, Policies, Users)
- CloudWatch Logs

## Deployment Steps

### Step 1: Clone and Configure

```bash
git clone <repository-url>
cd altschool-final-assessment
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit terraform.tfvars with your AWS region and configuration.

### Step 2: Deploy Infrastructure
```bash
cd terraform

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply infrastructure
terraform apply
```

This creates:
- VPC with networking components
- EKS cluster
- Node group
- IAM resources

Expected deployment time: 20-25 minutes

### Step 3: Configure kubectl

After Terraform completes, configure kubectl:

```bash
aws eks update-kubeconfig --name innovatemart-production-eks --region us-east-1
```

Verify access:
```bash
kubectl get nodes
```

### Step 4: Deploy Application

```bash
# Using the script
./scripts/deploy-app.sh

# Or manually
git clone https://github.com/aws-containers/retail-store-sample-app.git
kubectl apply -f retail-store-sample-app/dist/kubernetes/
```

### Step 5: Set Up RBAC for Developer

```bash
kubectl apply -f k8s-manifests/aws-auth-rbac.yaml
```

## Accessing the Application

### Local Access (Port Forwarding)

```bash
kubectl port-forward -n retail-store-sample svc/ui 8080:80
```

Open http://localhost:8080 in your browser

### Verify Deployment

```bash
# Check all pods
kubectl get pods -n retail-store-sample

# Check services
kubectl get svc -n retail-store-sample

# View logs
kubectl logs -n retail-store-sample deployment/ui
```

## Developer Access Configuration

Get credentials from Terraform outputs:
```bash
cd terraform
terraform output developer_access_key_id
terraform output developer_secret_access_key
```

Configure AWS CLI with developer credentials:
```bash
aws configure --profile innovatemart-dev
# Enter the access key ID and secret access key
```

Configure kubectl:
```bash
aws eks update-kubeconfig \
  --name innovatemart-production-eks \
  --region us-east-1 \
  --profile innovatemart-dev
```

Test read-only access:
```bash
# These commands should work
kubectl get pods -n retail-store-sample
kubectl describe pod <pod-name> -n retail-store-sample
kubectl logs <pod-name> -n retail-store-sample

# These commands should be denied
kubectl delete pod <pod-name> -n retail-store-sample
kubectl apply -f manifest.yaml
```

## CI/CD Pipeline

GitHub Actions workflow behavior:

- Pull Request: Runs terraform plan
- Push to Main: Runs terraform apply

### Setting Up GitHub Actions

Add AWS credentials to GitHub Secrets:
- Go to repository Settings > Secrets and variables > Actions
- Add secrets:
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY

Push to trigger the pipeline:
```bash
git add .
git commit -m "Initial infrastructure setup"
git push origin main
```

## Branching Strategy

- main: Production code (auto-applies)
- develop: Integration branch (runs plan)
- feature/*: Feature development (runs plan on PR)

Workflow:
```bash
# Create feature branch
git checkout -b feature/add-monitoring

# Make changes and push
git add .
git commit -m "Add CloudWatch monitoring"
git push origin feature/add-monitoring

# Create PR to develop → triggers terraform plan
# Merge to develop → triggers terraform plan
# Merge develop to main → triggers terraform apply
```

## Troubleshooting

### Issue: Pods not starting

```bash
kubectl describe pod <pod-name> -n retail-store-sample
kubectl logs <pod-name> -n retail-store-sample
```

### Issue: Cannot connect to cluster

```bash
# Re-configure kubectl
aws eks update-kubeconfig --name innovatemart-production-eks --region us-east-1

# Check cluster status
aws eks describe-cluster --name innovatemart-production-eks
```

### Issue: Terraform state locked

```bash
# If using remote state with DynamoDB
terraform force-unlock <lock-id>
```

## Cost Estimate

Estimated monthly costs:
- EKS Cluster: $73
- EC2 Nodes (2x t3.medium): $60
- NAT Gateways (2): $65
- Data transfer: Variable

Total: Approximately $200/month

Cost reduction options:
- Use single NAT Gateway
- Reduce node count to 1
- Use t3.small instances
- Destroy resources when not in use

## Cleanup

To destroy all resources:

```bash
./scripts/cleanup.sh
```

Or manually:
```bash
kubectl delete -f retail-store-sample-app/dist/kubernetes/
cd terraform
terraform destroy
```

## Bonus Requirements

- Migrate to managed RDS/DynamoDB
- Install AWS Load Balancer Controller
- Configure Ingress with ALB
- Set up Route 53 and ACM for HTTPS
- Add monitoring with CloudWatch/Prometheus
- Implement backup strategies

## Support

For issues or questions:
1. Check logs: `kubectl logs <pod-name> -n retail-store-sample`
2. Review Terraform output: `terraform show`
3. Check AWS Console for resource status
