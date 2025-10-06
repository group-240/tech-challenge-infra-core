# ==============================================================================
# OUTPUTS DO BOOTSTRAP
# ==============================================================================

output "s3_bucket_name" {
  description = "Nome do bucket S3 criado para o Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB para lock"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN da tabela DynamoDB"
  value       = aws_dynamodb_table.terraform_lock.arn
}

# ==============================================================================
# Backend Configuration (para copiar nos outros repositórios)
# ==============================================================================

output "backend_config" {
  description = "Configuração do backend para usar no main.tf dos outros repositórios"
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_lock.name
    encrypt        = true
  }
}