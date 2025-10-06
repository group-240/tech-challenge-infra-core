# ==============================================================================
# BOOTSTRAP - Criação do Backend S3/DynamoDB
# ==============================================================================
# 
# ⚠️ IMPORTANTE: Execute este módulo PRIMEIRO, antes da infraestrutura principal
# 
# Este módulo cria:
#   - Bucket S3 para armazenar o state do Terraform
#   - Tabela DynamoDB para lock do state
#
# Os nomes dos recursos são definidos de forma centralizada:
#   - Bucket S3: tech-challenge-tfstate-{aws_account_suffix}
#   - DynamoDB:  tech-challenge-terraform-lock-{aws_account_suffix}
#
# O valor de {aws_account_suffix} vem do arquivo ../lab-config.tf
# Altere lá para propagar para todos os repositórios.
# ==============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # ⚠️ SEM backend S3 aqui - bootstrap usa state local
  # Após criar o S3, a infra principal usará o backend remoto
}

provider "aws" {
  region = var.aws_region
}

# ==============================================================================
# CONFIGURAÇÃO CENTRALIZADA
# ==============================================================================

locals {
  # 🎯 Valores vindos das variáveis (definidas com defaults)
  account_id     = var.aws_account_id
  account_suffix = var.aws_account_suffix
  
  # 📦 Nomes dos recursos (gerados automaticamente)
  bucket_name = "tech-challenge-tfstate-${local.account_suffix}"
  table_name  = "tech-challenge-terraform-lock-${local.account_suffix}"
  
  # 🏷️ Tags comuns
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "terraform-bootstrap"
    AccountId     = local.account_id
    AccountSuffix = local.account_suffix
    Owner         = var.owner
  }
}

# S3 Bucket para armazenar o state do Terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name
  
  tags = local.common_tags
}

# Versionamento do bucket (backup automático)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Criptografia do bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear acesso público (segurança)
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle para gerenciar versões antigas
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "terraform_state_lifecycle"
    status = "Enabled"

    filter {}  # Filter vazio aplica a regra a todos os objetos

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# DynamoDB para lock do Terraform
resource "aws_dynamodb_table" "terraform_lock" {
  name           = local.table_name
  billing_mode   = "PAY_PER_REQUEST"  # Mais econômico para baixo volume
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.common_tags
}

# Política IAM para acesso ao bucket (opcional - para maior segurança)
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}