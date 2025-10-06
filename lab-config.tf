# ==============================================================================
# CONFIGURAÇÃO CENTRALIZADA - AWS Learner Lab
# ==============================================================================
# 
# ⚙️ PONTO ÚNICO DE CONFIGURAÇÃO
# Altere apenas o 'aws_account_suffix' abaixo e ele será propagado para:
#   - Terraform backend (S3 + DynamoDB)
#   - Bootstrap (criação dos recursos)
#   - Todos os outputs
#   - Tags de recursos
#
# ==============================================================================

locals {
  # ┌─────────────────────────────────────────────────────────────────────┐
  # │ ⚠️ CONFIGURAÇÃO PRINCIPAL - ALTERE AQUI                             │
  # └─────────────────────────────────────────────────────────────────────┘
  aws_account_id     = "533267363894"
  aws_account_suffix = "533267363894-10"  # 🎯 MUDE APENAS ESTE VALOR
  aws_region         = "us-east-1"
  
  # ┌─────────────────────────────────────────────────────────────────────┐
  # │ 📦 NOMES DE RECURSOS (gerados automaticamente)                      │
  # └─────────────────────────────────────────────────────────────────────┘
  s3_bucket_name     = "tech-challenge-tfstate-${local.aws_account_suffix}"
  dynamodb_table_name = "tech-challenge-terraform-lock-${local.aws_account_suffix}"
  
  # ┌─────────────────────────────────────────────────────────────────────┐
  # │ 🔐 IAM Configuration                                                │
  # └─────────────────────────────────────────────────────────────────────┘
  lab_role_arn = "arn:aws:iam::${local.aws_account_id}:role/LabRole"
  
  # ┌─────────────────────────────────────────────────────────────────────┐
  # │ 🏷️ TAGS PADRÃO (aplicadas a todos os recursos)                     │
  # └─────────────────────────────────────────────────────────────────────┘
  common_tags = {
    AccountId      = local.aws_account_id
    AccountSuffix  = local.aws_account_suffix
    Region         = local.aws_region
    Lab            = "aws-learner-lab"
    Owner          = var.owner
    Environment    = var.environment
    Project        = var.project_name
    ManagedBy      = "terraform"
  }
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Data source para LabRole (necessário para EKS)
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Validação da conta AWS
data "aws_caller_identity" "current" {}

# Verificação de conta correta
locals {
  is_correct_account = data.aws_caller_identity.current.account_id == local.aws_account_id
}