# Validação de Workflows - Deploy AWS Tech Challenge

## 🏗️ **Workflows por Repositório**

### 1. **tech-challenge-infra-core**

#### 📁 Workflows:
- ✅ `.github/workflows/main.yml` - Deploy da infraestrutura core
- ✅ `.github/workflows/bootstrap.yml` - **NOVO** - Criação do S3 backend

#### 🔧 Configurações:
```yaml
triggers: pull_request + push (main)
aws_region: us-east-1
terraform_version: 1.5.0
jobs:
  - terraform-plan (apenas PRs)
  - terraform-apply (apenas push main)
```

#### 📦 Recursos criados:
- VPC, Subnets, NAT Gateway
- EKS Cluster (`tech-challenge-eks`)
- Cognito User Pool + Client
- ECR Repository (`tech-challenge-api`)
- Network Load Balancer
- Target Groups

#### 🎯 **Ordem de execução**: **1º**

---

### 2. **tech-challenge-infra-database**

#### 📁 Workflows:
- ✅ `.github/workflows/main.yml` - Deploy do RDS PostgreSQL

#### 🔧 Configurações:
```yaml
triggers: pull_request + push (main) + workflow_dispatch
aws_region: us-east-1
terraform_version: 1.5.0
secrets_required: DB_PASSWORD
```

#### 📦 Recursos criados:
- RDS PostgreSQL 14.12
- Subnet Groups
- Security Groups

#### 🎯 **Ordem de execução**: **2º**

---

### 3. **tech-challenge-application**

#### 📁 Workflows:
- ✅ `.github/workflows/main.yml` - Build + Deploy da aplicação

#### 🔧 Configurações:
```yaml
triggers: pull_request + push (main)
aws_region: us-east-1
ecr_repository: tech-challenge-api
eks_cluster_name: tech-challenge-eks ✅ (CORRIGIDO)
secrets_required: DB_PASSWORD, JWT_SECRET
```

#### 📦 Processo:
1. **Build & Test**: Maven build + tests
2. **Docker**: Build + Push para ECR
3. **Deploy**: Terraform apply no EKS

#### 🎯 **Ordem de execução**: **3º**

---

### 4. **tech-challenge-infra-gateway-lambda**

#### 📁 Workflows:
- ✅ `.github/workflows/deploy.yml` - Deploy do API Gateway

#### 🔧 Configurações:
```yaml
triggers: pull_request + push (main) + workflow_dispatch
aws_region: us-east-1
terraform_version: 1.5.0
```

#### 📦 Recursos criados:
- API Gateway REST API
- VPC Link para NLB
- Cognito Authorizer
- Métodos com autenticação

#### 🎯 **Ordem de execução**: **4º**

---

## 🚀 **Ordem de Deploy Correta**

```bash
# 1. Bootstrap (apenas primeira vez)
Repository: tech-challenge-infra-core
Workflow: bootstrap.yml
Action: Manual dispatch
Resources: S3 + DynamoDB para state

# 2. Core Infrastructure
Repository: tech-challenge-infra-core  
Workflow: main.yml
Trigger: Push to main
Resources: VPC, EKS, Cognito, ECR, NLB

# 3. Database
Repository: tech-challenge-infra-database
Workflow: main.yml
Trigger: Push to main
Resources: RDS PostgreSQL

# 4. Application
Repository: tech-challenge-application
Workflow: main.yml
Trigger: Push to main
Resources: Docker build + EKS deployment

# 5. API Gateway
Repository: tech-challenge-infra-gateway-lambda
Workflow: deploy.yml
Trigger: Push to main
Resources: API Gateway + Cognito auth
```

---

## 🔐 **Secrets Necessários**

### Para todos os repositórios:
```bash
AWS_ACCESS_KEY_ID      # Chave de acesso AWS
AWS_SECRET_ACCESS_KEY  # Secret key AWS  
AWS_SESSION_TOKEN      # Token de sessão (AWS Academy)
```

### Para repositórios específicos:
```bash
# tech-challenge-infra-database + tech-challenge-application
DB_PASSWORD="DevPassword123!"

# tech-challenge-application  
JWT_SECRET="dev-jwt-secret-key-12345"
```

---

## 📋 **Checklist de Validação**

### ✅ **Workflows Corretos**
- [x] Bootstrap está no infra-core
- [x] Account ID correto (533267363894)
- [x] Nome do cluster EKS correto (tech-challenge-eks)
- [x] ECR repository criado
- [x] Ordem de dependências respeitada

### ✅ **Infraestrutura Pronta**
- [x] S3 backend configurado
- [x] Remote state sharing funcionando
- [x] NLB no infra-core (shared infrastructure)
- [x] Cognito authorizer implementado

### ✅ **Deploy Funcional**
- [x] Terraform init/plan/apply em todos
- [x] Docker build + ECR push
- [x] EKS deployment via Terraform
- [x] API Gateway com autenticação

---

## 🧪 **Como Testar o Deploy**

### 1. **Executar Bootstrap** (apenas primeira vez)
```bash
# No GitHub Actions do tech-challenge-infra-core
# Actions → Bootstrap → Run workflow
```

### 2. **Push nos repositórios na ordem:**
```bash
1. tech-challenge-infra-core (main branch)
2. tech-challenge-infra-database (main branch)  
3. tech-challenge-application (main branch)
4. tech-challenge-infra-gateway-lambda (main branch)
```

### 3. **Verificar recursos criados:**
```bash
# VPC + EKS
aws eks describe-cluster --name tech-challenge-eks

# ECR
aws ecr describe-repositories --repository-names tech-challenge-api

# RDS
aws rds describe-db-instances --db-instance-identifier tech-challenge-db

# API Gateway
aws apigateway get-rest-apis --query 'items[?name==`tech-challenge-api`]'

# NLB
aws elbv2 describe-load-balancers --names tech-challenge-nlb
```

---

## 🎯 **Estado Final Esperado**

```
Internet → Cognito → API Gateway → VPC Link → NLB → EKS Pods → RDS
```

### 🔗 **Endpoints funcionais:**
- ✅ `/health` (público)
- ✅ `/products` (público)  
- ✅ `/categories` (público)
- ✅ `/webhooks` (público)
- 🔐 `/orders` (Cognito auth)
- 🔐 `/payments` (Cognito auth)
- 🔐 `/customers` (Cognito auth)

### 📊 **Recursos provisionados:**
- 1x VPC com 2 AZs
- 1x EKS cluster (1 node SPOT)
- 1x RDS PostgreSQL
- 1x NLB interno
- 1x API Gateway REST
- 1x Cognito User Pool
- 1x ECR repository

**✅ Todos os workflows estão validados e prontos para deploy na AWS!**