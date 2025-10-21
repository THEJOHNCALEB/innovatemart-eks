locals {
  developer_username = "${var.project_name}-${var.environment}-developer-readonly"
}

# IAM Policy for read-only EKS access
resource "aws_iam_policy" "eks_readonly" {
  name        = "${local.developer_username}-policy"
  description = "Read-only access to EKS cluster resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = var.eks_cluster_arn
      }
    ]
  })
}

# IAM User for developers
resource "aws_iam_user" "developer" {
  name = local.developer_username
  path = "/"

  tags = {
    Name        = local.developer_username
    Description = "Read-only access for development team"
  }
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "developer_eks_readonly" {
  user       = aws_iam_user.developer.name
  policy_arn = aws_iam_policy.eks_readonly.arn
}

# Create access key for the user
resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

# Kubernetes ConfigMap for aws-auth
# This needs to be applied after the EKS cluster is created
resource "null_resource" "update_aws_auth" {
  provisioner "local-exec" {
    command = <<-EOT
      cat > /tmp/aws-auth-patch.yaml <<EOF
      - groups:
        - system:viewers
        userarn: ${aws_iam_user.developer.arn}
        username: ${aws_iam_user.developer.name}
      EOF
    EOT
  }

  depends_on = [aws_iam_user.developer]
}
