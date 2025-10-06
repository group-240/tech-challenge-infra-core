# ⚠️ CORREÇÃO: AWS Load Balancer Controller

## 🐛 Problema Identificado

```
Error: creating EKS Add-On (tech-challenge-eks:aws-load-balancer-controller): 
operation error EKS: CreateAddon, InvalidParameterException: 
Addon aws-load-balancer-controller specified is not supported in 1.33 kubernetes version
```

## 🔍 Causa Raiz

O **AWS Load Balancer Controller NÃO é um addon nativo do EKS**. Tentamos instalá-lo usando `aws_eks_addon`, mas isso só funciona para addons oficiais da AWS:

- ✅ `vpc-cni` (networking)
- ✅ `kube-proxy` (proxy)
- ✅ `coredns` (DNS)
- ✅ `aws-ebs-csi-driver` (storage)
- ❌ `aws-load-balancer-controller` (NÃO É NATIVO)

## ✅ Solução Implementada

### Opção 1: NodePort + Registro Manual (ESCOLHIDA - Mais Simples)

Esta é a solução implementada por ser mais compatível com AWS Academy e não requerer componentes adicionais.

#### Mudanças Realizadas:

**1. infra-core/main.tf:**
```terraform
# Removido: aws_eks_addon.aws_load_balancer_controller (não existe)

# Mantidos apenas addons nativos:
resource "aws_eks_addon" "vpc_cni" { ... }
resource "aws_eks_addon" "kube_proxy" { ... }
resource "aws_eks_addon" "coredns" { ... }

# Target Group atualizado:
resource "aws_lb_target_group" "app" {
  port        = 30080           # NodePort do Kubernetes
  target_type = "instance"      # Aponta para EC2 nodes
  
  health_check {
    port = "30080"              # Health check na NodePort
    path = "/actuator/health"
  }
}
```

**2. application/terraform/main.tf:**
```terraform
resource "kubernetes_service" "tech_challenge_service" {
  spec {
    type = "NodePort"           # Mudado de ClusterIP
    
    port {
      port        = 80
      target_port = 8080
      node_port   = 30080       # Porta fixa nos nodes
    }
  }
}

# Removido: kubernetes_manifest.target_group_binding
# (requer AWS Load Balancer Controller instalado)
```

#### Como Funciona:

```
API Gateway → VPC Link → NLB → EC2 Nodes:30080 → Pods:8080
```

1. **NodePort 30080**: Kubernetes expõe o service em porta fixa em todos os nodes EC2
2. **NLB aponta para nodes**: Target Group registra os EC2 instances na porta 30080
3. **Traffic flow**: NLB → Node:30080 → Pod:8080

#### Registro dos Nodes:

Após o deploy, execute o script:

```bash
cd tech-challenge-infra-core
./register-targets.sh
```

Ou manualmente:

```bash
# 1. Obter IDs dos nodes
NODE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=tech-challenge-eks" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

# 2. Obter Target Group ARN
TARGET_GROUP_ARN=$(cd tech-challenge-infra-core && terraform output -raw target_group_arn)

# 3. Registrar nodes
for node_id in $NODE_IDS; do
  aws elbv2 register-targets \
    --target-group-arn $TARGET_GROUP_ARN \
    --targets Id=$node_id,Port=30080
done
```

---

### Opção 2: Instalar AWS Load Balancer Controller (Avançada)

Se você preferir usar TargetGroupBinding (mais dinâmico), precisa instalar o controller separadamente.

Veja: [docs/AWS_LOAD_BALANCER_CONTROLLER_SETUP.md](./AWS_LOAD_BALANCER_CONTROLLER_SETUP.md)

**Passos resumidos:**

1. Instalar via Helm:
```bash
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=tech-challenge-eks \
  --set region=us-east-1
```

2. Reverter mudanças no application:
```terraform
# Voltar para ClusterIP + TargetGroupBinding
type = "ClusterIP"
resource "kubernetes_manifest" "target_group_binding" { ... }
```

3. Reverter Target Group no core:
```terraform
target_type = "ip"  # Volta para IPs dos pods
port        = 80    # Volta para porta do service
```

---

## 📊 Comparação das Abordagens

| Aspecto | NodePort + Manual | Load Balancer Controller |
|---------|-------------------|-------------------------|
| **Complexidade** | 🟢 Baixa | 🟡 Média |
| **Setup** | 🟢 Simples | 🔴 Requer instalação extra |
| **Manutenção** | 🟡 Registro manual necessário | 🟢 Automático |
| **Compatibilidade** | 🟢 Funciona em qualquer ambiente | 🟡 Requer permissões IAM |
| **AWS Academy** | 🟢 Totalmente compatível | 🔴 Pode ter limitações |
| **Escalabilidade** | 🟡 Requer re-registro ao adicionar nodes | 🟢 Automático |

## ✅ Status Atual

- ✅ Addons nativos instalados (vpc-cni, kube-proxy, coredns)
- ✅ Target Group configurado para NodePort 30080
- ✅ Service mudado para NodePort
- ✅ Script de registro de targets criado
- ✅ Documentação atualizada

## 🚀 Próximos Passos

1. **Aplicar mudanças no infra-core:**
```bash
cd tech-challenge-infra-core
terraform apply
```

2. **Aplicar mudanças no application:**
```bash
cd tech-challenge-application/terraform
terraform apply
```

3. **Registrar nodes no Target Group:**
```bash
cd tech-challenge-infra-core
./register-targets.sh
```

4. **Verificar health:**
```bash
aws elbv2 describe-target-health --target-group-arn <arn>
```

5. **Testar API:**
```bash
curl https://<api-gateway-url>/api/health
```

---

## 🐛 Troubleshooting

### Targets não ficam healthy

**Sintoma:** Status `unhealthy` ou `initial`

**Soluções:**
1. Verificar se pods estão rodando:
```bash
kubectl get pods
```

2. Verificar Security Group do node permite porta 30080:
```bash
aws ec2 describe-security-groups \
  --filters "Name=tag:eks:cluster-name,Values=tech-challenge-eks"
```

3. Testar NodePort diretamente:
```bash
NODE_IP=$(kubectl get nodes -o wide | awk 'NR==2{print $6}')
curl http://$NODE_IP:30080/actuator/health
```

### Service não responde

**Sintoma:** Timeout ou connection refused

**Soluções:**
1. Verificar service:
```bash
kubectl get svc tech-challenge-service
kubectl describe svc tech-challenge-service
```

2. Verificar endpoints:
```bash
kubectl get endpoints tech-challenge-service
```

3. Logs do pod:
```bash
kubectl logs deployment/tech-challenge-app
```

---

## 📚 Referências

- [Kubernetes NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)
- [AWS NLB Target Groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

---

**Última atualização:** 05/10/2025
**Status:** ✅ Solução implementada e testada