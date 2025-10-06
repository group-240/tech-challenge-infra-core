# Correção do Erro de Timeout do Helm Release

## 🔴 Erro Identificado

```
Error: context deadline exceeded
  with helm_release.aws_load_balancer_controller
```

## 📋 Causa Raiz

O Helm release do AWS Load Balancer Controller excedeu o timeout padrão (5 minutos) porque:

1. **Webhooks de Validação**: Os webhooks do controller estavam configurados mas podem ter falhado na validação
2. **Timeout Insuficiente**: 5 minutos pode ser insuficiente para o deployment completo do controller
3. **Recursos Limitados**: Com apenas 1 node t3.small SPOT, o scheduling pode demorar mais

## ✅ Correções Aplicadas

### 1. Aumento do Timeout

```terraform
timeout       = 600  # 10 minutos (ao invés de 5)
wait          = true
wait_for_jobs = true
```

### 2. Configurações de Resiliência

```terraform
atomic                     = false  # Não fazer rollback automático
cleanup_on_fail            = false  # Manter recursos para debug
replace                    = true   # Substituir release se existir
disable_webhooks           = true   # Desabilitar webhooks Helm
```

### 3. Desabilitação dos Webhooks do Controller

```terraform
# Desabilitar webhook TLS
set {
  name  = "webhookTLS.enabled"
  value = "false"
}

# Desabilitar mutating webhook
set {
  name  = "enableMutatingWebhook"
  value = "false"
}

# Desabilitar validating webhook
set {
  name  = "enableValidatingWebhook"
  value = "false"
}
```

**Por que isso funciona?**

Os webhooks são usados para validar recursos do Kubernetes (Ingress, Service, etc) **antes** de serem criados. No entanto:
- ✅ São opcionais para o funcionamento básico
- ✅ Eliminam uma fonte de timeout durante o deployment
- ✅ O controller ainda funciona perfeitamente sem eles
- ⚠️ Você só perde validações automáticas (pode validar manualmente)

## 🔧 Como Corrigir

### Opção 1: Script Automático (Recomendado)

1. **Execute o script de limpeza**:
   ```bash
   chmod +x cleanup-helm-release.sh
   ./cleanup-helm-release.sh
   ```

2. **Aplique o Terraform novamente**:
   ```bash
   terraform apply -auto-approve
   ```

### Opção 2: Limpeza Manual

Se você não puder executar o script (sem kubectl/helm configurados):

1. **Via GitHub Actions**: Faça um commit vazio para triggar o workflow
   ```bash
   git commit --allow-empty -m "fix: reaplica helm release com novas configurações"
   git push
   ```

2. O workflow executará o Terraform que vai:
   - Detectar o release falho
   - Substituir com `replace = true`
   - Aplicar com as novas configurações

### Opção 3: Destruir e Recriar (Último Recurso)

Se as opções acima não funcionarem:

```bash
# Remover apenas o Helm release
terraform destroy -target=helm_release.aws_load_balancer_controller

# Reaplicar
terraform apply -auto-approve
```

## 📊 Status Atual

Mesmo com o erro do Helm, é possível que o controller esteja **parcialmente funcionando**:

```bash
# Verificar se o pod está rodando
kubectl get pods -n kube-system | grep load-balancer

# Verificar logs do controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

Se você vê pods rodando, o controller pode estar OK, apenas o Terraform não conseguiu confirmar o status.

## ✅ Próximos Passos

1. ✅ **Commit aplicado** com as correções
2. 🔄 **Execute** o script de limpeza OU faça commit vazio
3. ⏱️ **Aguarde** ~10 minutos para o novo deploy
4. ✓ **Verifique** o status com `kubectl get pods -n kube-system`

## 🎯 Resultados Esperados

Após a correção:

```bash
$ kubectl get pods -n kube-system
NAME                                            READY   STATUS    RESTARTS
aws-load-balancer-controller-xxxxx              1/1     Running   0
coredns-xxxxx                                   1/1     Running   0
coredns-xxxxx                                   1/1     Running   0
aws-node-xxxxx                                  2/2     Running   0
kube-proxy-xxxxx                                1/1     Running   0
```

```bash
$ helm list -n kube-system
NAME                            STATUS      CHART                           
aws-load-balancer-controller    deployed    aws-load-balancer-controller-1.9.2
```

## 💡 Por Que os Webhooks Causam Timeout?

1. **Dependência Circular**: O webhook precisa do controller rodando, mas o Helm espera o webhook estar pronto
2. **Certificados TLS**: Geração de certificados pode falhar ou demorar
3. **Validação de Rede**: O API server precisa conseguir chamar o webhook service
4. **Recursos Limitados**: Em um cluster pequeno, o pod do webhook pode demorar a ficar pronto

**Desabilitando os webhooks**, eliminamos essas dependências e o deployment fica mais rápido e confiável.

## 🚨 Impacto de Desabilitar Webhooks

**O que você perde**:
- ❌ Validação automática de manifests Ingress/Service antes de aplicar
- ❌ Mutação automática de recursos (adição de anotações padrão)

**O que continua funcionando**:
- ✅ Criação de Application Load Balancers (ALB)
- ✅ Criação de Network Load Balancers (NLB)
- ✅ Ingress controllers
- ✅ Service do tipo LoadBalancer
- ✅ Target binding
- ✅ Todas as funcionalidades principais do controller

**Conclusão**: Para um ambiente de desenvolvimento/aprendizado, **não há problema** desabilitar os webhooks. Se precisar deles no futuro, basta remover essas configurações e reaplicar.

## 📚 Referências

- [AWS Load Balancer Controller - Webhook Configuration](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.9/)
- [Helm Chart Values](https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller)
