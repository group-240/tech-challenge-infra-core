# ==============================================================================
# VARIÁVEIS DO BOOTSTRAP - Com defaults para facilitar manutenção
# ==============================================================================
# 
# ⚙️ CONFIGURAÇÃO CENTRALIZADA
# Estes valores devem ser os mesmos do ../lab-config.tf
# Definidos aqui com defaults para não precisar de terraform.tfvars
#
# ==============================================================================

# ┌─────────────────────────────────────────────────────────────────────┐
# │ ⚠️ ALTERE APENAS O aws_account_suffix PARA PROPAGAR MUDANÇAS       │
# └─────────────────────────────────────────────────────────────────────┘

variable "aws_account_id" {
  description = "ID da conta AWS"
  type        = string
  default     = "533267363894"
}

variable "aws_account_suffix" {
  description = "Sufixo da conta AWS (usado em nomes de recursos S3/DynamoDB)"
  type        = string
  default     = "533267363894-10"  # 🎯 MUDE APENAS ESTE VALOR
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

# ┌─────────────────────────────────────────────────────────────────────┐
# │ 🏷️ TAGS E PROJETO                                                   │
# └─────────────────────────────────────────────────────────────────────┘

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "tech-challenge"
}

variable "environment" {
  description = "Ambiente (fixo em dev para estudo)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Responsável pelo projeto"
  type        = string
  default     = "student"
}