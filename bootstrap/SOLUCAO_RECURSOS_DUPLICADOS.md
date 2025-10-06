# 🚨 Problema: Recursos S3/DynamoDB Duplicados

## 📋 Situação Atual

O Terraform está tentando criar recursos que já existem com nomes diferentes:

### ❌ Recursos Antigos (já criados):
- Bucket S3: `tech-challenge-tfstate-533267363894-4`
- DynamoDB: `tech-challenge-terraform-lock-533267363894`

### ✅ Recursos Novos (esperados pelo backend):
- Bucket S3: `tech-challenge-tfstate-533267363894-10`
- DynamoDB: `tech-challenge-terraform-lock-533267363894-10`

## 🔍 Causa do Problema

O arquivo `bootstrap/main.tf` estava criando os recursos com nomes inconsistentes em relação ao backend configurado no `main.tf` principal.

**Correção aplicada:** Commit `43bcd5f` padronizou o bootstrap para usar sufixo `-10`.

---

## 🛠️ Soluções

Você tem **2 opções** para resolver:

### **Opção 1: Destruir e Recriar (RECOMENDADO)** ⭐

**Vantagens:**
- ✅ Nomes consistentes e padronizados
- ✅ Sem recursos "órfãos" na AWS
- ✅ Alinhado com a documentação

**Passos:**

```bash
cd c:/Users/User/repositorios/tech-challenge-infra-core/bootstrap
bash fix-resources.sh
# Escolha opção 1
```

O script irá:
1. Deletar bucket `tech-challenge-tfstate-533267363894-4`
2. Deletar tabela `tech-challenge-terraform-lock-533267363894`
3. Orientar sobre criação dos novos recursos

Depois execute:
```bash
terraform init -reconfigure
terraform plan
terraform apply
```

---

### **Opção 2: Usar Recursos Existentes**

**Vantagens:**
- ✅ Não perde dados existentes
- ✅ Mais rápido

**Desvantagens:**
- ❌ Nomes não seguem o padrão `-10`
- ❌ Inconsistência com documentação

**Passos:**

1. Reverter o `bootstrap/main.tf` para usar os nomes antigos:

```bash
cd c:/Users/User/repositorios/tech-challenge-infra-core
git revert HEAD  # Reverte o commit 43bcd5f
```

2. Atualizar **TODOS** os backends nos 4 repositórios:

**tech-challenge-infra-core/main.tf:**
```terraform
backend "s3" {
  bucket         = "tech-challenge-tfstate-533267363894-4"
  dynamodb_table = "tech-challenge-terraform-lock-533267363894"
}
```

**tech-challenge-infra-database/main.tf:**
```terraform
backend "s3" {
  bucket         = "tech-challenge-tfstate-533267363894-4"
  dynamodb_table = "tech-challenge-terraform-lock-533267363894"
}
```

**tech-challenge-infra-gateway-lambda/provider.tf:**
```terraform
backend "s3" {
  bucket         = "tech-challenge-tfstate-533267363894-4"
  dynamodb_table = "tech-challenge-terraform-lock-533267363894"
}
```

**tech-challenge-application/terraform/main.tf:**
```terraform
backend "s3" {
  bucket         = "tech-challenge-tfstate-533267363894-4"
  dynamodb_table = "tech-challenge-terraform-lock-533267363894"
}
```

---

## 🎯 Recomendação

**Use a Opção 1** - É melhor ter nomes consistentes desde o início. Os recursos S3/DynamoDB do bootstrap são vazios (sem state importante ainda), então é seguro deletar e recriar.

---

## 📝 Checklist

Após escolher a solução:

- [ ] Recursos S3/DynamoDB consistentes
- [ ] Bootstrap funciona sem erros
- [ ] `terraform init` funciona em todos os repositórios
- [ ] `terraform plan` não mostra erros de backend
- [ ] Documentação atualizada (se necessário)

---

## 🆘 Se Precisar de Ajuda

Execute este comando para verificar os recursos existentes:

```bash
# Buckets S3
aws s3 ls | grep tech-challenge

# Tabelas DynamoDB
aws dynamodb list-tables --query "TableNames[?contains(@, 'tech-challenge')]"
```

---

**Última atualização:** 06/10/2025  
**Commit de correção:** `43bcd5f`
