# 🗑️ Como Destruir e Recriar a Infraestrutura

## 🎯 Opções de Destruição

Você tem 2 workflows para destruir recursos:

### 1️⃣ **Destroy Infrastructure** (Infraestrutura Principal)
Destrói:
- ✅ EKS Cluster
- ✅ Node Group  
- ✅ VPC e Subnets

**Mantém**:
- ❌ Bucket S3 (backend)
- ❌ DynamoDB (lock)

### 2️⃣ **Destroy Bootstrap** (Backend)
Destrói:
- ✅ Bucket S3
- ✅ DynamoDB Table

---

## 🚀 Passo a Passo: Destruir e Recriar do Zero

### **Cenário: Você quer destruir TUDO e recriar**

#### **Passo 1: Destruir Infraestrutura Principal**

1. Vá para: `https://github.com/TheMyFish/tech-challenge-infra-core/actions`
2. Clique em **"Destroy Infrastructure"** (menu lateral esquerdo)
3. Clique em **"Run workflow"**
4. Digite `DESTROY` no campo de confirmação
5. Clique em **"Run workflow"** (verde)
6. ⏱️ Aguarde ~10-15 minutos

#### **Passo 2: Destruir Backend (Opcional)**

⚠️ **Só faça isso se quiser começar COMPLETAMENTE do zero!**

1. No GitHub Actions, clique em **"Destroy Bootstrap (S3 + DynamoDB)"**
2. Clique em **"Run workflow"**
3. Digite `DESTROY-BACKEND` no campo de confirmação
4. Clique em **"Run workflow"**
5. ⏱️ Aguarde ~2-3 minutos

#### **Passo 3: Recriar do Zero**

1. Execute **"Bootstrap - Create S3 Backend"** (se destruiu backend)
2. Aguarde completar
3. Execute **"Infrastructure Core CI/CD"** ou faça push na `main`
4. ⏱️ Aguarde ~20 minutos

---

## 🎮 Métodos de Destruição

### **Método 1: Workflow Manual (Recomendado)** ⭐

**Vantagens:**
- ✅ Interface gráfica
- ✅ Confirmação obrigatória
- ✅ Logs completos
- ✅ Seguro

**Como usar:**
```
GitHub → Actions → Destroy Infrastructure → Run workflow
```

### **Método 2: Terraform Local**

**Pré-requisitos:**
- Terraform instalado localmente
- Credenciais AWS configuradas

**Comandos:**
```bash
# Destruir infraestrutura
cd /caminho/do/repo
terraform init
terraform destroy

# Destruir backend (se necessário)
cd bootstrap
terraform init
terraform destroy
```

### **Método 3: AWS Console (Manual)**

**Último recurso** se Terraform falhar:

1. **EKS**:
   - Console → EKS → Clusters
   - Delete Node Group primeiro
   - Depois delete Cluster

2. **VPC**:
   - Console → VPC
   - Delete subnets, VPC

3. **S3/DynamoDB**:
   - Console → S3 → Delete bucket
   - Console → DynamoDB → Delete table

---

## ⚠️ Cuidados Importantes

### **Antes de Destruir:**

1. **Backup do State**
   - O state fica no S3
   - Se destruir o S3, perde o histórico

2. **Verificar Dependências**
   - Se tem apps rodando no EKS, eles serão perdidos
   - Faça backup se necessário

3. **Custo**
   - Destruir para economicamente quando não estiver usando
   - EKS cobra $72/mês mesmo parado

### **Se Algo Der Errado:**

1. **Node Group não deleta**
   ```bash
   # No console AWS, force delete
   EKS → Node Groups → Force Delete
   ```

2. **VPC não deleta**
   ```bash
   # Verifique ENIs (Elastic Network Interfaces)
   # Aguarde alguns minutos e tente novamente
   ```

3. **State corrompido**
   ```bash
   # Download do backup no S3
   # Restaure manualmente
   ```

---

## 🔄 Casos de Uso Comuns

### **Caso 1: Economizar dinheiro à noite**
```
17:00 → Run "Destroy Infrastructure"
09:00 → Run "Infrastructure Core CI/CD"
```
💰 Economia: ~50% do custo mensal

### **Caso 2: Erro no deploy, começar do zero**
```
1. Run "Destroy Infrastructure"
2. Aguardar completar
3. Push novo código ou Run workflow
```

### **Caso 3: Mudar configuração drasticamente**
```
1. Run "Destroy Infrastructure"  
2. Run "Destroy Bootstrap" (se mudar backend)
3. Atualizar código
4. Run "Bootstrap" (se destruiu backend)
5. Push para deploy
```

### **Caso 4: Projeto encerrado**
```
1. Run "Destroy Infrastructure"
2. Run "Destroy Bootstrap"
3. Delete o repositório (opcional)
```
💰 Custo zero após isso

---

## 📊 Tempo de Execução

| Ação | Tempo Estimado |
|------|----------------|
| Destroy Infrastructure | 10-15 minutos |
| Destroy Bootstrap | 2-3 minutos |
| Bootstrap | 2-3 minutos |
| Deploy Completo | 20-25 minutos |

---

## 🎯 Atalhos Rápidos

### Destruir e Recriar (mantendo backend)
```bash
1. GitHub Actions → "Destroy Infrastructure" → "DESTROY"
2. Aguardar ~15 min
3. GitHub Actions → "Infrastructure Core CI/CD" → Run workflow
4. Aguardar ~20 min
```

### Destruir TUDO e começar do zero
```bash
1. "Destroy Infrastructure" → "DESTROY"
2. "Destroy Bootstrap" → "DESTROY-BACKEND"  
3. "Bootstrap" → Run workflow
4. "Infrastructure Core CI/CD" → Run workflow
```

---

## 💡 Dicas

1. **Sempre destrua primeiro a infraestrutura, depois o backend**
2. **Nunca destrua o backend se ainda tem infraestrutura rodando**
3. **Faça backup do state antes de destruir backend**
4. **Use destroy para economizar quando não estiver usando**
5. **Teste em ambiente de dev antes de prod**

---

## 🆘 Comandos de Emergência

### Se tudo der errado e precisar limpar manualmente:

```bash
# Listar todos os recursos
aws eks list-clusters --region us-east-1
aws ec2 describe-vpcs --region us-east-1
aws s3 ls | grep tech-challenge

# Deletar manualmente
aws eks delete-nodegroup --cluster-name tech-challenge-eks --nodegroup-name tech-challenge-nodes
aws eks delete-cluster --name tech-challenge-eks
aws ec2 delete-vpc --vpc-id vpc-xxxxx
aws s3 rb s3://tech-challenge-tfstate-533267363894 --force
aws dynamodb delete-table --table-name tech-challenge-terraform-lock-533267363894
```

---

**Agora você tem controle total para destruir e recriar quando quiser!** 🎉
