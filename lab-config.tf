# ------------------------------------------------------------------
# AWS Learner Lab - Conta 533267363894 - us-east-1
# ------------------------------------------------------------------

locals {
  # Configurações fixas da sua conta
  aws_account_id     = "533267363894"
  aws_account_suffix = "533267363894-10"  # Sufixo para recursos S3/DynamoDB
  aws_region         = "us-east-1"
  
  # Role específico do Learner Lab
  lab_role_arn = "arn:aws:iam::${local.aws_account_id}:role/LabRole"
  
  # Tags obrigatórias para sua conta
  account_tags = {
    AccountId   = local.aws_account_id
    Region      = local.aws_region
    Lab         = "aws-learner-lab"
    Owner       = "student"
    Environment = "dev"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Data source para LabRole (necessário para EKS)
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Validação da conta (deve ser exatamente sua conta)
data "aws_caller_identity" "current" {}

locals {
  is_correct_account = data.aws_caller_identity.current.account_id == local.aws_account_id
}

# Output para validar configuração
output "account_validation" {
  description = "Validação da conta AWS"
  value = {
    expected_account = local.aws_account_id
    current_account  = data.aws_caller_identity.current.account_id
    is_valid        = local.is_correct_account
    lab_role        = local.lab_role_arn
    region          = local.aws_region
  }
}