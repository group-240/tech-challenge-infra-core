output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block da VPC"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "availability_zones" {
  description = "Availability Zones utilizadas"
  value       = [aws_subnet.private_1.availability_zone, aws_subnet.private_2.availability_zone]
}

output "eks_cluster_id" {
  description = "ID do cluster EKS"
  value       = aws_eks_cluster.main.id
}

output "eks_cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security Group do cluster EKS"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "eks_node_group_arn" {
  description = "ARN do node group EKS"
  value       = aws_eks_node_group.main.arn
}

output "eks_cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = aws_subnet.public.id
}

output "nat_gateway_id" {
  description = "ID do NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "cognito_user_pool_id" {
  description = "ID do Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "ID do Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_user_pool_arn" {
  description = "ARN do Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "cognito_user_pool_endpoint" {
  description = "Endpoint do Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

# ------------------------------------------------------------------
# NLB Outputs (para integração com API Gateway e Application)
# ------------------------------------------------------------------

output "nlb_arn" {
  description = "ARN do Network Load Balancer"
  value       = aws_lb.app.arn
}

output "nlb_dns_name" {
  description = "DNS name do Network Load Balancer"
  value       = aws_lb.app.dns_name
}

output "nlb_zone_id" {
  description = "Zone ID do Network Load Balancer"
  value       = aws_lb.app.zone_id
}

output "target_group_arn" {
  description = "ARN do Target Group para aplicação"
  value       = aws_lb_target_group.app.arn
}

# ==============================================================================
# ECR Repository Outputs
# ==============================================================================

output "ecr_repository_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Nome do repositório ECR"
  value       = aws_ecr_repository.app.name
}

# ==============================================================================
# Account & Configuration Outputs
# ==============================================================================

output "account_info" {
  description = "Informações da conta AWS"
  value = {
    account_id      = local.aws_account_id
    account_suffix  = local.aws_account_suffix
    region          = local.aws_region
    project         = var.project_name
    environment     = var.environment
    lab_role        = data.aws_iam_role.lab_role.arn
  }
}

output "account_validation" {
  description = "Validação da conta AWS (certifica que está na conta correta)"
  value = {
    expected_account = local.aws_account_id
    current_account  = data.aws_caller_identity.current.account_id
    is_valid         = local.is_correct_account
    lab_role         = local.lab_role_arn
    region           = local.aws_region
  }
}

# ==============================================================================
# Backend Configuration Outputs (para outros repositórios)
# ==============================================================================

output "backend_config" {
  description = "Configuração do backend S3 para usar em outros repositórios"
  value = {
    bucket         = local.s3_bucket_name
    dynamodb_table = local.dynamodb_table_name
    region         = local.aws_region
    encrypt        = true
  }
}