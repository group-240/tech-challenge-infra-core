# ==============================================================================
# DATA SOURCES - Dados externos consultados
# ==============================================================================

# AWS Caller Identity - Informações da conta atual
data "aws_caller_identity" "current" {}

# IAM Role - LabRole do AWS Academy
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Availability Zones - Zonas disponíveis na região
data "aws_availability_zones" "available" {
  state = "available"
}

# Kubernetes Namespace - kube-system (usado pelo Load Balancer Controller)
data "kubernetes_namespace" "kube_system" {
  metadata {
    name = "kube-system"
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
}
