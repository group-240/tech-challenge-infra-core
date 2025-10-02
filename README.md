# Tech Challenge - Infraestrutura Core

Infraestrutura base para o Tech Challenge usando AWS EKS.

## 🏗️ Arquitetura

Este repositório cria:
- **VPC**: 10.0.0.0/16
- **2 Subnets Privadas**: Em AZs diferentes (requerido pelo EKS)
- **EKS Cluster**: Kubernetes gerenciado
- **Node Group**: 1 node t3.small (mínimo viável para EKS)

## 📋 Pré-requisitos

1. Conta AWS (533267363894)
2. GitHub Secrets configurados:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN` (se usar credenciais temporárias)

## 🚀 Deploy

### 1. Bootstrap (Primeira vez apenas)

Execute o workflow **"Bootstrap - Create S3 Backend"** manualmente no GitHub Actions.

Isso cria:
- Bucket S3 para Terraform state
- Tabela DynamoDB para state locking

### 2. Infraestrutura Principal

Após o bootstrap:
- Push para `main` → Deploy automático
- Pull Request → Plan automático com comentário

## 📦 Recursos Criados

| Recurso | Tipo | Quantidade |
|---------|------|------------|
| VPC | aws_vpc | 1 |
| Subnets Privadas | aws_subnet | 2 |
| EKS Cluster | aws_eks_cluster | 1 |
| Node Group | aws_eks_node_group | 1 node t3.small |

## 💰 Custos Estimados

- **EKS Cluster**: ~$72/mês (control plane)
- **t3.small node**: ~$15/mês (On-Demand)
- **Total**: ~$87/mês

## 🔧 Configuração

- **Região**: us-east-1 (fixo)
- **Ambiente**: dev (fixo)
- **Backend**: S3 + DynamoDB

## 📝 Outputs

Após o deploy, você terá acesso a:
- VPC ID
- Subnet IDs
- EKS Cluster Endpoint
- Security Group ID

Use esses outputs em outros repositórios.

## ⚠️ Notas Importantes

1. **t3.nano/micro NÃO funcionam** com EKS (muito pequenos para pods do sistema)
2. EKS **requer 2+ subnets** em AZs diferentes
3. Credenciais temporárias **expiram** - use IAM user permanente para CI/CD
4. Este é apenas o **core** - API Gateway e aplicações vão em outros repos