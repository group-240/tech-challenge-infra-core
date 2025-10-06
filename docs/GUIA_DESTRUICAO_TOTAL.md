# 🧹 Guia de Destruição Total da Infraestrutura

## 🚨 ATENÇÃO - DANGER ZONE

Este guia descreve como **DESTRUIR COMPLETAMENTE** toda a infraestrutura do Tech Challenge na AWS usando workflows do GitHub Actions.

**⚠️ AVISO IMPORTANTE:**
- Esta ação é **IRREVERSÍVEL**
- Todos os dados serão **PERDIDOS**
- Use apenas para **limpar ambiente de desenvolvimento**
- **NÃO use em produção**

---

## 📋 Ordem de Destruição Recomendada

Para evitar erros de dependências, siga esta ordem:

```
1. 🔸 Application        (app + kubernetes)
2. 🔸 Gateway & Lambda   (api gateway + lambdas)
3. 🔸 Database          (RDS PostgreSQL)
4. 🔸 Core              (EKS + VPC + S3/DynamoDB)
```

---

## 🎯 Destruição Passo a Passo

### **1️⃣ Destruir Application**

**Repositório:** `tech-challenge-application`

1. Acesse: https://github.com/group-240/tech-challenge-application/actions
2. Selecione workflow: **"🧹 Destroy Application - DANGER ZONE"**
3. Clique em **"Run workflow"**
4. Preencha os campos:
   ```
   Confirmation: DESTROY-APPLICATION
   Force: ✅ (recomendado)
   Delete ECR images: ✅ (para limpar imagens Docker)
   ```
5. Clique em **"Run workflow"**

**O que será deletado:**
- ✅ Deployment Kubernetes
- ✅ Services e LoadBalancer
- ✅ Namespace `tech-challenge`
- ✅ Recursos Terraform
- ✅ Imagens ECR (se marcado)
- ✅ Load Balancers órfãos
- ✅ Target Groups
- ✅ CloudWatch Logs

---

### **2️⃣ Destruir Gateway & Lambda**

**Repositório:** `tech-challenge-infra-gateway-lambda`

1. Acesse: https://github.com/group-240/tech-challenge-infra-gateway-lambda/actions
2. Selecione workflow: **"🧹 Destroy Gateway & Lambda - DANGER ZONE"**
3. Clique em **"Run workflow"**
4. Preencha os campos:
   ```
   Confirmation: DESTROY-GATEWAY
   Force: ✅ (recomendado)
   ```
5. Clique em **"Run workflow"**

**O que será deletado:**
- ✅ API Gateway (REST e HTTP)
- ✅ Lambda Functions
- ✅ CloudWatch Log Groups
- ✅ IAM Roles (se force=true)
- ✅ Recursos Terraform

---

### **3️⃣ Destruir Database**

**Repositório:** `tech-challenge-infra-database`

1. Acesse: https://github.com/group-240/tech-challenge-infra-database/actions
2. Selecione workflow: **"🧹 Destroy Database - DANGER ZONE"**
3. Clique em **"Run workflow"**
4. Preencha os campos:
   ```
   Confirmation: DESTROY-DATABASE
   Force: ✅ (recomendado)
   Delete snapshots: ⚠️ CUIDADO! (só marque se quiser DELETAR backups)
   ```
5. Clique em **"Run workflow"**

**O que será deletado:**
- ✅ RDS PostgreSQL Instance
- ✅ DB Subnet Groups
- ✅ Security Groups
- ✅ RDS Snapshots (se marcado)
- ✅ Recursos Terraform

**💾 Backup Automático:**
O workflow cria um snapshot final antes de destruir (se a instância existir).

---

### **4️⃣ Destruir Core (ÚLTIMO)**

**Repositório:** `tech-challenge-infra-core`

1. Acesse: https://github.com/group-240/tech-challenge-infra-core/actions
2. Selecione workflow: **"🧹 Destroy Infrastructure - DANGER ZONE"**
3. Clique em **"Run workflow"**
4. Preencha os campos:
   ```
   Confirmation: DESTROY
   Force: ✅ (recomendado)
   ```
5. Clique em **"Run workflow"**

**O que será deletado:**
- ✅ EKS Cluster
- ✅ VPC e Subnets
- ✅ NAT Gateway
- ✅ Internet Gateway
- ✅ Security Groups
- ✅ AWS Load Balancer Controller
- ✅ S3 Bucket (terraform state)
- ✅ DynamoDB Table (terraform lock)
- ✅ Recursos Terraform

---

## 🔍 Verificação Pós-Destruição

Após executar todos os workflows, verifique se há recursos órfãos:

### **Via AWS CLI:**

```bash
# VPCs
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=tech-challenge" --query 'Vpcs[*].VpcId'

# EKS Clusters
aws eks list-clusters --query 'clusters[?contains(@, `tech-challenge`)]'

# RDS Instances
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `tech-challenge`)].DBInstanceIdentifier'

# Lambda Functions
aws lambda list-functions --query "Functions[?contains(FunctionName, 'tech-challenge')].FunctionName"

# Load Balancers
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'tech-challenge')].[LoadBalancerName,LoadBalancerArn]"

# S3 Buckets
aws s3 ls | grep tech-challenge

# DynamoDB Tables
aws dynamodb list-tables --query "TableNames[?contains(@, 'tech-challenge')]"
```

**Resultado esperado:** Todos devem retornar vazio (nenhum recurso encontrado)

---

## 🆘 Troubleshooting

### **Erro: "Resource in use" ou "Timeout"**

**Solução:** Execute novamente com `force: true` marcado.

### **Erro: "Terraform state lock"**

**Solução 1:** Aguarde 5 minutos e tente novamente.

**Solução 2 (force):**
```bash
# Deletar lock manualmente no DynamoDB
aws dynamodb delete-item \
  --table-name tech-challenge-terraform-lock-533267363894-10 \
  --key '{"LockID":{"S":"<repositorio>/terraform.tfstate-md5"}}'
```

### **Erro: "Cannot delete VPC with dependencies"**

**Solução:** Execute destroy do Core novamente com `force: true`.

O workflow tentará limpar:
- Load Balancers
- TargetGroupBindings
- Security Groups
- Network Interfaces

### **S3 Bucket não deleta (contém objetos)**

**Solução:** O workflow do Core automaticamente:
1. Esvazia todos os buckets S3
2. Depois tenta deletar

Se falhar, execute manualmente:
```bash
aws s3 rm s3://tech-challenge-tfstate-533267363894-10 --recursive
aws s3 rb s3://tech-challenge-tfstate-533267363894-10 --force
```

---

## 📊 Opções dos Workflows

### **Force Mode** (`force: true`)

- ✅ Continua mesmo com erros
- ✅ Tenta deletar recursos órfãos manualmente
- ✅ Usa `-auto-approve` no Terraform
- ⚠️ Pode deixar alguns recursos órfãos

### **Standard Mode** (`force: false`)

- ✅ Para na primeira falha
- ✅ Mais seguro
- ❌ Pode precisar de múltiplas execuções

**Recomendação:** Use `force: true` para ambiente de dev.

---

## 🔒 Segurança

### **Confirmações Obrigatórias:**

Cada workflow exige uma palavra específica:

| Repositório | Palavra de Confirmação |
|-------------|----------------------|
| Application | `DESTROY-APPLICATION` |
| Gateway     | `DESTROY-GATEWAY` |
| Database    | `DESTROY-DATABASE` |
| Core        | `DESTROY` |

**Isso previne destruição acidental!**

---

## 💡 Cenários de Uso

### **Cenário 1: Limpar tudo e recomeçar**

```
Execute todos os 4 workflows na ordem (1→2→3→4)
```

### **Cenário 2: Apenas recriar aplicação**

```
Execute apenas workflow 1 (Application)
```

### **Cenário 3: Recriar banco de dados**

```
Execute workflows 1 e 3 (Application + Database)
```

### **Cenário 4: Ambiente completamente novo**

```
1. Execute todos os 4 workflows de destruição (1→2→3→4)
2. Aguarde 5-10 minutos
3. Execute bootstrap novamente
4. Execute deploys na ordem correta
```

---

## 📝 Logs e Auditoria

Todos os workflows geram:

- ✅ Logs detalhados de cada etapa
- ✅ Lista de recursos antes da destruição
- ✅ Verificação pós-destruição
- ✅ Summary com timestamp e configurações

Acesse os logs em:
```
GitHub → Actions → Workflow específico → Run details
```

---

## ⏱️ Tempo Estimado

| Workflow | Tempo Médio | Com Force |
|----------|-------------|-----------|
| Application | 3-5 min | 2-3 min |
| Gateway | 2-3 min | 1-2 min |
| Database | 5-10 min | 3-5 min |
| Core | 10-15 min | 5-10 min |
| **TOTAL** | **20-33 min** | **11-20 min** |

---

## 🎯 Checklist de Destruição Total

Use esta checklist para garantir que tudo foi deletado:

- [ ] **Application destroyed**
  - [ ] Namespace `tech-challenge` removido
  - [ ] LoadBalancers deletados
  - [ ] ECR images removidas (opcional)

- [ ] **Gateway destroyed**
  - [ ] API Gateway removido
  - [ ] Lambda functions deletadas
  - [ ] CloudWatch logs removidos

- [ ] **Database destroyed**
  - [ ] RDS instance removida
  - [ ] Snapshots deletados (opcional)
  - [ ] Security groups removidos

- [ ] **Core destroyed**
  - [ ] EKS cluster removido
  - [ ] VPC e subnets removidas
  - [ ] S3 bucket deletado
  - [ ] DynamoDB table deletada

- [ ] **Verificação AWS CLI executada**
  - [ ] Nenhum recurso órfão encontrado

- [ ] **Confirmação final**
  - [ ] Todos os workflows executados com sucesso
  - [ ] Nenhum erro bloqueante
  - [ ] Ambiente AWS limpo

---

## 🚀 Próximos Passos (Após Destruição)

Se você destruiu tudo e quer recriar:

1. **Aguarde 5-10 minutos** (propagação DNS, etc)

2. **Execute bootstrap:**
   ```bash
   cd tech-challenge-infra-core/bootstrap
   terraform init
   terraform apply
   ```

3. **Execute deploys na ordem:**
   - Core → Database → Application → Gateway

4. **Verifique deployment:**
   ```bash
   kubectl get pods -n tech-challenge
   kubectl get svc -n tech-challenge
   ```

---

**Última atualização:** 06/10/2025  
**Versão:** 1.0  
**Autor:** Tech Challenge Team

---

## 📞 Suporte

Se encontrar problemas:

1. ✅ Verifique os logs do workflow
2. ✅ Execute com `force: true`
3. ✅ Consulte a seção de Troubleshooting
4. ✅ Execute verificação AWS CLI
5. ✅ Delete recursos manualmente se necessário

**Comandos úteis:** Veja seção "Verificação Pós-Destruição"
