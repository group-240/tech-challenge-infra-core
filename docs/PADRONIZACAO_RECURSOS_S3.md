# 📦 Padronização de Recursos S3 e DynamoDB

## 🎯 Objetivo

Padronizar a nomenclatura dos recursos de **backend do Terraform** (S3 e DynamoDB) em todos os repositórios do projeto, facilitando a manutenção e evitando inconsistências.

---

## ✅ Padrão Definido

### **Nomenclatura Padrão**
```
Bucket S3:        tech-challenge-tfstate-{aws_account_suffix}
DynamoDB Table:   tech-challenge-terraform-lock-{aws_account_suffix}
```

### **Valor Atual**
```
aws_account_suffix = "533267363894-10"
```

### **Recursos Criados**
- **Bucket S3:** `tech-challenge-tfstate-533267363894-10`
- **DynamoDB Table:** `tech-challenge-terraform-lock-533267363894-10`

---

## 🔧 Implementação

### **1. tech-challenge-infra-core**

**Arquivo:** `lab-config.tf`
```terraform
locals {
  aws_account_id     = "533267363894"
  aws_account_suffix = "533267363894-10"  # Sufixo para recursos S3/DynamoDB
  aws_region         = "us-east-1"
  
  lab_role_arn = "arn:aws:iam::${local.aws_account_id}:role/LabRole"
  
  # ...
}
```

**Arquivo:** `main.tf`
```terraform
backend "s3" {
  bucket         = "tech-challenge-tfstate-533267363894-10"
  key            = "core/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
  encrypt        = true
}
```

---

### **2. tech-challenge-infra-database**

**Backend S3:**
```terraform
backend "s3" {
  bucket         = "tech-challenge-tfstate-533267363894-10"
  key            = "database/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
  encrypt        = true
}
```

**Remote State:**
```terraform
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "tech-challenge-tfstate-533267363894-10"
    key    = "core/terraform.tfstate"
    region = "us-east-1"
  }
}
```

---

### **3. tech-challenge-infra-gateway-lambda**

**Backend S3 (provider.tf):**
```terraform
backend "s3" {
  bucket         = "tech-challenge-tfstate-533267363894-10"
  key            = "gateway/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
  encrypt        = true
}
```

**Remote States (main.tf):**
```terraform
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "tech-challenge-tfstate-533267363894-10"
    key    = "core/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "application" {
  backend = "s3"
  config = {
    bucket = "tech-challenge-tfstate-533267363894-10"
    key    = "application/terraform.tfstate"
    region = "us-east-1"
  }
}
```

---

### **4. tech-challenge-application**

**Backend S3 (terraform/main.tf):**
```terraform
backend "s3" {
  bucket         = "tech-challenge-tfstate-533267363894-10"
  key            = "application/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
  encrypt        = true
}
```

**Remote States:**
```terraform
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "tech-challenge-tfstate-533267363894-10"
    key    = "core/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"
  config = {
    bucket = "tech-challenge-tfstate-533267363894-10"
    key    = "database/terraform.tfstate"
    region = "us-east-1"
  }
}
```

---

## 📊 Antes vs Depois

### **ANTES (Inconsistente)** ❌
```
infra-core:           533267363894-10  ✅
infra-database:       533267363894-4   ❌
infra-gateway-lambda: 533267363894-4   ❌
application:          533267363894-4   ❌

DynamoDB Tables:
infra-core:           533267363894-10  ✅
infra-database:       533267363894     ❌ (sem sufixo)
infra-gateway-lambda: 533267363894     ❌ (sem sufixo)
application:          533267363894     ❌ (sem sufixo)
```

### **AGORA (Padronizado)** ✅
```
Todos os repositórios:
- Bucket S3:        tech-challenge-tfstate-533267363894-10
- DynamoDB Table:   tech-challenge-terraform-lock-533267363894-10
```

---

## 🚀 Commits Realizados

| Repositório | Commit | Descrição |
|-------------|--------|-----------|
| **infra-core** | `8029ef4` | Adiciona `aws_account_suffix` em `lab-config.tf` |
| **infra-database** | `707767f` | Atualiza backend e remote state |
| **infra-gateway-lambda** | `3a6431f` | Atualiza backend e remote states |
| **application** | `47b4ebf` | Atualiza backend e remote states |

---

## 📝 Benefícios

1. **✅ Consistência Total** - Todos os repositórios usam o mesmo padrão
2. **✅ Facilita Manutenção** - Mudança futura centralizada em `lab-config.tf`
3. **✅ Evita Conflitos** - Sufixo único previne colisão de nomes
4. **✅ Documentação Clara** - Comentários explicam o padrão
5. **✅ Rastreabilidade** - Fácil identificar recursos por conta AWS

---

## 🔍 Verificação

Para verificar se está tudo correto:

```bash
# Verificar backends em todos os repositórios
grep -r "533267363894-10" */main.tf */provider.tf

# Verificar remote states
grep -r "terraform_remote_state" */main.tf

# Verificar variável centralizada
cat tech-challenge-infra-core/lab-config.tf | grep aws_account
```

**Resultado esperado:** Todos devem usar `533267363894-10`

---

## ⚠️ Importante

### **Migração do State (se necessário)**

Se você já tinha recursos criados com os nomes antigos, precisará:

1. **Criar novos recursos S3/DynamoDB** com o padrão `-10`
2. **Copiar states existentes:**
   ```bash
   # Exemplo para database
   aws s3 cp s3://tech-challenge-tfstate-533267363894-4/database/terraform.tfstate \
             s3://tech-challenge-tfstate-533267363894-10/database/terraform.tfstate
   ```
3. **Reinicializar Terraform:**
   ```bash
   cd tech-challenge-infra-database
   terraform init -reconfigure
   ```

### **Ou simplesmente:**

Se você começar do zero, os novos buckets serão criados automaticamente pelo bootstrap.

---

## 📚 Referências

- **Documentação Principal:** [MAPA_DEPENDENCIAS.md](./MAPA_DEPENDENCIAS.md)
- **Ordem de Deploy:** [ORDEM_DEPLOY.md](./ORDEM_DEPLOY.md)
- **Configurações Compartilhadas:** [CONFIGURACOES_COMPARTILHADAS.md](./CONFIGURACOES_COMPARTILHADAS.md)

---

**Última atualização:** 06/10/2025  
**Status:** ✅ Padronização completa em todos os repositórios
