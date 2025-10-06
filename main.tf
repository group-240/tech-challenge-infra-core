# ------------------------------------------------------------------
# Arquivo: main.tf
# Descrição: Ponto de entrada principal do Terraform para a infraestrutura core.
# ------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }

  # Backend S3 específico para sua conta AWS (891377164819)
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-4"
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894"
    encrypt        = true
  }
}

provider "aws" {
  region = local.aws_region  # us-east-1 fixo

  default_tags {
    tags = local.common_tags
  }
}

# Provider Kubernetes para gerenciar recursos no EKS
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.main.name,
      "--region",
      local.aws_region
    ]
  }
}

# Provider Helm para instalar charts automaticamente
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        aws_eks_cluster.main.name,
        "--region",
        local.aws_region
      ]
    }
  }
}

# Tags padrão usando configurações da conta
locals {
  common_tags = merge(local.account_tags, {
    Component = "infrastructure-core"
  })
}

# VPC - APENAS 1
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Data source para primeira AZ disponível
data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway (necessário para conectividade externa)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# Subnet Pública para NAT Gateway
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "${var.project_name}-public-subnet"
    Type                     = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

# Elastic IP para NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway (permite subnets privadas acessarem internet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Table para Subnet Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

# Associação da Route Table Pública
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Route Table para Subnets Privadas
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-rt"
  })
}

# Subnets Privadas - EKS requer pelo menos 2 AZs diferentes
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.common_tags, {
    Name                              = "${var.project_name}-private-subnet-1"
    Type                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  })
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(local.common_tags, {
    Name                              = "${var.project_name}-private-subnet-2"
    Type                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  })
}

# Associações das Route Tables Privadas
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks"
  role_arn = data.aws_iam_role.lab_role.arn
  #version  = "1.34" # Versão atual (requer AL2023)

  vpc_config {
    subnet_ids              = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    endpoint_private_access = true
    endpoint_public_access  = true # Necessário para kubectl access
  }

  # CloudWatch Logs para observabilidade (retenção mínima = 3 dias)
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-cluster"
  })

  depends_on = [
    aws_subnet.private_1,
    aws_subnet.private_2,
    aws_cloudwatch_log_group.eks
  ]
}

# CloudWatch Log Group para EKS (3 dias para custo mínimo)
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}-eks/cluster"
  retention_in_days = 3

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-logs"
  })
}

# Política IAM adicional para AWS Load Balancer Controller
# Necessária porque LabRole não tem permissões para gerenciar ELB/TargetGroups
resource "aws_iam_role_policy" "node_load_balancer_controller" {
  name = "${var.project_name}-node-alb-controller-policy"
  role = data.aws_iam_role.lab_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      }
    ]
  })
}

# EKS Node Group - CONFIGURAÇÃO MAIS BARATA POSSÍVEL
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-nodes"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  
  # APENAS 1 AZ para economizar (node fica só na subnet 1)
  subnet_ids = [aws_subnet.private_1.id]

  # MÁXIMA ECONOMIA
  instance_types = ["t3.small"] # Menor possível que ainda funciona (2 vCPU, 2GB RAM)
  capacity_type  = "SPOT"       # 70% mais barato que On-Demand

  scaling_config {
    desired_size = 1 # APENAS 1 node
    max_size     = 2 # Permite escalar para 2 se necessário
    min_size     = 1 # Sempre pelo menos 1
  }

  # Configurações mínimas
  disk_size = 20 # GB mínimo para EKS (não pode ser menor)
  ami_type  = "AL2023_x86_64_STANDARD" # Amazon Linux 2023 (requerido para K8s 1.33+)

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-nodes"
  })

  depends_on = [
    aws_eks_cluster.main,
    aws_route_table_association.private_1,
    aws_route_table_association.private_2,
    aws_iam_role_policy.node_load_balancer_controller
  ]
}

# EKS addon nativo - VPC CNI (gerenciamento de rede dos pods)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "vpc-cni"
  # Versão será escolhida automaticamente pela AWS
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc-cni"
  })

  depends_on = [
    aws_eks_node_group.main
  ]
}

# EKS addon nativo - kube-proxy (proxy de rede Kubernetes)
resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "kube-proxy"
  # Versão será escolhida automaticamente pela AWS
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-kube-proxy"
  })

  depends_on = [
    aws_eks_node_group.main
  ]
}

# EKS addon nativo - CoreDNS (DNS interno do cluster)
resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "coredns"
  # Versão será escolhida automaticamente pela AWS
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-coredns"
  })

  depends_on = [
    aws_eks_node_group.main
  ]
}

# ------------------------------------------------------------------
# AWS Load Balancer Controller - Instalação via Helm (AUTOMATIZADA)
# ------------------------------------------------------------------

# Namespace para o controller (kube-system já existe por padrão)
# Não precisa criar, mas vamos garantir que está pronto
data "kubernetes_namespace" "kube_system" {
  metadata {
    name = "kube-system"
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
}

# Service Account para o AWS Load Balancer Controller
# Usando LabRole existente (sem IRSA devido a limitações do AWS Academy)
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
  }

  depends_on = [
    data.kubernetes_namespace.kube_system
  ]
}

# Instalar AWS Load Balancer Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.9.2"  # Compatível com EKS 1.33

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }

  set {
    name  = "region"
    value = local.aws_region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  # Desabilitar webhook para simplificar (funciona sem ele)
  set {
    name  = "enableCertManager"
    value = "false"
  }

  # Usar credenciais do node (LabRole) ao invés de IRSA
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = ""
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_eks_addon.vpc_cni,
    aws_eks_addon.coredns,
    kubernetes_service_account.aws_load_balancer_controller
  ]
}

# ------------------------------------------------------------------
# Cognito User Pool (para autenticação da aplicação)
# ------------------------------------------------------------------
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-user-pool"

  # Configuração de senha
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # Auto-verificação via email
  auto_verified_attributes = ["email"]

  # Atributos do schema
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cognito-pool"
  })
}

# Cognito User Pool Client (para a aplicação se conectar)
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Fluxos de autenticação permitidos
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # Configurações de token
  refresh_token_validity = 30
  access_token_validity  = 60
  id_token_validity      = 60

  token_validity_units {
    refresh_token = "days"
    access_token  = "minutes"
    id_token      = "minutes"
  }

  # Prevenir secret do client (para apps públicos)
  generate_secret = false
}

# Cognito User Pool Domain (para UI de autenticação)
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${local.aws_account_id}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# ------------------------------------------------------------------
# ECR Repository (para imagens Docker da aplicação)
# ------------------------------------------------------------------
resource "aws_ecr_repository" "app" {
  name = "${var.project_name}-api"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # Desabilitado para economizar custos
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-repository"
  })
}

# Lifecycle policy para limpar imagens antigas (economia de custo)
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------
# Network Load Balancer (NLB) - Infraestrutura compartilhada
# ------------------------------------------------------------------

# Target Group para o NLB (gerenciado via TargetGroupBinding)
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-app-tg"
  port        = 80  # Porta do ClusterIP Service
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"  # AWS Load Balancer Controller registra IPs dos pods automaticamente

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "HTTP"
    path                = "/api/health"  # Corrigido para usar o context-path correto da aplicação
    port                = "traffic-port"  # Usa a mesma porta do tráfego (80)
    timeout             = 10
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-app-target-group"
  })
}

# Network Load Balancer (interno)
resource "aws_lb" "app" {
  name               = "${var.project_name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  enable_deletion_protection = false # DEV environment

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nlb"
  })
}

# Listener para o NLB
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nlb-listener"
  })
}