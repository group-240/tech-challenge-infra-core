# 🔧 Correção: Kubernetes 1.33 com Amazon Linux 2023

## ❌ Problema Encontrado

```
Error: Unsupported Kubernetes minor version update from 1.33 to 1.31
```

## 📖 Explicação

O EKS **não permite downgrade de versão**. O cluster já foi criado com Kubernetes 1.33, então não é possível voltar para 1.31.

### Regra do Kubernetes:
- ✅ Upgrade: 1.31 → 1.32 → 1.33 (permitido)
- ❌ Downgrade: 1.33 → 1.31 (proibido)

## ✅ Solução Aplicada

Atualizei o código para usar:
- **Kubernetes**: 1.33 (versão atual do cluster)
- **AMI Type**: `AL2023_x86_64_STANDARD` (Amazon Linux 2023)

### Mudanças:

```hcl
# ANTES
version = "1.31"
ami_type = "AL2_x86_64"  # Amazon Linux 2 (não suportado em K8s 1.33+)

# AGORA
version = "1.33"
ami_type = "AL2023_x86_64_STANDARD"  # Amazon Linux 2023 (requerido)
```

## 🆚 Diferenças AL2 vs AL2023

| Feature | Amazon Linux 2 (AL2) | Amazon Linux 2023 (AL2023) |
|---------|---------------------|---------------------------|
| Kernel | 5.10 | 6.1+ |
| Suporte K8s | até 1.32 | 1.33+ |
| Suporte AWS | até 2025 | até 2028 |
| Performance | Base | Melhor |
| Segurança | Boa | Melhor |

## 💰 Impacto no Custo

**Nenhum!** AL2023 tem o mesmo custo que AL2.

## ⚠️ Alternativas se Precisar de AL2

Se você **realmente** precisar de AL2 (versão antiga), teria que:

1. **Destruir o cluster atual**
   ```bash
   terraform destroy
   ```

2. **Fixar versão antiga no código**
   ```hcl
   version = "1.31"
   ami_type = "AL2_x86_64"
   ```

3. **Recriar do zero**
   ```bash
   terraform apply
   ```

**Mas não recomendo!** AL2023 é melhor e mais moderno.

## 🚀 Próximos Passos

1. ✅ Código já está corrigido
2. 🔄 Execute o workflow novamente
3. ⏱️ Aguarde a criação do node group (~5-10 minutos)

**Agora deve funcionar!** 🎉
