# Guia Passo a Passo - Integração dos Repositórios

## Visão Geral

Todos os repositórios usam o mesmo backend S3/DynamoDB criado pelo infra-core.

Backend compartilhado:
- S3: `tech-challenge-tfstate-533267363894-10`
- DynamoDB: `tech-challenge-terraform-lock-533267363894-10`

## Estrutura Aplicada

Cada repositório agora tem:
- `backend.tf` - Configuração do backend S3 (separado)
- `provider.tf` - Providers e remote states (separado)
- `main.tf` - Apenas resources (limpo)
- `variables.tf` - Variables
- `outputs.tf` - Outputs

## Passo a Passo por Repositório

### 1. tech-challenge-infra-database

**Arquivos criados:**

`backend.tf`:
```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
  
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "database/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
}
```

`provider.tf`:
```terraform
provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "tech-challenge-tfstate-533267363894-10"
    key    = "core/terraform.tfstate"
    region = "us-east-1"
  }
}
```

`main.tf` (limpo, sem terraform/provider blocks)

**Aplicar:**
```bash
cd tech-challenge-infra-database
git add backend.tf provider.tf main.tf
git commit -m "refactor: separa backend e provider em arquivos dedicados"
terraform init -reconfigure
terraform plan
```

### 2. tech-challenge-infra-gateway-lambda

**Arquivos criados:**

`backend.tf`:
```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
  
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "gateway/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
}
```

`main.tf` (atualizado, sem comentários excessivos)

**Aplicar:**
```bash
cd tech-challenge-infra-gateway-lambda
git add backend.tf main.tf
git commit -m "refactor: adiciona backend.tf e limpa main.tf"
terraform init -reconfigure
terraform plan
```

### 3. tech-challenge-application/terraform

**Arquivos criados:**

`backend.tf`:
```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.5.0"
  
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "application/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
}
```

`provider.tf`:
```terraform
provider "aws" {
  region = "us-east-1"
}

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

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.core.outputs.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.core.outputs.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
```

`main.tf` (limpo, sem terraform/provider blocks)

**Aplicar:**
```bash
cd tech-challenge-application/terraform
git add backend.tf provider.tf main.tf
git commit -m "refactor: separa backend e provider em arquivos dedicados"
terraform init -reconfigure
terraform plan
```

## Validação

Após aplicar em cada repositório:

```bash
aws s3 ls s3://tech-challenge-tfstate-533267363894-10/
```

Deve listar:
- core/terraform.tfstate
- database/terraform.tfstate
- application/terraform.tfstate
- gateway/terraform.tfstate

## Validar Backend

```bash
# Listar states no S3
aws s3 ls s3://tech-challenge-tfstate-533267363894-10/

# Verificar locks no DynamoDB
aws dynamodb scan --table-name tech-challenge-terraform-lock-533267363894-10
```

## Alteração de Account Suffix

Se o `aws_account_suffix` mudar em `tech-challenge-infra-core`:

1. **Atualize infra-core**:
   ```bash
   cd tech-challenge-infra-core
   # Edite locals.tf
   cd bootstrap
   terraform destroy
   terraform apply
   ```

2. **Atualize cada repositório**:
   ```terraform
   # backend.tf de cada repo
   terraform {
     backend "s3" {
       bucket = "tech-challenge-tfstate-533267363894-20"  # NOVO
       dynamodb_table = "tech-challenge-terraform-lock-533267363894-20"  # NOVO
       # ...
     }
   }
   ```

3. **Reinicialize**:
   ```bash
   terraform init -reconfigure
   ```

## Estrutura de States

```
tech-challenge-tfstate-533267363894-10/
├── core/terraform.tfstate
├── database/terraform.tfstate
├── gateway/terraform.tfstate
└── application/terraform.tfstate
```

Cada repositório tem seu próprio state isolado no mesmo bucket.

## Troubleshooting

### State não encontrado
```
Error: Failed to get existing workspaces
```

Solução: Execute bootstrap primeiro no infra-core

### Lock travado
```
Error: Error acquiring the state lock
```

Solução:
```bash
terraform force-unlock <LOCK_ID>
```

### Conflito de backend
```
Error: Backend configuration changed
```

Solução:
```bash
terraform init -reconfigure
```

## Dependências

```
infra-core/bootstrap  (cria S3/DynamoDB)
        ↓
    infra-core        (usa backend)
        ↓
  infra-database     (usa backend)
        ↓
   application       (usa backend + outputs de database)
        ↓
infra-gateway-lambda (usa backend + outputs de application)
```

Execute nesta ordem para garantir que os outputs estejam disponíveis.
