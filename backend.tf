# ==============================================================================
# BACKEND CONFIGURATION - Gerado automaticamente
# ==============================================================================
# 
# ⚠️ Para alterar o backend:
#   1. Edite aws_account_suffix em locals.tf
#   2. Execute: ./generate-backend.sh
#   3. Execute: terraform init -reconfigure
#
# ==============================================================================

terraform {
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
}
