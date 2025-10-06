# Verificação do Status do Deploy EKS

## Status Atual

Você está vendo warnings **NORMAIS** durante o deploy inicial do cluster EKS:

### ⚠️ Warning 1: AWS Load Balancer Controller
```
0/1 nodes are available: 1 node(s) didn't have free ports for the requested pod ports
```

**O que significa**: O pod precisa de portas específicas no node (hostPort), mas:
- O node ainda não está completamente pronto, OU
- Outro pod está tentando usar as mesmas portas

**É normal?**: ✅ SIM - durante os primeiros 10-15 minutos do deploy

### ⚠️ Warning 2: CoreDNS
```
no nodes available to schedule pods
```

**O que significa**: Não há nodes prontos ainda para agendar os pods do CoreDNS

**É normal?**: ✅ SIM - significa que o Node Group ainda está sendo provisionado

## 🕐 Timeline Esperada do Deploy

| Tempo | Etapa | Status Esperado |
|-------|-------|-----------------|
| 0-10 min | EKS Cluster | Criando control plane |
| 10-15 min | Node Group | Provisionando instâncias SPOT |
| 15-20 min | Nodes | Registrando no cluster |
| 20-25 min | Sistema | CoreDNS iniciando |
| 25-30 min | Addons | Load Balancer Controller instalando |

## ✅ Comandos para Verificar o Progresso

### 1. Verificar Nodes
```bash
kubectl get nodes -o wide
```

**O que esperar**:
- Inicialmente: "No resources found"
- Depois: 1 node com status "NotReady"
- Finalmente: 1 node com status "Ready"

### 2. Verificar Pods do Sistema
```bash
kubectl get pods -n kube-system
```

**O que esperar**:
```
NAME                                            READY   STATUS
aws-node-xxxxx                                  2/2     Running
coredns-xxxxx                                   1/1     Running
kube-proxy-xxxxx                                1/1     Running
aws-load-balancer-controller-xxxxx              1/1     Running
```

### 3. Verificar Events
```bash
kubectl get events -n kube-system --sort-by='.lastTimestamp' | tail -20
```

**Warnings normais durante deploy**:
- FailedScheduling (nodes não prontos)
- ImagePullBackOff (temporário)
- Unhealthy (health checks falhando até pods iniciarem)

### 4. Status do Node Group (via AWS CLI)
```bash
aws eks describe-nodegroup \
  --cluster-name tech-challenge-eks \
  --nodegroup-name tech-challenge-nodes \
  --region us-east-1 \
  --query 'nodegroup.status'
```

**Estados possíveis**:
- CREATING → ACTIVE (esperado)
- DEGRADED (problema!)

### 5. Verificar Instâncias EC2 SPOT
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tech-challenge-eks-nodes" \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' \
  --output table
```

## 🔧 Quando os Warnings são um Problema Real?

Os warnings são **normais** se:
- ✅ Você está nos primeiros 15-20 minutos do deploy
- ✅ Comando `kubectl get nodes` mostra nodes em "NotReady" ou não mostra nada ainda
- ✅ Os warnings são sobre FailedScheduling ou "no nodes available"

Os warnings são **um problema** se:
- ❌ Passaram mais de 30 minutos
- ❌ Nodes aparecem como "Ready" mas pods continuam "Pending"
- ❌ Pods estão em "CrashLoopBackOff" ou "ImagePullBackOff" por muito tempo
- ❌ Node Group está em estado "DEGRADED"

## 🚨 Troubleshooting (se necessário após 30 min)

### Problema: Nodes não ficam prontos

```bash
# Ver logs do kubelet no node
kubectl describe node <node-name>

# Verificar eventos
kubectl get events -A --sort-by='.lastTimestamp'
```

**Possíveis causas**:
- Instância SPOT não disponível (AWS recusou)
- Problemas de rede (NAT Gateway, Internet Gateway)
- Problemas de IAM (LabRole sem permissões)

### Problema: Load Balancer Controller não inicia

```bash
# Ver logs do controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verificar se o service account existe
kubectl get serviceaccount -n kube-system aws-load-balancer-controller
```

**Possíveis causas**:
- Conflito de portas (outro pod usando hostPort)
- Imagem não baixada (ImagePullBackOff)
- Recursos insuficientes no node

## 💡 Solução se persistir após 30 minutos

### Opção 1: Aumentar número de nodes (temporário)
```bash
aws eks update-nodegroup-config \
  --cluster-name tech-challenge-eks \
  --nodegroup-name tech-challenge-nodes \
  --scaling-config desiredSize=2,minSize=1,maxSize=2 \
  --region us-east-1
```

### Opção 2: Remover hostPort do Load Balancer Controller

Se o problema for especificamente com hostPort, podemos reconfigurar o Helm chart para não usar hostPort (isso é seguro para ambientes de desenvolvimento).

## 📊 Monitoramento em Tempo Real

```bash
# Assistir nodes ficarem prontos
watch -n 5 'kubectl get nodes'

# Assistir pods do sistema
watch -n 5 'kubectl get pods -n kube-system'

# Assistir todos os eventos
kubectl get events -A -w
```

## ✅ Conclusão

**AGUARDE mais 10-15 minutos.** Os warnings que você está vendo são **completamente normais** durante o deploy inicial do EKS. 

O processo está funcionando conforme esperado:
1. ✅ Terraform aplicou com sucesso
2. 🔄 EKS Cluster está criado
3. 🔄 Node Group está provisionando instâncias SPOT
4. ⏳ Pods estão aguardando nodes ficarem prontos

Quando tudo estiver pronto, você verá:
```bash
$ kubectl get nodes
NAME                         STATUS   ROLES    AGE   VERSION
ip-10-0-x-x.ec2.internal    Ready    <none>   5m    v1.31.x

$ kubectl get pods -n kube-system
NAME                                            READY   STATUS    RESTARTS   AGE
aws-load-balancer-controller-xxxxx              1/1     Running   0          3m
coredns-xxxxx                                   1/1     Running   0          5m
```

**Volte a verificar em 10-15 minutos!** 🚀
