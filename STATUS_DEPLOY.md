# Status do Deploy

## Commit Realizado

**Commit:** 7527ed7  
**Mensagem:** chore: valida infraestrutura e inicia deploy  
**Branch:** main  
**Status:** Pushed para origin/main

## Workflow Acionado

O push para `main` vai acionar automaticamente o workflow **Infrastructure Core CI/CD** (`main.yml`).

### Fluxo do Workflow

1. **Checkout** - Clona o repositório
2. **Setup Terraform** - Instala Terraform 1.5.0 (com terraform_wrapper: false)
3. **Configure AWS credentials** - Usa secrets do GitHub
4. **Generate Backend Configuration** - Executa `./generate-backend.sh`
5. **Terraform Init** - Inicializa backend S3
6. **Terraform Validate** - Valida sintaxe
7. **Terraform Plan** - Cria plano de execução
8. **Terraform Apply** - Aplica mudanças (automático em push para main)

## Recursos que Serão Criados/Atualizados

### VPC e Rede
- VPC (10.0.0.0/16)
- 2 Subnets privadas
- Internet Gateway
- Route Tables
- NAT Gateway

### EKS
- EKS Cluster (tech-challenge-eks)
- Node Group (t3.small, 1-2 nodes)
- OIDC Provider

### Load Balancer Controller
- Helm Release (AWS Load Balancer Controller)
- Service Account com IAM Role

### Cognito
- User Pool
- User Pool Client

### ECR
- Repository para imagens Docker

### Network Load Balancer
- NLB
- Target Group
- Listeners

## Monitoramento do Deploy

### Via GitHub Actions

1. Acesse: https://github.com/group-240/tech-challenge-infra-core/actions
2. Procure pelo workflow "Infrastructure Core CI/CD"
3. Clique no último run (commit 7527ed7)
4. Acompanhe os logs em tempo real

### Via CLI (se necessário)

```bash
# Ver status do workflow
gh run list --repo group-240/tech-challenge-infra-core

# Ver logs do último run
gh run view --repo group-240/tech-challenge-infra-core

# Ver logs em tempo real
gh run watch --repo group-240/tech-challenge-infra-core
```

## Tempo Estimado

- **Terraform Init:** ~30 segundos
- **Terraform Validate:** ~5 segundos
- **Terraform Plan:** ~1-2 minutos
- **Terraform Apply:**
  - VPC/Subnets: ~2 minutos
  - EKS Cluster: ~10-15 minutos
  - Node Group: ~5 minutos
  - Helm (LB Controller): ~2 minutos
  - Cognito/ECR/NLB: ~2 minutos

**Total estimado:** ~20-25 minutos

## Validações Após Deploy

### 1. Verificar Outputs

```bash
cd tech-challenge-infra-core
terraform output
```

### 2. Verificar EKS

```bash
aws eks describe-cluster --name tech-challenge-eks --region us-east-1
aws eks list-nodegroups --cluster-name tech-challenge-eks --region us-east-1
```

### 3. Configurar kubectl

```bash
aws eks update-kubeconfig --name tech-challenge-eks --region us-east-1
kubectl get nodes
kubectl get pods -A
```

### 4. Verificar Load Balancer Controller

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### 5. Verificar NLB

```bash
aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[?contains(LoadBalancerName, `tech-challenge`)].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}'
```

## Próximos Passos

Após o deploy do infra-core ser concluído com sucesso:

1. **Deploy Database**
   ```bash
   cd tech-challenge-infra-database
   git add -A
   git commit -m "chore: inicia deploy do database"
   git push
   ```

2. **Deploy Application**
   ```bash
   cd tech-challenge-application
   git add -A
   git commit -m "chore: inicia deploy da aplicação"
   git push
   ```

3. **Deploy Gateway**
   ```bash
   cd tech-challenge-infra-gateway-lambda
   git add -A
   git commit -m "chore: inicia deploy do gateway"
   git push
   ```

## Troubleshooting

### Se o workflow falhar

1. Verifique os logs no GitHub Actions
2. Erros comuns:
   - Credenciais AWS expiradas
   - Backend S3 não existe (execute bootstrap primeiro)
   - Quotas AWS excedidas
   - Permissões IAM insuficientes

### Se precisar reexecutar

```bash
# Via GitHub Actions
# Actions > Infrastructure Core CI/CD > Re-run jobs

# Via CLI local (se tiver Terraform instalado)
cd tech-challenge-infra-core
./generate-backend.sh
terraform init
terraform plan
terraform apply
```

## Status Atual

- [x] Infraestrutura validada
- [x] Commit realizado
- [x] Push para main concluído
- [ ] Workflow em execução (verificar GitHub Actions)
- [ ] Deploy concluído (aguardar ~20-25 minutos)
- [ ] Validações pós-deploy
- [ ] Deploy dos outros repositórios

## Logs e Documentação

- **Workflow logs:** GitHub Actions
- **Terraform state:** S3 (tech-challenge-tfstate-533267363894-10/core/terraform.tfstate)
- **Documentação:** docs/README.md (guia completo)
