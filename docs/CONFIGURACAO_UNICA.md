# Configuração Única e Centralizada

## Princípio

**Um único arquivo controla tudo**: `locals.tf`

## Arquivo locals.tf

```terraform
locals {
  aws_account_id     = "533267363894"
  aws_account_suffix = "533267363894-10"
  aws_region         = "us-east-1"
  
  s3_bucket_name      = "tech-challenge-tfstate-${local.aws_account_suffix}"
  dynamodb_table_name = "tech-challenge-terraform-lock-${local.aws_account_suffix}"
  
  lab_role_arn = "arn:aws:iam::${local.aws_account_id}:role/LabRole"
  
  common_tags = {
    AccountId     = local.aws_account_id
    AccountSuffix = local.aws_account_suffix
    Region        = local.aws_region
    Lab           = "aws-learner-lab"
    Owner         = var.owner
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "terraform"
  }
  
  is_correct_account = data.aws_caller_identity.current.account_id == local.aws_account_id
}
```

## Como Usar

### Alterar Account Suffix

```terraform
locals {
  aws_account_suffix = "533267363894-20"  # NOVO VALOR
}
```

### Propagar Mudanças

**Automático (via workflow):**
- Push para main
- Workflow gera backend.tf automaticamente

**Manual (local):**
```bash
./generate-backend.sh
terraform init -reconfigure
```

## Estrutura de Arquivos

```
locals.tf      # Configuração única
data.tf        # Data sources
variables.tf   # Variables com defaults
outputs.tf     # Outputs
backend.tf     # Gerado automaticamente
main.tf        # Resources
```

## Sincronização com Bootstrap

O `bootstrap/variables.tf` deve ter os mesmos valores:

```terraform
variable "aws_account_id" {
  default = "533267363894"
}

variable "aws_account_suffix" {
  default = "533267363894-10"
}
```

## Sem Arquivos Desnecessários

- Sem `terraform.tfvars` (usa defaults)
- Sem configurações hardcoded
- Sem duplicação de valores

## Validação de Conta

```terraform
locals {
  is_correct_account = data.aws_caller_identity.current.account_id == local.aws_account_id
}
```

Se a conta estiver errada, o Terraform falha com erro claro.

## Benefícios

1. **Manutenção simples**: Um único lugar para editar
2. **Sem duplicação**: Valores gerados automaticamente
3. **Sem erros**: Validação automática de conta
4. **Workflows integrados**: Backend gerado automaticamente
5. **Sincronizado**: Bootstrap usa mesmos valores
