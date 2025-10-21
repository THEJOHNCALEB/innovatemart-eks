#!/bin/bash
set -e

echo "InnovateMart EKS Setup Script"
echo "================================"

# Check if required tools are installed
echo "\nChecking prerequisites..."
command -v aws >/dev/null 2>&1 || { echo "Error: AWS CLI is required but not installed. Aborting." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Error: Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "Error: kubectl is required but not installed. Aborting." >&2; exit 1; }

echo "All prerequisites met"

# Step 1: Initialize Terraform
echo "\nStep 1: Initializing Terraform..."
cd terraform
terraform init

# Step 2: Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    echo "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "Please edit terraform.tfvars with your desired values before continuing"
    exit 1
fi

# Step 3: Plan infrastructure
echo "\nStep 2: Planning infrastructure..."
terraform plan -out=tfplan

# Step 4: Apply infrastructure
echo "\nStep 3: Do you want to apply the infrastructure? (yes/no)"
read -r response
if [[ "$response" == "yes" ]]; then
    terraform apply tfplan
    echo "Infrastructure created successfully"
else
    echo "Deployment cancelled"
    exit 0
fi

# Step 5: Configure kubectl
echo "\nStep 4: Configuring kubectl..."
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
AWS_REGION=$(terraform output -raw aws_region || echo "us-east-1")
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"
echo "kubectl configured"

# Step 6: Verify cluster access
echo "\nStep 5: Verifying cluster access..."
kubectl get nodes
echo "Cluster is accessible"

# Step 7: Apply RBAC for read-only user
echo "\nStep 6: Setting up read-only user RBAC..."
cd ..
kubectl apply -f k8s-manifests/aws-auth-rbac.yaml
echo "RBAC configured"

# Step 8: Display next steps
echo "\n========================================"
echo "Setup Complete"
echo "========================================"
echo "\nNext steps:"
echo "1. Deploy the retail store application:"
echo "   ./scripts/deploy-app.sh"
echo "\n2. Get developer credentials:"
echo "   cd terraform && terraform output developer_access_key_id"
echo "   terraform output developer_secret_access_key"
