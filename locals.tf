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