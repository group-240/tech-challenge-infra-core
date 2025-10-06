# ==============================================================================
# VARIÁVEIS COM DEFAULTS - Facilita manutenção (sem terraform.tfvars)
# ==============================================================================

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "tech-challenge"
}

variable "environment" {
  description = "Ambiente (fixo em dev para estudo)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Responsável pelo projeto"
  type        = string
  default     = "student"
}

# ==============================================================================
# EKS Node Group Configuration
# ==============================================================================

variable "node_instance_type" {
  description = "Tipo de instância para nodes EKS"
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "Número desejado de nodes"
  type        = number
  default     = 1
}

variable "node_min_size" {
  description = "Número mínimo de nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Número máximo de nodes"
  type        = number
  default     = 2
}