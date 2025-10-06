# Guia Completo - Tech Challenge Infrastructure

## Visão Geral

Sistema multi-repositório para deploy de aplicação Spring Boot no AWS EKS com backend Terraform compartilhado.

### Repositórios

1. **tech-challenge-infra-core**: VPC, EKS, Load Balancer, Cognito, ECR, NLB
2. **tech-challenge-infra-database**: RDS PostgreSQL
3. **tech-challenge-application**: Deploy Kubernetes da aplicação
4. **tech-challenge-infra-gateway-lambda**: API Gateway + Lambdas

### Estrutura de Backend

Todos os repositórios usam o mesmo backend S3:

```
tech-challenge-tfstate-533267363894-10/
├── core/terraform.tfstate
├── database/terraform.tfstate
├── application/terraform.tfstate
└── gateway/terraform.tfstate
```

## Passo 1: Bootstrap (Uma Vez)

Execute no **tech-challenge-infra-core**:

```bash
cd tech-challenge-infra-core/bootstrap
terraform init
terraform apply
```

Ou via GitHub Actions:
- Actions > Bootstrap > Run workflow

Isso cria:
- S3 Bucket: `tech-challenge-tfstate-533267363894-10`
- DynamoDB: `tech-challenge-terraform-lock-533267363894-10`

## Passo 2: Deploy Infra-Core

### Local

```bash
cd tech-challenge-infra-core
./generate-backend.sh
terraform init
terraform apply
```

### GitHub Actions

Push para main = deploy automático

Recursos criados:
- VPC (10.0.0.0/16)
- 2 Subnets privadas
- EKS Cluster
- Node Group (t3.small)
- Load Balancer Controller
- Cognito User Pool
- ECR Repository
- Network Load Balancer

## Passo 3: Deploy Database

```bash
cd tech-challenge-infra-database
terraform init
terraform apply
```

Ou push para main.

Recursos criados:
- RDS PostgreSQL
- Security Group
- Subnet Group

## Passo 4: Deploy Application

```bash
cd tech-challenge-application/terraform
terraform init
terraform apply
```

Ou push para main.

Recursos criados:
- Kubernetes Namespace
- ConfigMap (DATABASE_URL)
- Deployment (3 replicas)
- Service (LoadBalancer type)
- HPA (Horizontal Pod Autoscaler)

## Passo 5: Deploy Gateway

```bash
cd tech-challenge-infra-gateway-lambda
terraform init
terraform apply
```

Ou push para main.

Recursos criados:
- API Gateway REST API
- VPC Link
- Integração com NLB
- Deploy + Stage

## Estrutura de Arquivos (Cada Repositório)

### infra-core

```
backend.tf           # Backend S3 (gerado automaticamente)
provider.tf          # Provider AWS
locals.tf            # Configuração única
data.tf              # Data sources
variables.tf         # Variables
outputs.tf           # Outputs
main.tf              # Resources
generate-backend.sh  # Script gerador
```

### infra-database

```
backend.tf    # Backend S3 (fixo)
provider.tf   # Provider + remote state
variables.tf  # Variables
outputs.tf    # Outputs
main.tf       # Resources
```

### application/terraform

```
backend.tf    # Backend S3 (fixo)
provider.tf   # Providers + remote states
variables.tf  # Variables
outputs.tf    # Outputs
main.tf       # Resources Kubernetes
```

### infra-gateway-lambda

```
backend.tf    # Backend S3 (fixo)
provider.tf   # Provider + remote states
variables.tf  # Variables
outputs.tf    # Outputs
main.tf       # Resources API Gateway
```

## Configuração Única

Tudo é controlado em **infra-core/locals.tf**:

```terraform
locals {
  aws_account_id     = "533267363894"
  aws_account_suffix = "533267363894-10"
  aws_region         = "us-east-1"
}
```

### Alterar Account Suffix

1. **Edite infra-core/locals.tf**:
   ```terraform
   locals {
     aws_account_suffix = "533267363894-20"  # NOVO
   }
   ```

2. **Recrie bootstrap**:
   ```bash
   cd tech-challenge-infra-core/bootstrap
   terraform destroy
   terraform apply
   ```

3. **Atualize cada repositório**:
   
   Edite `backend.tf` em cada repo:
   ```terraform
   terraform {
     backend "s3" {
       bucket = "tech-challenge-tfstate-533267363894-20"  # NOVO
       dynamodb_table = "tech-challenge-terraform-lock-533267363894-20"  # NOVO
       # ...
     }
   }
   ```

4. **Reinicialize**:
   ```bash
   terraform init -reconfigure
   ```

## Workflows GitHub Actions

### infra-core

- **bootstrap.yml**: Cria S3/DynamoDB (manual)
- **main.yml**: Deploy automático (push para main)
- **destroy.yml**: Destruição completa (manual)

### Outros Repositórios

- **main.yml**: Deploy automático (push para main)
- **destroy.yml**: Destruição (manual)

## Dependências Entre Repositórios

```
infra-core/bootstrap  (cria backend S3)
        ↓
    infra-core        (VPC, EKS, Cognito, ECR, NLB)
        ↓
  infra-database     (RDS com VPC do core)
        ↓
   application       (Kubernetes usando database URL)
        ↓
infra-gateway-lambda (API Gateway usando NLB do core)
```

Execute nesta ordem.

## Outputs Importantes

### infra-core

- `vpc_id`
- `private_subnet_ids`
- `eks_cluster_name`
- `eks_cluster_endpoint`
- `cognito_user_pool_arn`
- `ecr_repository_url`
- `nlb_dns_name`
- `target_group_arn`

### infra-database

- `rds_endpoint`
- `database_url`

### application

- `app_url` (Load Balancer DNS)

### infra-gateway-lambda

- `api_gateway_url`

## Remote States

Cada repositório acessa outputs dos outros via remote state:

**Exemplo (database):**
```terraform
data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "tech-challenge-tfstate-533267363894-10"
    key    = "core/terraform.tfstate"
    region = "us-east-1"
  }
}

# Usar outputs
resource "aws_security_group" "rds" {
  vpc_id = data.terraform_remote_state.core.outputs.vpc_id
}
```

## Comandos Úteis

### Verificar Backend

```bash
aws s3 ls s3://tech-challenge-tfstate-533267363894-10/
aws dynamodb scan --table-name tech-challenge-terraform-lock-533267363894-10
```

### Destruir Tudo (Ordem Inversa)

```bash
# 1. Gateway
cd tech-challenge-infra-gateway-lambda
terraform destroy

# 2. Application
cd tech-challenge-application/terraform
terraform destroy

# 3. Database
cd tech-challenge-infra-database
terraform destroy

# 4. Core
cd tech-challenge-infra-core
terraform destroy

# 5. Bootstrap
cd bootstrap
terraform destroy
```

### Troubleshooting

**State lock travado:**
```bash
terraform force-unlock <LOCK_ID>
```

**Backend mudou:**
```bash
terraform init -reconfigure
```

**EKS não conecta:**
```bash
aws eks update-kubeconfig --name tech-challenge-eks --region us-east-1
kubectl get nodes
```

## Custos Estimados

- EKS Control Plane: ~$72/mês
- EC2 t3.small: ~$15/mês
- RDS db.t3.micro: ~$15/mês
- Load Balancers: ~$20/mês
- **Total**: ~$122/mês

## Recursos por Repositório

### infra-core
- VPC, Subnets, Route Tables, Internet Gateway
- EKS Cluster, Node Group
- Helm Release (AWS Load Balancer Controller)
- Cognito User Pool
- ECR Repository
- Network Load Balancer, Target Group

### infra-database
- Security Group
- DB Subnet Group
- RDS PostgreSQL Instance
- Secrets Manager Secret

### application
- Kubernetes Namespace
- ConfigMap
- Deployment (Spring Boot)
- Service (LoadBalancer)
- HorizontalPodAutoscaler

### infra-gateway-lambda
- API Gateway REST API
- Resources, Methods
- VPC Link
- Integrations
- Deployment, Stage

## Segurança

- RDS acessível apenas de dentro da VPC
- S3 com criptografia AES256
- S3 com acesso público bloqueado
- DynamoDB com billing pay-per-request
- Cognito para autenticação de usuários
- Security Groups restritivos

## Manutenção

### Atualizar Versão do Kubernetes

Edite `infra-core/main.tf`:
```terraform
resource "aws_eks_cluster" "tech_challenge" {
  version = "1.34"  # Nova versão
}
```

### Escalar Aplicação

Edite `application/terraform/main.tf`:
```terraform
resource "kubernetes_deployment" "app" {
  spec {
    replicas = 5  # Aumentar réplicas
  }
}
```

### Adicionar Novo Endpoint

1. Adicione recurso no `infra-gateway-lambda/main.tf`
2. Adicione método no API Gateway
3. Configure integração com NLB
4. Deploy via push

## Monitoramento

- CloudWatch Logs: Logs de EKS, RDS, API Gateway
- CloudWatch Metrics: CPU, memória, requisições
- EKS Control Plane Logs habilitados
- Application Insights (futuro)

## Suporte

Para problemas:
1. Verifique logs no CloudWatch
2. Execute `terraform plan` para ver mudanças
3. Valide remote states estão acessíveis
4. Confirme ordem de deploy

## Referências

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Backend S3](https://www.terraform.io/docs/language/settings/backends/s3.html)
