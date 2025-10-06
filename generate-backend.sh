#!/bin/bash

set -e

echo "Lendo configuração de locals.tf..."

ACCOUNT_SUFFIX=$(grep 'aws_account_suffix' locals.tf | grep -v '#' | sed 's/.*= "\(.*\)".*/\1/')

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

cat > backend.tf << EOF
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

echo "Arquivo backend.tf gerado com sucesso!"
echo ""
echo "Próximos passos:"
echo "  1. terraform init -reconfigure"
echo "  2. terraform plan"
echo ""
