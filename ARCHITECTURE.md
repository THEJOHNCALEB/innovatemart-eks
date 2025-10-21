# Architecture Document

## System Overview

InnovateMart retail application runs on Amazon EKS with a microservices architecture, featuring automatic scaling, high availability, and secure access controls.

## Network Architecture

```
                                 Internet
                                    |
                          Internet Gateway
                                    |
                    +---------------+---------------+
                    |                               |
            Public Subnet 1                 Public Subnet 2
            (us-east-1a)                    (us-east-1b)
                    |                               |
              NAT Gateway                     NAT Gateway
                    |                               |
            +-------+-------+               +-------+-------+
            |               |               |               |
       Private Subnet 1  Private Subnet 2  Private Subnet 3  Private Subnet 4
       (us-east-1a)      (us-east-1a)      (us-east-1b)     (us-east-1b)
            |                                       |
        EKS Nodes                              EKS Nodes
```

### VPC Configuration
- **CIDR**: 10.0.0.0/16
- **Public Subnets**: 2 (for NAT Gateways and Load Balancers)
- **Private Subnets**: 2 (for EKS worker nodes)
- **Availability Zones**: 2 (for high availability)

## EKS Cluster Architecture

### Control Plane
- Managed by AWS
- Kubernetes version 1.28
- Multi-AZ deployment
- API server endpoint: Public + Private access

### Data Plane (Worker Nodes)
- **Node Group**: Managed node group
- **Instance Type**: t3.medium (2 vCPU, 4 GB RAM)
- **Scaling**: 1-4 nodes
- **AMI**: Amazon EKS optimized Amazon Linux 2

## Application Architecture

The application consists of:
- UI Service (frontend)
- Catalog Service with MySQL backend
- Cart Service with DynamoDB Local backend
- Orders Service with PostgreSQL backend
- Checkout Service
- Assets Service

### Microservices

1. **UI Service**
   - Frontend web application
   - Nginx-based
   - Port: 80

2. **Catalog Service**
   - Product catalog management
   - Backend: MySQL
   - Port: 8080

3. **Cart Service**
   - Shopping cart functionality
   - Backend: DynamoDB Local
   - Port: 8080

4. **Orders Service**
   - Order processing
   - Backend: PostgreSQL
   - Port: 8080

5. **Checkout Service**
   - Payment processing
   - Port: 8080

6. **Assets Service**
   - Static assets (images, CSS, JS)
   - Port: 8080

## Security Architecture

### IAM Roles

1. **EKS Cluster Role**
   - Policies: AmazonEKSClusterPolicy, AmazonEKSVPCResourceController
   - Used by: EKS control plane

2. **Node Group Role**
   - Policies: AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, AmazonEC2ContainerRegistryReadOnly
   - Used by: Worker nodes

3. **Developer Read-Only User**
   - Custom policy for read-only EKS access
   - Kubernetes RBAC: ClusterRole with view permissions

### Network Security

- Worker nodes in private subnets
- Security groups control traffic flow
- NAT Gateways for outbound internet access
- No direct internet access to worker nodes

### RBAC Configuration

ClusterRole: read-only-role
Permissions:
- get, list, watch: pods, services, deployments
- get, list, watch: logs
- No write permissions

## Data Flow

1. User accesses UI via LoadBalancer/Port-forward
2. UI communicates with backend services
3. Services interact with respective databases
4. All communication within cluster network
5. Databases persist data in persistent volumes

## Scalability

### Horizontal Pod Autoscaling (HPA)
- Can be configured based on CPU/memory metrics
- Automatic pod scaling between min/max replicas

### Cluster Autoscaling
- Node group scales 1-4 nodes
- Based on pod resource requests
- Automatic scale up/down

## Monitoring & Logging

- CloudWatch Container Insights (can be enabled)
- Kubernetes native logging via kubectl
- Application logs accessible via: `kubectl logs`

## High Availability

- Multi-AZ deployment
- EKS control plane managed across 3 AZs
- Worker nodes distributed across 2 AZs
- Database replicas (when using managed services)

## Disaster Recovery

- Infrastructure as Code enables quick recovery
- Terraform state management
- Regular backups of persistent data
- Multi-AZ provides zone failure tolerance

## Future Enhancements

Managed Databases:
- RDS PostgreSQL for orders
- RDS MySQL for catalog
- DynamoDB for carts

Advanced Networking:
- AWS Load Balancer Controller
- Ingress with ALB
- Route 53 for DNS
- ACM for SSL/TLS

Monitoring Stack:
- Prometheus for metrics
- Grafana for visualization
- ELK stack for log aggregation

Security Enhancements:
- Pod Security Policies
- Network Policies
- Secrets management with AWS Secrets Manager
- VPC endpoints for AWS services
