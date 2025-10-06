# 🚀 Guia Rápido: Recuperação do Deploy

## ✅ Correções Aplicadas (Commit f183a68)

1. ✅ **Timeout aumentado** de 5 para 10 minutos
2. ✅ **Webhooks desabilitados** (eliminam fonte de falhas)
3. ✅ **Replace habilitado** (substitui release falho automaticamente)
4. ✅ **Script de limpeza** criado (`cleanup-helm-release.sh`)

## 🎯 O que fazer AGORA

O workflow já está executando novamente (push automático). Você tem **2 opções**:

### Opção 1: Aguardar o Workflow Atual ⏱️

O GitHub Actions está rodando agora com as novas configurações:
- ✅ Timeout de 10 minutos
- ✅ Webhooks desabilitados
- ✅ Replace automático do release falho

**Tempo estimado**: 10-15 minutos

**Como acompanhar**:
- GitHub Actions: https://github.com/group-240/tech-challenge-infra-core/actions

### Opção 2: Limpeza Manual + Reaplica 🔧

Se o workflow falhar novamente, execute:

```bash
# 1. Acesse o CloudShell da AWS ou configure AWS CLI + kubectl localmente

# 2. Configure kubectl
aws eks update-kubeconfig --name tech-challenge-eks --region us-east-1

# 3. Remova o release falho
helm uninstall aws-load-balancer-controller -n kube-system --wait

# 4. Force novo workflow (commit vazio)
git commit --allow-empty -m "chore: força reaplicação do helm release"
git push
```

## 📊 Como Verificar se Está Funcionando

Após o workflow completar:

### 1. Verificar Pods
```bash
kubectl get pods -n kube-system | grep load-balancer
```

**Esperado**:
```
aws-load-balancer-controller-xxxxx   1/1   Running   0   2m
```

### 2. Verificar Helm Release
```bash
helm list -n kube-system
```

**Esperado**:
```
NAME                          STATUS     CHART
aws-load-balancer-controller  deployed   aws-load-balancer-controller-1.9.2
```

### 3. Verificar Logs (se houver problemas)
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=50
```

## 🔍 Por que o Erro Aconteceu?

O erro `context deadline exceeded` aconteceu porque:

1. **Timeout Padrão**: 5 minutos não foi suficiente
2. **Webhooks**: Tentando configurar webhooks de validação
3. **Recursos Limitados**: 1 node t3.small SPOT demora mais para scheduling
4. **Certificados TLS**: Geração de certs para webhooks pode falhar

## ✅ O que Mudou?

### Antes (Configuração com Problemas)
```terraform
# Sem configurações de timeout
# Webhooks habilitados por padrão
# Esperando validações que podem falhar
```

### Depois (Configuração Corrigida)
```terraform
timeout              = 600  # 10 minutos
disable_webhooks     = true
replace              = true
enableMutatingWebhook    = false
enableValidatingWebhook  = false
webhookTLS.enabled       = false
```

## ⚠️ Webhooks Desabilitados - É Seguro?

**SIM!** Os webhooks são **opcionais**. Você ainda tem:

✅ **Todas as funcionalidades principais**:
- Criação de ALB/NLB
- Ingress controllers
- Service LoadBalancer
- Target Groups
- Health checks

❌ **O que você perde** (não crítico para dev):
- Validação automática de Ingress antes de aplicar
- Mutação automática de recursos

Para ambiente de **desenvolvimento/aprendizado**, é perfeitamente aceitável e até **recomendado** desabilitar os webhooks para evitar complexidade desnecessária.

## 🎯 Próximos Passos

1. ⏱️ **Aguarde** 10-15 minutos para o workflow completar
2. ✅ **Verifique** o status: `kubectl get pods -n kube-system`
3. 🎉 **Continue** para o deploy do database quando tudo estiver OK

## 💡 Dica

Se você ver mensagens como:
- "Release has a failed status" → **Normal**, o Terraform vai substituir
- "context deadline exceeded" novamente → Execute a limpeza manual (Opção 2)
- Pods em "Pending" → **Aguarde** mais alguns minutos

## 📚 Documentação Completa

Para detalhes técnicos completos, veja:
- **CORRECAO_HELM_TIMEOUT.md** - Explicação detalhada do erro e correções
- **cleanup-helm-release.sh** - Script de limpeza manual
- **DEPLOY_COMPLETO.md** - Guia completo de deploy

---

**TL;DR**: Aguarde o workflow completar (~10-15 min). Se falhar de novo, execute limpeza manual. As correções foram aplicadas e devem resolver o problema! 🚀
