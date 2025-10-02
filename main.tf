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
  }

  # Backend S3 específico para sua conta AWS (891377164819)
  backend "s3" {
    bucket         = "tech-challenge-tfstate-891377164819"
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-891377164819"
    encrypt        = true
  }
}

provider "aws" {
  region = local.aws_region  # us-east-1 fixo

  default_tags {
    tags = local.common_tags
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
  version  = "1.33" # Versão atual (requer AL2023)

  vpc_config {
    subnet_ids              = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    endpoint_private_access = true
    endpoint_public_access  = true # Necessário para kubectl access
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks-cluster"
  })

  depends_on = [
    aws_subnet.private_1,
    aws_subnet.private_2
  ]
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
    aws_route_table_association.private_2
  ]
}