#!/bin/bash
set -e

echo "Cleanup Script - InnovateMart EKS"
echo "===================================="

echo "WARNING: This will destroy all infrastructure!"
echo "Are you sure you want to continue? (type 'destroy' to confirm)"
read -r response

if [[ "$response" != "destroy" ]]; then
    echo "Cleanup cancelled"
    exit 0
fi

# Delete Kubernetes resources first
echo "\nDeleting Kubernetes resources..."
if [ -d "retail-store-sample-app" ]; then
    kubectl delete -f retail-store-sample-app/dist/kubernetes/ --ignore-not-found=true
fi
kubectl delete -f k8s-manifests/aws-auth-rbac.yaml --ignore-not-found=true

# Wait for resources to be deleted
echo "Waiting for resources to be cleaned up..."
sleep 30

# Destroy Terraform infrastructure
echo "\nDestroying Terraform infrastructure..."
cd terraform
terraform destroy -auto-approve

echo "\n========================================"
echo "Cleanup Complete"
echo "========================================"
