#!/bin/bash

# ==============================================================================
# Script para Gerar Configuração de Backend
# ==============================================================================
# 
# Uso: ./generate-backend.sh
#
# Este script lê o aws_account_suffix de locals.tf e gera o backend.tf
# ==============================================================================

set -e

echo "🔍 Lendo configuração de locals.tf..."

# Extrair aws_account_suffix do locals.tf
ACCOUNT_SUFFIX=$(grep 'aws_account_suffix' locals.tf | grep -v '#' | sed 's/.*= "\(.*\)".*/\1/')

if [ -z "$ACCOUNT_SUFFIX" ]; then
    echo "❌ Erro: Não foi possível encontrar aws_account_suffix em locals.tf"
    exit 1
fi

echo "✅ Account Suffix encontrado: $ACCOUNT_SUFFIX"

# Gerar configuração do backend
BUCKET_NAME="tech-challenge-tfstate-${ACCOUNT_SUFFIX}"
TABLE_NAME="tech-challenge-terraform-lock-${ACCOUNT_SUFFIX}"

echo ""
echo "📦 Configuração do Backend:"
echo "   Bucket S3:       $BUCKET_NAME"
echo "   DynamoDB Table:  $TABLE_NAME"
echo ""

# Criar arquivo backend.tf
cat > backend.tf << EOF
# ==============================================================================
# BACKEND CONFIGURATION - Gerado automaticamente
# ==============================================================================
# 
# ⚠️ NÃO EDITE ESTE ARQUIVO MANUALMENTE
# 
# Para alterar o backend:
#   1. Edite aws_account_suffix em locals.tf
#   2. Execute: ./generate-backend.sh
#   3. Execute: terraform init -reconfigure
#
# ==============================================================================

terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "${TABLE_NAME}"
    encrypt        = true
  }
}
EOF

echo "✅ Arquivo backend.tf gerado com sucesso!"
echo ""
echo "📝 Próximos passos:"
echo "   1. terraform init -reconfigure"
echo "   2. terraform plan"
echo ""
