# Correção do Erro de Multi-line String no backend.tf

## Problema Identificado

Durante o deploy, o workflow falhou com erro de validação Terraform:

```
Error: Invalid multi-line string
  on backend.tf line 3, in terraform:
   3:     bucket         = "tech-challenge-tfstate-533267363894-10
   4: tech-challenge-tfstate-${local.aws_account_suffix}
```

## Causa Raiz

O script `generate-backend.sh` estava usando interpolação de variáveis dentro de um heredoc (`<< EOF`), o que em algumas circunstâncias pode causar problemas com quebras de linha, especialmente quando há caracteres especiais ou quebras de linha inesperadas no valor da variável `ACCOUNT_SUFFIX`.

## Solução Aplicada

### 1. Extração mais robusta da variável

**Antes:**
```bash
ACCOUNT_SUFFIX=$(grep 'aws_account_suffix' locals.tf | grep -v '#' | sed 's/.*= "\(.*\)".*/\1/')
```

**Depois:**
```bash
ACCOUNT_SUFFIX=$(grep 'aws_account_suffix' locals.tf | grep -v '#' | head -n 1 | sed 's/.*= *"\([^"]*\)".*/\1/' | tr -d '\n\r')
```

Melhorias:
- `head -n 1`: Pega apenas a primeira ocorrência
- `sed 's/.*= *"\([^"]*\)".*/\1/'`: Regex mais precisa que não captura quebras de linha
- `tr -d '\n\r'`: Remove explicitamente quebras de linha e carriage returns

### 2. Uso de placeholders em vez de interpolação direta

**Antes:**
```bash
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "${TABLE_NAME}"
    encrypt        = true
  }
}
EOF
```

**Depois:**
```bash
cat > backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "BUCKET_NAME_PLACEHOLDER"
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "TABLE_NAME_PLACEHOLDER"
    encrypt        = true
  }
}
EOF

# Substitui os placeholders
sed -i "s|BUCKET_NAME_PLACEHOLDER|${BUCKET_NAME}|g" backend.tf
sed -i "s|TABLE_NAME_PLACEHOLDER|${TABLE_NAME}|g" backend.tf
```

Melhorias:
- Heredoc com aspas simples (`<< 'EOF'`) previne interpolação prematura
- Substituição com `sed` é mais controlada e previsível
- Usa `|` como delimitador no sed (mais seguro que `/`)

## Verificação

Todos os arquivos `backend.tf` nos 4 repositórios foram verificados e estão corretos:

✅ **tech-challenge-infra-core**: `backend.tf` OK
✅ **tech-challenge-infra-database**: `backend.tf` OK
✅ **tech-challenge-infra-gateway-lambda**: `backend.tf` OK
✅ **tech-challenge-application**: `terraform/backend.tf` OK

Todos apontam para:
- Bucket: `tech-challenge-tfstate-533267363894-10`
- DynamoDB: `tech-challenge-terraform-lock-533267363894-10`
- Keys específicas por repositório

## Commits Aplicados

### 1. Correção do Script de Geração do Backend
```
commit a0e461b
fix: corrige generate-backend.sh para evitar quebras de linha em strings
```

### 2. Correção de Referência Circular
```
commit 673c920
fix: corrige referência circular em module_tags (deve usar common_tags)
```

**Problema adicional encontrado**: `main.tf` tinha uma referência circular onde `module_tags` tentava fazer merge com ele mesmo.

**Solução**: Alterado de `merge(local.module_tags, {...})` para `merge(local.common_tags, {...})` na definição do `module_tags`.

## Próximos Passos

1. O workflow será re-executado automaticamente
2. O script agora gerará o `backend.tf` corretamente
3. O deploy deve completar sem erros de validação

## Como Testar Localmente

```bash
cd tech-challenge-infra-core
./generate-backend.sh
cat backend.tf  # Verificar se está correto
terraform validate
```

O arquivo `backend.tf` deve estar em uma única linha por valor, sem quebras:
```terraform
terraform {
  backend "s3" {
    bucket         = "tech-challenge-tfstate-533267363894-10"
    key            = "core/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-lock-533267363894-10"
    encrypt        = true
  }
}
```
