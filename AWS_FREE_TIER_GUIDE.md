# AWS Free Tier - Guía de Configuración Costo Cero

## 🎯 Objetivo
Esta configuración garantiza que todos los servicios de AWS utilizados para el proyecto API Festivos estén dentro del **AWS Free Tier** con **COSTO CERO**.

## 💰 Servicios Incluidos y Límites

### 1. Amazon RDS MySQL
- **Instancia**: `db.t3.micro` 
- **Storage**: 20 GB SSD
- **Horas gratis**: 750 horas/mes (24/7 para 1 instancia)
- **Backups**: 0 días (deshabilitado para evitar costos)
- **Multi-AZ**: Deshabilitado
- **Encriptación**: Deshabilitada
- **Enhanced Monitoring**: Deshabilitado

### 2. Amazon ECR (Elastic Container Registry)
- **Storage**: 500 MB gratis
- **Transferencias**: 1 GB gratis/mes de salida a internet

### 3. AWS CodeBuild
- **Tiempo de build**: 100 minutos/mes gratis
- **Compute type**: `BUILD_GENERAL1_SMALL` únicamente
- **Storage cache**: Incluido

### 4. Amazon ECS Fargate
- **CPU**: 256 vCPU units (0.25 vCPU)
- **Memoria**: 512 MB
- **Límite**: Incluido en AWS Compute Savings Plans

### 5. Amazon CloudWatch Logs
- **Storage**: 5 GB gratis
- **Retención**: 7 días máximo para free tier
- **API calls**: 1 millón gratis

### 6. AWS Secrets Manager
- **Secrets**: 30 días gratis para nuevos secrets
- **API calls**: 10,000 gratis/mes

### 7. AWS CodePipeline
- **Pipeline**: 1 pipeline gratis/mes
- **Source actions**: GitHub, CodeCommit incluidos

## ⚠️ Configuraciones Críticas para Mantener Costo Cero

### RDS MySQL
```yaml
# Configuraciones que DEBEN mantenerse:
DBInstanceClass: db.t3.micro          # ✅ FREE TIER
AllocatedStorage: 20                  # ✅ FREE TIER (máximo)
MaxAllocatedStorage: 20               # ✅ Sin auto-scaling
BackupRetentionPeriod: 0              # ✅ Sin backups
StorageEncrypted: false               # ✅ Sin encriptación
MultiAZ: false                        # ✅ Sin Multi-AZ
MonitoringInterval: 0                 # ✅ Sin enhanced monitoring
EnablePerformanceInsights: false     # ✅ Sin performance insights
```

### ECS Fargate
```json
{
  "cpu": "256",        // ✅ Mínimo para Fargate
  "memory": "512",     // ✅ Mínimo para 256 CPU
  "tasks": 1           // ✅ Solo 1 tarea running
}
```

### CodeBuild
```yaml
# Usar SIEMPRE:
compute-type: BUILD_GENERAL1_SMALL    # ✅ FREE TIER
# Optimizar builds para reducir tiempo
```

## 🚨 Configuraciones que GENERAN COSTOS

### ❌ RDS - Evitar estas configuraciones:
- `db.t3.small` o superior → **$13+/mes**
- `BackupRetentionPeriod > 0` → **$0.095/GB-mes**
- `StorageEncrypted: true` → **Costo adicional**
- `MultiAZ: true` → **Doble el costo de instancia**
- `MonitoringInterval > 0` → **$2.50/mes**
- `EnablePerformanceInsights: true` → **$0.018/hour**

### ❌ ECS - Evitar estas configuraciones:
- CPU > 256 → **$0.04048/vCPU/hour**
- Memory > 512 → **$0.004445/GB/hour**
- Múltiples tasks → **Costo por cada task adicional**

### ❌ General - Evitar:
- NAT Gateways → **$32+/mes**
- Application Load Balancer → **$18+/mes**
- VPC personalizada con recursos adicionales
- CloudWatch alarms > 10 → **$0.10/alarm/mes**

## 📊 Monitoreo de Costos

### 1. AWS Cost Explorer
```bash
# Verificar costos mensualmente
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

### 2. Billing Alerts
- Configurar alerta en $0.01 para detectar cualquier costo
- Usar CloudWatch + SNS (incluidos en free tier)

### 3. AWS Budgets
- 2 budgets gratuitos
- Configurar budget de $0.00 con alertas

## 🛠️ Comandos de Verificación

### Verificar configuración RDS
```bash
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,AllocatedStorage,MultiAZ,BackupRetentionPeriod]' \
  --output table
```

### Verificar tasks ECS
```bash
aws ecs list-tasks --cluster your-cluster
aws ecs describe-tasks --cluster your-cluster --tasks task-arn
```

### Verificar uso ECR
```bash
aws ecr describe-repositories --query 'repositories[*].[repositoryName,repositorySizeInBytes]'
```

## 📋 Checklist Pre-Deploy

- [ ] **RDS**: Usar `db.t3.micro` únicamente
- [ ] **RDS**: Storage = 20GB máximo
- [ ] **RDS**: BackupRetentionPeriod = 0
- [ ] **RDS**: MultiAZ = false
- [ ] **RDS**: Enhanced Monitoring = disabled
- [ ] **ECS**: CPU = 256, Memory = 512
- [ ] **ECS**: Solo 1 task running
- [ ] **CodeBuild**: BUILD_GENERAL1_SMALL
- [ ] **CloudWatch**: Retención logs = 7 días máximo
- [ ] **Region**: us-east-1, us-west-2, o eu-west-1

## 🔄 Procedimiento de Limpieza

### Para evitar costos de recursos olvidados:
```bash
# 1. Eliminar stack RDS
aws cloudformation delete-stack --stack-name festivos-rds-dev

# 2. Eliminar imágenes ECR antigas
aws ecr list-images --repository-name festivos-api
aws ecr batch-delete-image --repository-name festivos-api --image-ids imageTag=old-tag

# 3. Eliminar log groups
aws logs delete-log-group --log-group-name /ecs/festivos-api

# 4. Detener todas las tasks ECS
aws ecs update-service --cluster cluster-name --service service-name --desired-count 0
```

## 📞 Soporte y Emergencias

### Si aparecen costos inesperados:
1. **Inmediatamente**: Detener todos los servicios
2. **Revisar**: AWS Cost Explorer para identificar el servicio
3. **Eliminar**: El recurso que genera costos
4. **Contactar**: AWS Support (incluido en free tier)

### Recursos de ayuda:
- [AWS Free Tier FAQ](https://aws.amazon.com/free/faqs/)
- [AWS Cost Management](https://aws.amazon.com/aws-cost-management/)
- [AWS Support](https://aws.amazon.com/support/)

---

**⚡ IMPORTANTE**: Esta configuración está diseñada para mantener COSTO CERO. Cualquier modificación a los parámetros especificados puede generar cargos. Siempre verificar en AWS Cost Explorer antes de realizar cambios.
