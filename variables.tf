# ------------------------------------------------------------------
# Variáveis essenciais - Conta AWS 533267363894
# ------------------------------------------------------------------

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "tech-challenge"
}

# Ambiente fixo em dev - sem necessidade de variável