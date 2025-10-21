#!/bin/bash

echo "InnovateMart Deployment Verification"
echo "====================================="

# Function to check status
check_status() {
    if [ $? -eq 0 ]; then
        echo "[OK] $1"
        return 0
    else
        echo "[FAIL] $1"
        return 1
    fi
}

# Check AWS CLI
echo "\n1. Checking Prerequisites..."
aws --version > /dev/null 2>&1
check_status "AWS CLI installed"

kubectl version --client > /dev/null 2>&1
check_status "kubectl installed"

terraform --version > /dev/null 2>&1
check_status "Terraform installed"

# Check AWS connectivity
echo "\n2. Checking AWS Connectivity..."
aws sts get-caller-identity > /dev/null 2>&1
check_status "AWS credentials configured"

# Check Terraform state
echo "\n3. Checking Infrastructure..."
if [ -d "terraform/.terraform" ]; then
    echo "[OK] Terraform initialized"
else
    echo "[FAIL] Terraform not initialized"
fi

if [ -f "terraform/terraform.tfstate" ]; then
    echo "[OK] Terraform state exists"
    
    # Check if resources are deployed
    cd terraform
    CLUSTER_NAME=$(terraform output -raw eks_cluster_name 2>/dev/null)
    if [ -n "$CLUSTER_NAME" ]; then
        echo "[OK] EKS cluster deployed: $CLUSTER_NAME"
    else
        echo "[WARN] No EKS cluster found in state"
    fi
    cd ..
else
    echo "[WARN] Terraform state not found (infrastructure not deployed)"
fi

# Check kubectl connectivity
echo "\n4. Checking Kubernetes Cluster..."
kubectl get nodes > /dev/null 2>&1
if check_status "kubectl can connect to cluster"; then
    kubectl get nodes
    
    # Check node status
    NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    READY_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready")
    echo "[OK] Nodes: $READY_COUNT/$NODE_COUNT Ready"
fi

# Check application deployment
echo "\n5. Checking Application..."
kubectl get namespace retail-store-sample > /dev/null 2>&1
if check_status "retail-store-sample namespace exists"; then
    
    # Check pods
    TOTAL_PODS=$(kubectl get pods -n retail-store-sample --no-headers 2>/dev/null | wc -l)
    RUNNING_PODS=$(kubectl get pods -n retail-store-sample --no-headers 2>/dev/null | grep -c "Running")
    echo -e "Pods: $RUNNING_PODS/$TOTAL_PODS Running"
    
    if [ "$TOTAL_PODS" -eq 0 ]; then
        echo "[WARN] No pods found. Run ./scripts/deploy-app.sh"
    else
        kubectl get pods -n retail-store-sample
    fi
    
    # Check services
    echo "\nServices:"
    kubectl get svc -n retail-store-sample
else
    echo "[WARN] Application not deployed. Run ./scripts/deploy-app.sh"
fi

# Check RBAC
echo "\n6. Checking RBAC Configuration..."
kubectl get clusterrole read-only-role > /dev/null 2>&1
check_status "Read-only ClusterRole exists"

kubectl get clusterrolebinding read-only-binding > /dev/null 2>&1
check_status "Read-only ClusterRoleBinding exists"

# Summary
echo "\n======================================"
echo "Verification Complete"
echo "======================================"

echo "\nNext Steps:"
echo "1. Access the application:"
echo "   kubectl port-forward -n retail-store-sample svc/ui 8080:80"
echo "   Then open: http://localhost:8080"
echo "\n2. Get developer credentials:"
echo "   cd terraform && terraform output developer_access_key_id"
echo "\n3. View full status:"
echo "   kubectl get all -n retail-store-sample"
