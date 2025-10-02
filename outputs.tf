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

output "account_info" {
  description = "Informações da conta AWS"
  value = {
    account_id  = local.aws_account_id
    region      = local.aws_region
    project     = var.project_name
    environment = "dev"
    lab_role    = data.aws_iam_role.lab_role.arn
  }
}