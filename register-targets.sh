#!/bin/bash

# Script para registrar EC2 nodes do EKS no Target Group do NLB
# Execute este script APÓS fazer deploy do infra-core e application

set -e

echo "🔍 Registrando nodes EKS no Target Group do NLB..."

# Configurações
CLUSTER_NAME="tech-challenge-eks"
REGION="us-east-1"

# Obter ARN do Target Group
echo "📋 Obtendo Target Group ARN..."
cd "$(dirname "$0")"
TARGET_GROUP_ARN=$(terraform output -raw target_group_arn 2>/dev/null)

if [ -z "$TARGET_GROUP_ARN" ]; then
    echo "❌ Erro: Não foi possível obter o Target Group ARN"
    echo "   Certifique-se de estar no diretório tech-challenge-infra-core"
    exit 1
fi

echo "✅ Target Group ARN: $TARGET_GROUP_ARN"

# Obter IDs dos EC2 nodes do EKS
echo "🔍 Procurando EC2 nodes do cluster EKS..."
NODE_IDS=$(aws ec2 describe-instances \
    --region $REGION \
    --filters \
        "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" \
        "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)

if [ -z "$NODE_IDS" ]; then
    echo "❌ Erro: Nenhum node encontrado para o cluster $CLUSTER_NAME"
    echo "   Certifique-se de que o cluster EKS está rodando com nodes"
    exit 1
fi

echo "✅ Nodes encontrados: $NODE_IDS"

# Registrar cada node no Target Group
echo "📝 Registrando nodes no Target Group..."
for node_id in $NODE_IDS; do
    echo "   Registrando node: $node_id na porta 30080"
    aws elbv2 register-targets \
        --region $REGION \
        --target-group-arn $TARGET_GROUP_ARN \
        --targets Id=$node_id,Port=30080
done

echo "✅ Nodes registrados com sucesso!"

# Aguardar targets ficarem healthy
echo "⏳ Aguardando targets ficarem healthy..."
sleep 10

# Verificar status dos targets
echo "🔍 Verificando status dos targets..."
aws elbv2 describe-target-health \
    --region $REGION \
    --target-group-arn $TARGET_GROUP_ARN \
    --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]' \
    --output table

echo ""
echo "✅ Processo concluído!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Aguarde ~2 minutos para os health checks passarem"
echo "   2. Verifique o status novamente:"
echo "      aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN"
echo "   3. Teste o endpoint do API Gateway"
echo ""