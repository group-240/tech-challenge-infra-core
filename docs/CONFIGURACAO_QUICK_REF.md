# 🎯 Estrutura Centralizada - Quick Reference

## 📁 Estrutura de Arquivos (Organizada)

```
tech-challenge-infra-core/
│
├── 🎯 lab-config.tf              # LOCALS: Configuração central (UM ponto de mudança)
├── 📝 variables.tf                # VARIABLES: Todas com defaults (sem .tfvars)
├── 📤 outputs.tf                  # OUTPUTS: TODOS os outputs aqui
├── 🏗️ main.tf                     # RESOURCES: Infraestrutura
│
└── bootstrap/
    ├── 🚀 main.tf                 # Cria S3/DynamoDB
    ├── 📝 variables.tf            # Variables com defaults (sync com ../lab-config.tf)
    └── 📤 outputs.tf              # Outputs do bootstrap
```

---

## ⚙️ lab-config.tf (locals)

```terraform
locals {
  # 🎯 ALTERE APENAS AQUI
  aws_account_suffix = "533267363894-10"
  
  # ✅ Gerado automaticamente
  s3_bucket_name      = "tech-challenge-tfstate-${local.aws_account_suffix}"
  dynamodb_table_name = "tech-challenge-terraform-lock-${local.aws_account_suffix}"
  
  # 🏷️ Tags comuns
  common_tags = { ... }
}

# Data sources
data "aws_iam_role" "lab_role" { ... }
data "aws_caller_identity" "current" { ... }

# ❌ SEM OUTPUTS AQUI - vão para outputs.tf
```

---

## 📝 variables.tf (com defaults)

```terraform
variable "project_name" {
  default = "tech-challenge"
}

variable "environment" {
  default = "dev"
}

variable "owner" {
  default = "student"
}

variable "node_instance_type" {
  default = "t3.small"
}

# ✅ SEM NECESSIDADE DE terraform.tfvars
```

---

## 📤 outputs.tf (TODOS aqui)

```terraform
# VPC Outputs
output "vpc_id" { ... }

# EKS Outputs
output "eks_cluster_name" { ... }

# Cognito Outputs
output "cognito_user_pool_id" { ... }

# 🆕 Account Validation (movido de lab-config.tf)
output "account_validation" { ... }

# 🆕 Backend Config (para outros repos)
output "backend_config" { ... }

# ✅ TODOS OS OUTPUTS EM UM SÓ LUGAR
```

---

## 🏗️ main.tf (recursos)

```terraform
terraform {
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
  }
}

provider "aws" {
  region = local.aws_region  # de lab-config.tf
}

# Tags do módulo
locals {
  module_tags = merge(local.common_tags, {
    Component = "infrastructure-core"
  })
}

# Recursos usam:
# - local.aws_region
# - local.module_tags
# - var.project_name
```

---

## 🚀 bootstrap/variables.tf

```terraform
# 🔄 SINCRONIZADO com ../lab-config.tf

variable "aws_account_suffix" {
  default = "533267363894-10"  # 🎯 MESMO VALOR
}

variable "aws_account_id" {
  default = "533267363894"
}

variable "aws_region" {
  default = "us-east-1"
}

# + project_name, environment, owner
```

---

## 🚀 bootstrap/main.tf

```terraform
terraform {
  # ❌ SEM BACKEND (usa local)
}

provider "aws" {
  region = var.aws_region  # de variables.tf
}

locals {
  bucket_name = "tech-challenge-tfstate-${var.aws_account_suffix}"
  table_name  = "tech-challenge-terraform-lock-${var.aws_account_suffix}"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name
}

resource "aws_dynamodb_table" "terraform_lock" {
  name = local.table_name
}
```

---

## ✅ Benefícios

| Aspecto | Antes | Agora |
|---------|-------|-------|
| **Configuração** | ❌ Hardcoded em 10+ lugares | ✅ `aws_account_suffix` em 1 lugar |
| **Variables** | ❌ Precisa terraform.tfvars | ✅ Defaults em variables.tf |
| **Outputs** | ❌ Espalhados (lab-config.tf + outputs.tf) | ✅ TODOS em outputs.tf |
| **Bootstrap** | ❌ Desconectado | ✅ Sincronizado com ../lab-config.tf |
| **Manutenção** | ❌ Precisa editar N arquivos | ✅ Edita 2 arquivos (lab-config.tf + bootstrap/variables.tf) |

---

## 🔄 Como Alterar o Account Suffix

### 1️⃣ Edite `lab-config.tf`:
```terraform
aws_account_suffix = "533267363894-20"  # NOVO
```

### 2️⃣ Edite `bootstrap/variables.tf`:
```terraform
variable "aws_account_suffix" {
  default = "533267363894-20"  # NOVO
}
```

### 3️⃣ Edite backend do `main.tf`:
```terraform
backend "s3" {
  bucket         = "tech-challenge-tfstate-533267363894-20"
  dynamodb_table = "tech-challenge-terraform-lock-533267363894-20"
}
```

### 4️⃣ Reaplique:
```bash
cd bootstrap
terraform destroy && terraform apply

cd ..
terraform init -reconfigure
terraform apply
```

---

## 📋 Checklist

- [x] `lab-config.tf` - Apenas locals e data sources (sem outputs)
- [x] `variables.tf` - Todas com defaults
- [x] `outputs.tf` - TODOS os outputs
- [x] `bootstrap/variables.tf` - Sincronizado
- [x] `terraform.tfvars` - Desnecessário (pode deletar)
- [x] Ponto único de mudança: `aws_account_suffix`

---

## 📚 Documentação Completa

Para detalhes completos: [CONFIGURACAO_CENTRALIZADA.md](./CONFIGURACAO_CENTRALIZADA.md)

---

**Última atualização:** 06/10/2025  
**Commit:** 1e628b8
