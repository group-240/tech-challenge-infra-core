 # 🔄 Configurações Compartilhadas - Tech Challenge

> **⚠️ ATENÇÃO**: Este arquivo lista todas as configurações que devem ser mantidas sincronizadas entre os repositórios. Qualquer mudança em uma dessas configurações deve ser aplicada em TODOS os repositórios afetados.

## 🔴 Configurações Críticas (Quebram Sistema se Divergirem)

### 1. **Identificadores Globais**

| Configuração | Valor Atual | Arquivos Afetados | Repositórios |
|--------------|-------------|-------------------|--------------|
| `project_name` | `"tech-challenge"` | `variables.tf` | **TODOS** |
| `aws_region` | `"us-east-1"` | `provider.tf`, workflows | **TODOS** |
| `account_id` | `"533267363894"` | bootstrap, backends | **TODOS** |

### 2. **Terraform Backend**

| Configuração | Valor Atual | Arquivos | Repositórios |
|--------------|-------------|----------|--------------|
| S3 Bucket | `tech-challenge-tfstate-533267363894-4` | `main.tf` (backend) | **TODOS** |
| DynamoDB Table | `tech-challenge-terraform-lock-533267363894` | `main.tf` (backend) | **TODOS** |
| State Key Prefix | `infra/` | `main.tf` (backend) | **TODOS** |

### 3. **Nomes de Recursos AWS**

| Recurso | Padrão Atual | Repositórios | Exemplo |
|---------|-------------|--------------|---------|
| EKS Cluster | `${project_name}-eks` | core, application | `tech-challenge-eks` |
| RDS Instance | `${project_name}-db` | database, application | `tech-challenge-db` |
| ECR Repository | `${project_name}-api` | core, application | `tech-challenge-api` |
| NLB Name | `${project_name}-nlb` | core, gateway | `tech-challenge-nlb` |
| API Gateway | `${project_name}-api` | gateway | `tech-challenge-api` |
| Cognito Pool | `${project_name}-user-pool` | core, gateway | `tech-challenge-user-pool` |

## 🟡 Configurações de Rede (Devem Ser Consistentes)

### VPC e Subnets

| Configuração | Valor | Repositórios | Arquivo |
|--------------|-------|--------------|---------|
| VPC CIDR | `10.0.0.0/16` | core, database | `main.tf` |
| Subnet Pública | `10.0.0.0/24` | core | `main.tf` |
| Subnet Privada 1 | `10.0.1.0/24` | core, database | `main.tf` |
| Subnet Privada 2 | `10.0.2.0/24` | core, database | `main.tf` |

### Portas e Protocolos

| Serviço | Porta | Protocolo | Repositórios |
|---------|-------|-----------|--------------|
| Application Container | `8080` | HTTP | application |
| Kubernetes Service | `80` | HTTP | application, gateway |
| NLB Listener | `80` | TCP | core, gateway |
| RDS PostgreSQL | `5432` | TCP | database, application |
| API Gateway | `443` | HTTPS | gateway |

## 🔐 Configurações de Segurança

### Database

| Configuração | Valor | Repositórios | Observações |
|--------------|-------|--------------|-------------|
| DB Name | `tech_challenge` | database, application | Nome do banco |
| DB Username | `postgres` | database, application | Usuário admin |
| DB Password | `DevPassword123!` | database, application | **Hardcoded DEV** |

### JWT e Secrets

| Secret | Valor | Repositórios | Uso |
|--------|-------|--------------|-----|
| JWT_SECRET | `dev-jwt-secret-key-12345` | application | **Hardcoded DEV** |
| DB_PASSWORD | `DevPassword123!` | database, application | **Hardcoded DEV** |

## 🐳 Configurações de Container

### Docker e ECR

| Configuração | Valor | Repositórios | Arquivo |
|--------------|-------|--------------|---------|
| ECR Repository Name | `tech-challenge-api` | core, application | workflows |
| Image Tag Strategy | `${github.sha}` + `latest` | application | workflows |
| Container Port | `8080` | application | Dockerfile, K8s |
| Health Check Path | `/actuator/health` | core, application | NLB, K8s |

### Kubernetes

| Configuração | Valor | Repositórios | Arquivo |
|--------------|-------|--------------|---------|
| Namespace | `default` | application | `main.tf` |
| Service Type | `ClusterIP` | application | `main.tf` |
| Service Name | `tech-challenge-service` | application | `main.tf` |
| TargetGroupBinding Name | `tech-challenge-tgb` | application | `main.tf` |

## 📦 Configurações de CI/CD

### GitHub Actions

| Configuração | Valor | Repositórios | Arquivo |
|--------------|-------|--------------|---------|
| Terraform Version | `1.5.0` | **TODOS** | workflows |
| Java Version | `17` | application | workflow |
| Maven Goal | `clean package -DskipTests` | application | workflow |

### Secrets Necessários

| Secret | Repositórios | Descrição |
|--------|--------------|-----------|
| `AWS_ACCESS_KEY_ID` | **TODOS** | Credencial AWS |
| `AWS_SECRET_ACCESS_KEY` | **TODOS** | Credencial AWS |
| `AWS_SESSION_TOKEN` | **TODOS** | Token de sessão AWS Academy |
| `DB_PASSWORD` | database, application | Senha do PostgreSQL |
| `JWT_SECRET` | application | Chave JWT para tokens |

## 📝 Checklist de Sincronização

### ✅ Antes de Fazer Mudanças

- [ ] Identificar qual tipo de configuração está sendo alterada
- [ ] Verificar em quantos repositórios ela aparece
- [ ] Planejar ordem de aplicação das mudanças
- [ ] Verificar se existem dependências entre recursos

### ✅ Aplicando Mudanças

- [ ] Atualizar configuração em TODOS os repositórios afetados
- [ ] Fazer commit em todos mas NÃO fazer push ainda
- [ ] Executar `terraform plan` em cada repositório para validar
- [ ] Se todos os plans estão OK, fazer push na ordem correta

### ✅ Ordem de Deploy após Mudanças

```bash
1. tech-challenge-infra-core (base infrastructure)
2. tech-challenge-infra-database (depends on VPC from core)
3. tech-challenge-application (depends on EKS from core, RDS from database)
4. tech-challenge-infra-gateway-lambda (depends on NLB from core, Cognito from core)
```

## 🚨 Configurações Perigosas de Alterar

### ❌ **NUNCA alterar sem planejamento completo:**

1. **project_name** - Recria TODOS os recursos
2. **account_id** - Quebra backend do Terraform
3. **VPC CIDR** - Recria toda a rede
4. **EKS cluster name** - Quebra deployments
5. **RDS identifier** - Recria banco (PERDA DE DADOS)

### ⚠️ **Alterar com cuidado:**

1. **Subnet CIDRs** - Pode causar conflitos de rede
2. **Security Group rules** - Pode quebrar conectividade
3. **ECR repository name** - Quebra pipeline de deploy
4. **Terraform version** - Pode causar incompatibilidades

## 📖 Procedimento para Mudanças Seguras

### 1. **Mudança de project_name**

```bash
# Exemplo: tech-challenge → my-new-project

# 1. Atualizar em todos os repositórios
find . -name "variables.tf" -exec sed -i 's/tech-challenge/my-new-project/g' {} \;

# 2. Atualizar bucket S3 (bootstrap)
# infra-core/bootstrap/main.tf: bucket_name = "my-new-project-tfstate-533267363894-4"

# 3. Atualizar backend configs em todos os repos
# backend "s3" { bucket = "my-new-project-tfstate-533267363894-4" }

# 4. Executar terraform init para migrar state
terraform init -migrate-state

# 5. Deploy na ordem: core → database → application → gateway
```

### 2. **Mudança de AWS Region**

```bash
# Exemplo: us-east-1 → us-west-2

# 1. Atualizar providers em todos os repos
# 2. Atualizar workflows (.github/workflows/*.yml)
# 3. Criar novo bucket S3 na nova região
# 4. Migrar state files
# 5. Recriar TODA a infraestrutura
```

### 3. **Mudança de Database Password**

```bash
# 1. Atualizar GitHub Secrets
# 2. Deploy database (terraform apply)
# 3. Deploy application (terraform apply)
# 4. Verificar conectividade
```

## 🔍 Ferramentas para Verificar Sincronização

### Script para Verificar Consistência

```bash
#!/bin/bash
# check-sync.sh

echo "🔍 Verificando sincronização entre repositórios..."

# Verificar project_name
grep -r "project_name.*=.*\"" */variables.tf

# Verificar account_id  
grep -r "533267363894" */bootstrap/main.tf */main.tf

# Verificar bucket S3
grep -r "tech-challenge-tfstate" */main.tf

# Verificar cluster EKS
grep -r "tech-challenge-eks" */.github/workflows/*.yml

echo "✅ Verificação concluída"
```

### Validação com Terraform

```bash
# Em cada repositório
terraform init
terraform validate
terraform plan -detailed-exitcode

# Se exitcode = 0 → sem mudanças
# Se exitcode = 2 → mudanças pendentes  
# Se exitcode = 1 → erro
```

---

> **📚 Mantenha este arquivo atualizado sempre que adicionar nova configuração compartilhada!**
> 
> **🔄 Última atualização:** 04/10/2025
> 
> **👥 Responsável:** Equipe de Infraestrutura