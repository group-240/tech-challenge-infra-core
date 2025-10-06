# Tech Challenge - Infraestrutura Core

Infraestrutura base para o Tech Challenge usando AWS EKS.

## Arquitetura

Este repositório cria:
- VPC: 10.0.0.0/16
- 2 Subnets Privadas (AZs diferentes)
- EKS Cluster + Node Group
- Load Balancer Controller
- Cognito User Pool
- ECR Repository
- Network Load Balancer

## Pré-requisitos

1. Conta AWS configurada
2. GitHub Secrets:
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
   - AWS_SESSION_TOKEN

## Configuração Única

**Tudo é configurado em um único lugar**: `locals.tf`

```terraform
locals {
  aws_account_id     = "533267363894"
  aws_account_suffix = "533267363894-10"  # Mude apenas este valor
  aws_region         = "us-east-1"
}
```

Para alterar o account suffix:
1. Edite `locals.tf`
2. Execute bootstrap: `cd bootstrap && terraform apply`
3. Push para main (workflow gera backend automaticamente)

## Deploy

### 1. Bootstrap (Primeira Execução)

Cria S3 bucket e DynamoDB table:

```bash
cd bootstrap
terraform init
terraform apply
```

Ou via GitHub Actions: Workflow "Bootstrap"

### 2. Infraestrutura Principal

Automático via workflow:
- Push para main: Deploy automático
- Pull Request: Plan com comentário no PR

Local:
```bash
./generate-backend.sh  # Gera backend.tf
terraform init
terraform apply
```

## Estrutura de Arquivos

```
locals.tf              # Configuração única
data.tf                # Data sources
variables.tf           # Variables com defaults
outputs.tf             # Outputs
backend.tf             # Gerado automaticamente
main.tf                # Resources
generate-backend.sh    # Script de geração

bootstrap/
├── main.tf           # Cria S3 + DynamoDB
├── variables.tf      # Sincronizado com locals.tf
└── outputs.tf        # Exibe recursos criados

.github/workflows/
├── bootstrap.yml     # Workflow de bootstrap
├── main.yml          # Deploy automático com backend
└── destroy.yml       # Destruição completa
```

## Backend Automático

O workflow `main.yml` gera automaticamente o `backend.tf` antes do `terraform init`:

```yaml
- name: Generate Backend Configuration
  run: |
    chmod +x generate-backend.sh
    ./generate-backend.sh
```

Isso garante que o backend está sempre sincronizado com o `locals.tf`.

## Outputs

Disponíveis para outros repositórios:
- VPC: IDs, CIDRs, subnets
- EKS: Cluster, endpoint, security group
- Cognito: User Pool ARN
- NLB: DNS, ARN, Target Group
- ECR: Repository URL

## Documentação

- [Backend Automático](docs/BACKEND_AUTOMATICO.md)
- [Configuração Única](docs/CONFIGURACAO_UNICA.md)
- [Estrutura de Arquivos](docs/ESTRUTURA_ARQUIVOS.md)
- [Destruição Total](docs/GUIA_DESTRUICAO_TOTAL.md)

## Custos Estimados

- EKS Cluster: ~$72/mês
- t3.small node: ~$15/mês
- Total: ~$87/mês

## Integração com Outros Repositórios

Cada repositório usa o mesmo backend S3:

**tech-challenge-infra-database:**
```terraform
terraform {
  backend "s3" {
    bucket = "tech-challenge-tfstate-533267363894-10"
    key    = "database/terraform.tfstate"
    # ...
  }
}
```

Sincronize o `aws_account_suffix` em todos os repositórios após alteração.