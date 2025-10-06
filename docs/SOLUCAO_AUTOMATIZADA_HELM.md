# ✅ Solução Automatizada: AWS Load Balancer Controller via Helm + Terraform

## 🎯 Abordagem Escolhida

**Instalação TOTALMENTE AUTOMATIZADA via Terraform + Helm Provider**

- ✅ Zero intervenção manual
- ✅ Helm gerencia versões automaticamente
- ✅ TargetGroupBinding funciona perfeitamente
- ✅ Integração nativa com Terraform state
- ✅ Reproduzível e versionado

## 🏗️ Arquitetura Implementada

```
API Gateway → VPC Link → NLB → TargetGroupBinding → ClusterIP Service → Pods
                                        ↑
                            AWS Load Balancer Controller
                                (Helm Chart)
```

### Fluxo Automático:

1. **Terraform cria EKS cluster** com addons nativos (vpc-cni, kube-proxy, coredns)
2. **Helm provider instala** AWS Load Balancer Controller automaticamente
3. **TargetGroupBinding** conecta automaticamente o ClusterIP Service ao NLB
4. **Controller registra IPs** dos pods no Target Group do NLB
5. **Tudo gerenciado** via `terraform apply` - zero comandos manuais!

## 📦 Componentes Implementados

### 1. **Providers Terraform (infra-core/main.tf)**

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    }
  }
}
```

### 2. **AWS Load Balancer Controller via Helm (infra-core/main.tf)**

```terraform
# Service Account para o controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }
}

# Helm Release - Instalação automatizada
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.9.2"  # Compatível com EKS 1.33

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }

  set {
    name  = "region"
    value = "us-east-1"
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_eks_addon.vpc_cni,
    aws_eks_addon.coredns
  ]
}
```

### 3. **Target Group para IPs (infra-core/main.tf)**

```terraform
resource "aws_lb_target_group" "app" {
  name        = "tech-challenge-app-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"  # Controller registra IPs dos pods automaticamente

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "HTTP"
    path                = "/actuator/health"
    port                = "traffic-port"
    timeout             = 10
  }
}
```

### 4. **ClusterIP Service + TargetGroupBinding (application/terraform/main.tf)**

```terraform
# Service interno (ClusterIP)
resource "kubernetes_service" "tech_challenge_service" {
  spec {
    type = "ClusterIP"
    
    port {
      port        = 80
      target_port = 8080
    }
  }
}

# TargetGroupBinding - Conecta ao NLB automaticamente
resource "kubernetes_manifest" "target_group_binding" {
  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "tech-challenge-tgb"
      namespace = "default"
    }
    spec = {
      serviceRef = {
        name = kubernetes_service.tech_challenge_service.metadata[0].name
        port = 80
      }
      targetGroupARN = data.terraform_remote_state.core.outputs.target_group_arn
      targetType     = "ip"
    }
  }
}
```

## 🚀 Deploy Automatizado

### Comando Único:

```bash
# 1. Deploy infra-core (instala tudo automaticamente)
cd tech-challenge-infra-core
terraform init
terraform apply

# 2. Deploy application (TargetGroupBinding conecta automaticamente)
cd ../tech-challenge-application/terraform
terraform init
terraform apply

# 3. Pronto! Nada mais necessário
```

### O que acontece automaticamente:

1. ✅ EKS cluster criado
2. ✅ Addons nativos instalados (vpc-cni, kube-proxy, coredns)
3. ✅ **Helm instala AWS Load Balancer Controller**
4. ✅ NLB e Target Group criados
5. ✅ Pods deployed no EKS
6. ✅ **Controller registra pods no Target Group automaticamente**
7. ✅ Health checks passam automaticamente
8. ✅ API Gateway pode se conectar ao NLB

## 🎯 Vantagens da Solução

| Aspecto | Solução Automatizada |
|---------|---------------------|
| **Setup** | 🟢 `terraform apply` - ZERO comandos manuais |
| **Manutenção** | 🟢 Totalmente gerenciado pelo Terraform |
| **Versionamento** | 🟢 Helm chart versão 1.9.2 (compatível EKS 1.33) |
| **Escalabilidade** | 🟢 Novos pods são registrados automaticamente |
| **Reprodutibilidade** | 🟢 100% reproduzível em qualquer ambiente |
| **State Management** | 🟢 Tudo no Terraform state |
| **Rollback** | 🟢 `terraform destroy` remove tudo |
| **Upgrades** | 🟢 Mudar versão do chart e aplicar |

## 🔍 Verificação

### 1. Verificar Controller instalado:

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

Output esperado:
```
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           5m
```

### 2. Verificar TargetGroupBinding:

```bash
kubectl describe targetgroupbinding tech-challenge-tgb
```

Output esperado:
```
Events:
  Type    Reason                Age   Message
  ----    ------                ----  -------
  Normal  SuccessfullyReconciled 1m   Successfully reconciled
```

### 3. Verificar targets no NLB:

```bash
aws elbv2 describe-target-health \
  --target-group-arn $(cd tech-challenge-infra-core && terraform output -raw target_group_arn)
```

Output esperado:
```json
{
  "TargetHealthDescriptions": [
    {
      "Target": {
        "Id": "10.0.1.x",
        "Port": 80
      },
      "HealthCheckPort": "80",
      "TargetHealth": {
        "State": "healthy"
      }
    }
  ]
}
```

## 🐛 Troubleshooting

### Helm release falhou

**Sintoma:** `Error: failed to install chart`

**Solução:**
```bash
# Verificar se providers estão configurados
cd tech-challenge-infra-core
terraform state list | grep helm_release

# Re-aplicar
terraform apply -target=helm_release.aws_load_balancer_controller
```

### TargetGroupBinding não funciona

**Sintoma:** `Error: unknown resource type elbv2.k8s.aws/v1beta1`

**Solução:**
```bash
# Verificar se CRDs foram instalados
kubectl get crd targetgroupbindings.elbv2.k8s.aws

# Se não existir, aguardar controller instalar (pode levar 1-2 minutos)
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Targets não ficam healthy

**Sintoma:** Target Group mostra `initial` ou `unhealthy`

**Solução:**
```bash
# Verificar se pods estão rodando
kubectl get pods

# Verificar logs do controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verificar TargetGroupBinding
kubectl describe targetgroupbinding tech-challenge-tgb
```

## 📊 Comparação: Manual vs Automatizado

| Tarefa | Abordagem Manual | Terraform + Helm |
|--------|-----------------|------------------|
| **Instalar Controller** | 5+ comandos kubectl/helm | `terraform apply` |
| **Configurar RBAC** | Múltiplos YAMLs | Helm chart gerencia |
| **Criar CRDs** | kubectl apply | Helm chart gerencia |
| **Atualizar versão** | helm upgrade manual | Mudar `version` e apply |
| **Remover tudo** | Múltiplos comandos | `terraform destroy` |
| **Reproduzir** | Documentação externa | Terraform code |
| **State tracking** | Não rastreado | Terraform state |

## ✅ Checklist de Deploy

- [ ] Providers Terraform configurados (aws, helm, kubernetes)
- [ ] Helm release configurado no infra-core
- [ ] Target Group com `target_type = "ip"`
- [ ] ClusterIP Service no application
- [ ] TargetGroupBinding configurado
- [ ] Terraform apply no infra-core
- [ ] Aguardar controller instalar (~2 minutos)
- [ ] Terraform apply no application
- [ ] Verificar targets healthy

## 📚 Referências

- [Helm Provider Terraform](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
- [AWS Load Balancer Controller Helm Chart](https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller)
- [TargetGroupBinding CRD](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.9/guide/targetgroupbinding/targetgroupbinding/)

---

**✅ Solução 100% automatizada via Terraform - Zero intervenção manual necessária!**

**Última atualização:** 05/10/2025