# 🧹 Workflows de Destruição - Quick Reference

## 🚀 Acesso Rápido

| Repositório | Workflow | Link Direto |
|-------------|----------|-------------|
| 🔸 **Application** | Destroy Application | [🔗 Executar](https://github.com/group-240/tech-challenge-application/actions/workflows/destroy.yml) |
| 🔸 **Gateway** | Destroy Gateway & Lambda | [🔗 Executar](https://github.com/group-240/tech-challenge-infra-gateway-lambda/actions/workflows/destroy.yml) |
| 🔸 **Database** | Destroy Database | [🔗 Executar](https://github.com/group-240/tech-challenge-infra-database/actions/workflows/destroy.yml) |
| 🔸 **Core** | Destroy Infrastructure | [🔗 Executar](https://github.com/group-240/tech-challenge-infra-core/actions/workflows/destroy.yml) |

---

## ⚡ Quick Start

### **Destruir TUDO (ordem recomendada):**

1. **Application** → Digite: `DESTROY-APPLICATION` + Force: ✅
2. **Gateway** → Digite: `DESTROY-GATEWAY` + Force: ✅
3. **Database** → Digite: `DESTROY-DATABASE` + Force: ✅
4. **Core** → Digite: `DESTROY` + Force: ✅

**Tempo total:** ~15-20 minutos

---

## 📋 Confirmações Necessárias

| Repositório | Palavra de Confirmação |
|-------------|----------------------|
| Application | `DESTROY-APPLICATION` |
| Gateway     | `DESTROY-GATEWAY` |
| Database    | `DESTROY-DATABASE` |
| Core        | `DESTROY` |

---

## ⚙️ Opções Disponíveis

### **Todos os workflows:**
- `confirmation` (obrigatório) - Palavra de confirmação
- `force` (recomendado: ✅) - Continua mesmo com erros

### **Database:**
- `delete_snapshots` (⚠️ cuidado) - Deleta backups RDS

### **Application:**
- `delete_ecr_images` (opcional: ✅) - Remove imagens Docker

---

## 🔍 Verificação Rápida

Após destruir tudo, execute:

```bash
# Verificar VPCs
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=tech-challenge"

# Verificar EKS
aws eks list-clusters --query 'clusters[?contains(@, `tech-challenge`)]'

# Verificar RDS
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `tech-challenge`)]'

# Verificar S3
aws s3 ls | grep tech-challenge

# Verificar DynamoDB
aws dynamodb list-tables --query "TableNames[?contains(@, 'tech-challenge')]"
```

**Resultado esperado:** Todos devem retornar vazio ✅

---

## 📚 Documentação Completa

Para instruções detalhadas, consulte:
- [GUIA_DESTRUICAO_TOTAL.md](./GUIA_DESTRUICAO_TOTAL.md)

---

## ⚠️ ATENÇÃO

- ❌ **Irreversível** - Todos os dados serão perdidos
- ❌ **Use apenas em DEV** - Não use em produção
- ✅ **Force Mode recomendado** - Para ambiente de desenvolvimento
- 💾 **Database** - Cria snapshot automático antes de destruir

---

**Última atualização:** 06/10/2025
