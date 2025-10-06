# AWS Load Balancer Controller - Instalação Manual
# Este controller NÃO é um addon nativo do EKS e deve ser instalado separadamente

## ⚠️ IMPORTANTE: Execute APÓS o cluster EKS estar pronto

## 📋 Pré-requisitos:
# - Cluster EKS criado (tech-challenge-eks)
# - kubectl configurado
# - helm instalado

## 🚀 Passos para Instalação:

### 1. Configurar kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name tech-challenge-eks
```

### 2. Criar IAM Policy para o Load Balancer Controller
```bash
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy.json
```

### 3. Criar Service Account com IRSA (IAM Roles for Service Accounts)
```bash
# NOTA: AWS Academy Lab Role pode ter limitações para criar IRSA
# Se falhar, pule esta etapa e use a instalação simplificada

eksctl create iamserviceaccount \
  --cluster=tech-challenge-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::533267363894:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve
```

### 4. Adicionar Helm Repository
```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

### 5. Instalar AWS Load Balancer Controller
```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=tech-challenge-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=<VPC_ID>
```

### 6. Verificar Instalação
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

---

## ⚡ Instalação Simplificada (Para AWS Academy)

Se você tem limitações no AWS Academy, use esta abordagem sem IRSA:

```bash
# 1. Configurar kubectl
aws eks update-kubeconfig --region us-east-1 --name tech-challenge-eks

# 2. Instalar usando manifests diretos (sem Helm)
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.11.0/v2_11_0_full.yaml
```

---

## 🔍 Validação

### Verificar se o controller está rodando:
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

Output esperado:
```
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           1m
```

### Verificar logs:
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

---

## 🎯 Alternativa: TargetGroupBinding Manual

Se a instalação do Load Balancer Controller falhar devido a limitações do AWS Academy, você pode usar uma abordagem mais simples:

### 1. Não usar TargetGroupBinding no Terraform

No arquivo `tech-challenge-application/terraform/main.tf`, **REMOVA** o resource `kubernetes_manifest.target_group_binding`.

### 2. Registrar manualmente os EC2 nodes no Target Group

```bash
# 1. Obter IDs dos EC2 nodes do EKS
NODE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tech-challenge-eks-nodes" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

# 2. Registrar nodes no Target Group
TARGET_GROUP_ARN=$(cd tech-challenge-infra-core && terraform output -raw target_group_arn)

for node_id in $NODE_IDS; do
  aws elbv2 register-targets \
    --target-group-arn $TARGET_GROUP_ARN \
    --targets Id=$node_id,Port=30000
done
```

### 3. Mudar o Service para NodePort

No `tech-challenge-application/terraform/main.tf`:
```terraform
resource "kubernetes_service" "tech_challenge_service" {
  spec {
    type = "NodePort"
    node_port = 30000  # Porta fixa no node
    
    port {
      port        = 80
      target_port = 8080
      node_port   = 30000
    }
  }
}
```

---

## 📚 Referências

- [AWS Load Balancer Controller Docs](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Workshop - Load Balancer Controller](https://www.eksworkshop.com/beginner/180_fargate/prerequisites-for-alb/)
- [TargetGroupBinding Custom Resource](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.11/guide/targetgroupbinding/targetgroupbinding/)

---

## 🐛 Troubleshooting

### Erro: "webhook não encontrado"
```bash
# Reinstalar CRDs
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
```

### Erro: "permissões insuficientes"
```bash
# Verificar se o LabRole tem as permissões necessárias
# No AWS Academy, algumas permissões podem estar limitadas
```

### TargetGroupBinding não funciona
```bash
# Use a abordagem NodePort + registro manual de targets (veja seção acima)
```