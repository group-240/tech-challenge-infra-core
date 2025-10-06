# ==============================================================================
# LOCALS - Configuração Centralizada
# ==============================================================================
# 
# ⚙️ PONTO ÚNICO DE CONFIGURAÇÃO
# Altere apenas o 'aws_account_suffix' e ele será propagado para:
#   - Nomes de recursos S3/DynamoDB
#   - Tags de recursos
#   - Outputs
#
# ⚠️ IMPORTANTE: O backend S3 no main.tf ainda precisa ser atualizado manualmente
#    após mudar o aws_account_suffix (limitação do Terraform)
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
  s3_bucket_name      = "tech-challenge-tfstate-${local.aws_account_suffix}"
  dynamodb_table_name = "tech-challenge-terraform-lock-${local.aws_account_suffix}"
  
  # ┌─────────────────────────────────────────────────────────────────────┐
  # │ 🔐 IAM Configuration                                                │
  # └─────────────────────────────────────────────────────────────────────┘
  lab_role_arn = "arn:aws:iam::${local.aws_account_id}:role/LabRole"
  
  # ┌─────────────────────────────────────────────────────────────────────┐
  # │ 🏷️ TAGS PADRÃO (aplicadas a todos os recursos)                      │
  # └─────────────────────────────────────────────────────────────────────┘
  common_tags = {
    AccountId     = local.aws_account_id
    AccountSuffix = local.aws_account_suffix
    Region        = local.aws_region
    Lab           = "aws-learner-lab"
    Owner         = var.owner
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "terraform"
  }
  
  # ┌─────────────────────────────────────────────────────────────────────┐
  # │ ✅ VALIDAÇÃO DE CONTA                                               │
  # └─────────────────────────────────────────────────────────────────────┘
  is_correct_account = data.aws_caller_identity.current.account_id == local.aws_account_id
}