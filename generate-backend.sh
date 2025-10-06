#!/bin/bash

set -e

echo "Lendo configuração de locals.tf..."

# Extrai o valor de aws_account_suffix de forma mais robusta
ACCOUNT_SUFFIX=$(grep 'aws_account_suffix' locals.tf | grep -v '#' | head -n 1 | sed 's/.*= *"\([^"]*\)".*/\1/' | tr -d '\n\r')

if [ -z "$ACCOUNT_SUFFIX" ]; then
    echo "Erro: Não foi possível encontrar aws_account_suffix em locals.tf"
    exit 1
fi

echo "Account Suffix encontrado: $ACCOUNT_SUFFIX"

BUCKET_NAME="tech-challenge-tfstate-${ACCOUNT_SUFFIX}"
TABLE_NAME="tech-challenge-terraform-lock-${ACCOUNT_SUFFIX}"

echo ""
echo "Configuração do Backend:"
echo "  Bucket S3:       $BUCKET_NAME"
echo "  DynamoDB Table:  $TABLE_NAME"
echo ""

cat > backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "BUCKET_NAME_PLACEHOLDER"
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "TABLE_NAME_PLACEHOLDER"
    encrypt        = true
  }
}
EOF

# Substitui os placeholders
sed -i "s|BUCKET_NAME_PLACEHOLDER|${BUCKET_NAME}|g" backend.tf
sed -i "s|TABLE_NAME_PLACEHOLDER|${TABLE_NAME}|g" backend.tf

echo "Arquivo backend.tf gerado com sucesso!"
echo ""
echo "Próximos passos:"
echo "  1. terraform init -reconfigure"
echo "  2. terraform plan"
echo ""
