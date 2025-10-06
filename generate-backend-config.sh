#!/bin/bash

# ==============================================================================
# Script: generate-backend-config.sh
# Descrição: Gera configurações de backend para todos os repositórios
# ==============================================================================
#
# Este script lê a configuração centralizada e gera os arquivos backend.tf
# em todos os repositórios, garantindo consistência.
#
# Uso: ./generate-backend-config.sh
# ==============================================================================

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Gerador de Configurações de Backend${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Carregar configuração centralizada
CONFIG_FILE="lab-config.tf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Erro: Arquivo $CONFIG_FILE não encontrado!"
    echo "Execute este script no diretório tech-challenge-infra-core"
    exit 1
fi

# Extrair valores do lab-config.tf
AWS_ACCOUNT_SUFFIX=$(grep 'aws_account_suffix' "$CONFIG_FILE" | grep -oP '"\K[^"]+')
AWS_REGION=$(grep 'aws_region' "$CONFIG_FILE" | head -1 | grep -oP '"\K[^"]+')

if [ -z "$AWS_ACCOUNT_SUFFIX" ]; then
    echo "❌ Erro: Não foi possível extrair aws_account_suffix de $CONFIG_FILE"
    exit 1
fi

echo -e "${GREEN}✓${NC} Configuração lida:"
echo "  - AWS Account Suffix: ${YELLOW}${AWS_ACCOUNT_SUFFIX}${NC}"
echo "  - AWS Region: ${YELLOW}${AWS_REGION}${NC}"
echo ""

# Definir recursos
BUCKET_NAME="tech-challenge-tfstate-${AWS_ACCOUNT_SUFFIX}"
DYNAMODB_TABLE="tech-challenge-terraform-lock-${AWS_ACCOUNT_SUFFIX}"

echo -e "${GREEN}✓${NC} Recursos que serão configurados:"
echo "  - S3 Bucket: ${YELLOW}${BUCKET_NAME}${NC}"
echo "  - DynamoDB Table: ${YELLOW}${DYNAMODB_TABLE}${NC}"
echo ""

# Função para gerar backend.tf
generate_backend() {
    local repo_path=$1
    local state_key=$2
    local output_file="${repo_path}/backend.tf"
    
    echo -e "${BLUE}→${NC} Gerando: ${output_file}"
    
    cat > "$output_file" << EOF
# ==============================================================================
# Backend Configuration - AUTO-GENERATED
# ==============================================================================
# 
# ⚠️  NÃO EDITE ESTE ARQUIVO MANUALMENTE!
# 
# Este arquivo é gerado automaticamente pelo script:
#   tech-challenge-infra-core/generate-backend-config.sh
#
# Para atualizar as configurações:
#   1. Edite: tech-challenge-infra-core/lab-config.tf (aws_account_suffix)
#   2. Execute: ./generate-backend-config.sh
#
# Gerado em: $(date)
# ==============================================================================

terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "${state_key}"
    region         = "${AWS_REGION}"
    dynamodb_table = "${DYNAMODB_TABLE}"
    encrypt        = true
  }
}
EOF
    
    echo -e "${GREEN}  ✓ Criado${NC}"
}

# Função para gerar data sources
generate_remote_state() {
    local repo_path=$1
    local output_file="${repo_path}/remote-states.tf"
    
    echo -e "${BLUE}→${NC} Gerando: ${output_file}"
    
    cat > "$output_file" << EOF
# ==============================================================================
# Remote State Data Sources - AUTO-GENERATED
# ==============================================================================
# 
# ⚠️  NÃO EDITE ESTE ARQUIVO MANUALMENTE!
# 
# Este arquivo é gerado automaticamente pelo script:
#   tech-challenge-infra-core/generate-backend-config.sh
#
# Gerado em: $(date)
# ==============================================================================

# Remote state: Core Infrastructure
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "${BUCKET_NAME}"
    key    = "core/terraform.tfstate"
    region = "${AWS_REGION}"
  }
}
EOF
    
    # Adicionar data sources específicos para cada repositório
    case "$repo_path" in
        "../tech-challenge-infra-gateway-lambda")
            cat >> "$output_file" << EOF

# Remote state: Application
data "terraform_remote_state" "application" {
  backend = "s3"
  config = {
    bucket = "${BUCKET_NAME}"
    key    = "application/terraform.tfstate"
    region = "${AWS_REGION}"
  }
}
EOF
            ;;
        "../tech-challenge-application/terraform")
            cat >> "$output_file" << EOF

# Remote state: Database
data "terraform_remote_state" "database" {
  backend = "s3"
  config = {
    bucket = "${BUCKET_NAME}"
    key    = "database/terraform.tfstate"
    region = "${AWS_REGION}"
  }
}
EOF
            ;;
    esac
    
    echo -e "${GREEN}  ✓ Criado${NC}"
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Gerando arquivos de configuração${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Gerar backend para cada repositório
generate_backend "." "core/terraform.tfstate"
generate_remote_state "."

if [ -d "../tech-challenge-infra-database" ]; then
    generate_backend "../tech-challenge-infra-database" "database/terraform.tfstate"
    generate_remote_state "../tech-challenge-infra-database"
fi

if [ -d "../tech-challenge-infra-gateway-lambda" ]; then
    generate_backend "../tech-challenge-infra-gateway-lambda" "gateway/terraform.tfstate"
    generate_remote_state "../tech-challenge-infra-gateway-lambda"
fi

if [ -d "../tech-challenge-application/terraform" ]; then
    generate_backend "../tech-challenge-application/terraform" "application/terraform.tfstate"
    generate_remote_state "../tech-challenge-application/terraform"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Configurações geradas com sucesso!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Revise os arquivos gerados:"
echo "   - backend.tf (em cada repositório)"
echo "   - remote-states.tf (em cada repositório)"
echo ""
echo "2. Se houver mudanças no backend, execute em cada repositório:"
echo "   terraform init -reconfigure"
echo ""
echo "3. Commit as mudanças:"
echo "   git add backend.tf remote-states.tf"
echo "   git commit -m 'chore: atualiza configurações de backend'"
echo ""
