#!/bin/bash

# ==============================================================================
# Script para corrigir recursos S3/DynamoDB duplicados
# ==============================================================================
# 
# PROBLEMA: Recursos foram criados com nomes inconsistentes:
#   - tech-challenge-tfstate-533267363894-4  (antigo)
#   - tech-challenge-terraform-lock-533267363894 (antigo, sem sufixo)
# 
# SOLUÇÃO: Padronizar para -10 em todos os recursos
#   - tech-challenge-tfstate-533267363894-10
#   - tech-challenge-terraform-lock-533267363894-10
# ==============================================================================

set -e

echo "🔍 Verificando recursos existentes..."

# Verificar buckets S3
echo ""
echo "📦 Buckets S3 encontrados:"
aws s3 ls | grep tech-challenge || echo "  Nenhum bucket encontrado"

# Verificar DynamoDB
echo ""
echo "🗄️  Tabelas DynamoDB encontradas:"
aws dynamodb list-tables --query "TableNames[?contains(@, 'tech-challenge')]" --output table

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  OPÇÕES DE CORREÇÃO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "OPÇÃO 1: Destruir recursos antigos e criar novos (RECOMENDADO)"
echo "  - Destrói: tech-challenge-tfstate-533267363894-4"
echo "  - Destrói: tech-challenge-terraform-lock-533267363894"
echo "  - Cria:    tech-challenge-tfstate-533267363894-10"
echo "  - Cria:    tech-challenge-terraform-lock-533267363894-10"
echo ""
echo "OPÇÃO 2: Importar recursos existentes para o novo state"
echo "  - Mantém os recursos antigos"
echo "  - Atualiza apenas as referências no Terraform"
echo ""

read -p "Escolha a opção (1 ou 2): " opcao

if [ "$opcao" == "1" ]; then
    echo ""
    echo "🗑️  OPÇÃO 1: Destruindo recursos antigos..."
    echo ""
    
    # Destruir bucket S3 antigo
    BUCKET_OLD="tech-challenge-tfstate-533267363894-4"
    if aws s3 ls "s3://${BUCKET_OLD}" 2>/dev/null; then
        echo "📦 Removendo objetos do bucket ${BUCKET_OLD}..."
        aws s3 rm "s3://${BUCKET_OLD}" --recursive || true
        
        echo "📦 Deletando bucket ${BUCKET_OLD}..."
        aws s3 rb "s3://${BUCKET_OLD}" || true
        echo "✅ Bucket ${BUCKET_OLD} removido"
    else
        echo "ℹ️  Bucket ${BUCKET_OLD} não existe"
    fi
    
    # Destruir DynamoDB antiga
    TABLE_OLD="tech-challenge-terraform-lock-533267363894"
    if aws dynamodb describe-table --table-name "${TABLE_OLD}" 2>/dev/null; then
        echo "🗄️  Deletando tabela ${TABLE_OLD}..."
        aws dynamodb delete-table --table-name "${TABLE_OLD}"
        
        echo "⏳ Aguardando exclusão da tabela..."
        aws dynamodb wait table-not-exists --table-name "${TABLE_OLD}"
        echo "✅ Tabela ${TABLE_OLD} removida"
    else
        echo "ℹ️  Tabela ${TABLE_OLD} não existe"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Recursos antigos removidos!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Próximos passos:"
    echo "  1. cd bootstrap"
    echo "  2. terraform init -reconfigure"
    echo "  3. terraform plan"
    echo "  4. terraform apply"
    echo ""
    
elif [ "$opcao" == "2" ]; then
    echo ""
    echo "🔄 OPÇÃO 2: Importando recursos existentes..."
    echo ""
    
    cd bootstrap
    
    # Reinicializar Terraform
    echo "🔧 Reinicializando Terraform..."
    terraform init -reconfigure
    
    # Importar bucket S3
    BUCKET_OLD="tech-challenge-tfstate-533267363894-4"
    if aws s3 ls "s3://${BUCKET_OLD}" 2>/dev/null; then
        echo "📦 Importando bucket ${BUCKET_OLD}..."
        terraform import aws_s3_bucket.terraform_state "${BUCKET_OLD}" || echo "⚠️  Bucket já importado ou não existe"
    fi
    
    # Importar DynamoDB
    TABLE_OLD="tech-challenge-terraform-lock-533267363894"
    if aws dynamodb describe-table --table-name "${TABLE_OLD}" 2>/dev/null; then
        echo "🗄️  Importando tabela ${TABLE_OLD}..."
        terraform import aws_dynamodb_table.terraform_lock "${TABLE_OLD}" || echo "⚠️  Tabela já importada ou não existe"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Recursos importados!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Próximos passos:"
    echo "  1. terraform plan  (verifique as mudanças)"
    echo "  2. terraform apply (aplique as mudanças)"
    echo ""
    
else
    echo "❌ Opção inválida"
    exit 1
fi

echo ""
echo "🎉 Processo concluído!"
