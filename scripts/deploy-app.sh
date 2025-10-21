#!/bin/bash
set -e

echo "Deploying Retail Store Application"
echo "===================================="

# Check if retail-store-sample-app exists
if [ ! -d "retail-store-sample-app" ]; then
    echo "Cloning retail-store-sample-app repository..."
    git clone https://github.com/aws-containers/retail-store-sample-app.git
fi

# Deploy the application
echo "\nDeploying application to EKS..."
kubectl apply -f retail-store-sample-app/dist/kubernetes/

# Wait for pods to be ready
echo "\nWaiting for pods to be ready (this may take a few minutes)..."
kubectl wait --for=condition=ready pod --all -n retail-store-sample --timeout=300s || true

# Display status
echo "\nDeployment Status:"
kubectl get pods -n retail-store-sample
kubectl get services -n retail-store-sample

# Get UI service details
echo "\n========================================"
echo "Application Deployed Successfully"
echo "========================================"
echo "\nTo access the application locally:"
echo "kubectl port-forward -n retail-store-sample svc/ui 8080:80"
echo "Then open: http://localhost:8080"
