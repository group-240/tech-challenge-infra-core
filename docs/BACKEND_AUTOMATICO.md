# Backend Terraform Automático

## Configuração Centralizada

Toda a configuração está em **um único lugar**: `locals.tf`

```terraform
locals {
  aws_account_id     = "533267363894"
  aws_account_suffix = "533267363894-10"  # Mude apenas este valor
  aws_region         = "us-east-1"
}
```

## Como Funciona

### 1. Bootstrap (Primeira Execução)

Cria os recursos S3 e DynamoDB:

```bash
cd bootstrap
terraform init
terraform apply
```

Ou via workflow:
- GitHub Actions > Bootstrap > Run workflow

### 2. Infra Principal (Automático)

O workflow `main.yml` gera automaticamente o `backend.tf`:

```yaml
- name: Generate Backend Configuration
  run: |
    chmod +x generate-backend.sh
    ./generate-backend.sh
```

### 3. Outros Repositórios

Cada repositório lê as configurações do backend:

**tech-challenge-infra-database:**
```terraform
terraform {
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "database/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
}
```

**tech-challenge-infra-gateway-lambda:**
```terraform
terraform {
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "gateway/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
}
```

**tech-challenge-application/terraform:**
```terraform
terraform {
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "application/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
}
```

## Alterando o Account Suffix

### Passo 1: Edite locals.tf

```terraform
locals {
  aws_account_suffix = "533267363894-20"  # NOVO VALOR
}
```

### Passo 2: Execute Bootstrap

```bash
cd bootstrap
terraform destroy  # Remove recursos antigos
terraform apply    # Cria com novos nomes
```

### Passo 3: Atualize Outros Repositórios

Cada repositório precisa atualizar manualmente o backend:

```terraform
terraform {
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-20"  # ATUALIZADO
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-20"  # ATUALIZADO
    # ...
  }
}
```

Depois execute:
```bash
terraform init -reconfigure
```

## Estrutura de Arquivos

```
tech-challenge-infra-core/
├── locals.tf              # Configuração única
├── backend.tf             # Gerado automaticamente
├── generate-backend.sh    # Script de geração
│
├── bootstrap/
│   ├── main.tf           # Cria S3 + DynamoDB
│   ├── variables.tf      # Sincronizado com locals.tf
│   └── outputs.tf        # Exibe recursos criados
│
└── .github/workflows/
    ├── bootstrap.yml     # Workflow de bootstrap
    └── main.yml          # Gera backend automaticamente
```

## Recursos Criados

### S3 Bucket
- Nome: `tech-challenge-tfstate-{aws_account_suffix}`
- Versionamento: Habilitado
- Criptografia: AES256
- Acesso público: Bloqueado

### DynamoDB Table
- Nome: `tech-challenge-terraform-lock-{aws_account_suffix}`
- Billing: PAY_PER_REQUEST
- Hash Key: LockID

## Workflows

### Bootstrap (Manual)
1. Executa `terraform apply` no diretório `bootstrap/`
2. Cria S3 bucket e DynamoDB table
3. Exibe os recursos criados

### Main (Automático)
1. Gera `backend.tf` via script
2. Executa `terraform init`
3. Valida configuração
4. Executa `terraform plan/apply`

## Manutenção

### Verificar Recursos
```bash
aws s3 ls | grep tech-challenge-tfstate
aws dynamodb list-tables | grep terraform-lock
```

### Sincronizar Bootstrap
Se alterar `locals.tf`, atualize `bootstrap/variables.tf`:

```terraform
variable "aws_account_suffix" {
  default = "533267363894-10"  # Mesmo valor de locals.tf
}
```

### Limpar Tudo
```bash
# 1. Destruir infraestrutura
terraform destroy

# 2. Destruir bootstrap
cd bootstrap
terraform destroy

# 3. Limpar state local
rm -rf .terraform terraform.tfstate*
```

## Dependências Entre Repositórios

```
bootstrap (cria S3/DynamoDB)
    ↓
infra-core (usa backend S3)
    ↓
infra-database (usa backend S3)
    ↓
application (usa backend S3)
    ↓
infra-gateway-lambda (usa backend S3)
```

## Troubleshooting

### Backend não encontrado
```
Error: Failed to get existing workspaces: S3 bucket does not exist
```

Solução: Execute o bootstrap primeiro

### Lock do state
```
Error: Error acquiring the state lock
```

Solução: 
```bash
terraform force-unlock <LOCK_ID>
```

### Conflito de nomes
```
Error: BucketAlreadyExists
```

Solução: Altere `aws_account_suffix` para valor único
