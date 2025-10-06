# Integração Backend S3 - Outros Repositórios

## Configuração Atual

O backend S3 e DynamoDB são criados pelo `tech-challenge-infra-core/bootstrap`:

- Bucket S3: `tech-challenge-tfstate-533267363894-10`
- DynamoDB: `tech-challenge-terraform-lock-533267363894-10`

## Como Integrar Cada Repositório

### tech-challenge-infra-database

Crie ou atualize o arquivo `backend.tf`:

```terraform
terraform {
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "database/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
  required_version = ">= 1.5.0"
}
```

### tech-challenge-infra-gateway-lambda

Crie ou atualize o arquivo `backend.tf`:

```terraform
terraform {
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "gateway/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
  required_version = ">= 1.5.0"
}
```

### tech-challenge-application/terraform

Crie ou atualize o arquivo `backend.tf`:

```terraform
terraform {
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "application/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
  required_version = ">= 1.5.0"
}
```

## Aplicar Configuração

Após criar/atualizar o `backend.tf`:

```bash
cd <repositório>
terraform init -reconfigure
terraform plan
terraform apply
```

## Workflows (GitHub Actions)

Adicione um step antes do `terraform init`:

```yaml
- name: Terraform Init
  run: terraform init
```

Não precisa gerar backend dinamicamente nos outros repositórios porque o `backend.tf` é fixo.

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
