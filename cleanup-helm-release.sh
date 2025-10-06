#!/bin/bash

# Script para limpar o Helm release falho do AWS Load Balancer Controller
# Execute este script antes de fazer terraform apply novamente

set -e

echo "=========================================="
echo "Limpeza do Helm Release Falho"
echo "=========================================="
echo ""

# Configurar kubectl para o cluster EKS
echo "1. Configurando kubectl para o cluster EKS..."
aws eks update-kubeconfig --name tech-challenge-eks --region us-east-1

echo ""
echo "2. Verificando releases do Helm no namespace kube-system..."
helm list -n kube-system

echo ""
echo "3. Removendo release falho do AWS Load Balancer Controller (se existir)..."
if helm list -n kube-system | grep -q "aws-load-balancer-controller"; then
    echo "   Release encontrado. Removendo..."
    helm uninstall aws-load-balancer-controller -n kube-system --wait
    echo "   ✓ Release removido com sucesso!"
else
    echo "   Release não encontrado (pode já ter sido removido)"
fi

echo ""
echo "4. Verificando pods restantes..."
kubectl get pods -n kube-system | grep -i "load-balancer" || echo "   Nenhum pod do load-balancer encontrado (OK)"

echo ""
echo "5. Aguardando pods serem completamente removidos..."
sleep 10

echo ""
echo "=========================================="
echo "✓ Limpeza concluída com sucesso!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "  1. Execute: terraform apply"
echo "  2. O Helm chart será reinstalado com as novas configurações"
echo "  3. Agora com timeout de 10 minutos e webhooks desabilitados"
echo ""
