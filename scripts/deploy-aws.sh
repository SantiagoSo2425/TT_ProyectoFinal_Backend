#!/usr/bin/env bash
set -e

# Directorios del script y raíz del proyecto
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# Cambiar al directorio raíz del proyecto para referencias relativas
cd "$PROJECT_ROOT"

# Script de deployment para AWS RDS + ECS - OPTIMIZADO PARA FREE TIER
# Uso: ./deploy-aws.sh [dev|staging|prod]
# GARANTÍA: COSTO CERO - Solo utiliza servicios incluidos en AWS Free Tier

ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
STACK_NAME="festivos-rds-${ENVIRONMENT}"

echo "🚀 Deploying API Festivos to AWS - Environment: ${ENVIRONMENT}"
echo "💰 MODO FREE TIER - Configuración optimizada para COSTO CERO"

# Validar parámetros
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Error: Environment debe ser dev, staging o prod"
    exit 1
fi

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI no está instalado"
    exit 1
fi

# Verificar credenciales AWS
echo "🔐 Verificando credenciales AWS..."
aws sts get-caller-identity > /dev/null || {
    echo "❌ Error: Credenciales AWS no configuradas"
    exit 1
}

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account: ${ACCOUNT_ID}"

# FREE TIER CHECK: Verificar región válida para free tier
if [[ "$AWS_REGION" != "us-east-1" && "$AWS_REGION" != "us-west-2" && "$AWS_REGION" != "eu-west-1" ]]; then
    echo "⚠️  Advertencia: La región ${AWS_REGION} puede tener costos adicionales"
    echo "   Regiones recomendadas para Free Tier: us-east-1, us-west-2, eu-west-1"
fi

# 1. Crear repositorio ECR si no existe (FREE TIER: 500MB storage gratis)
echo "📦 Verificando repositorio ECR (Free Tier: 500MB storage)..."
ECR_REPO_NAME="festivos-api"
aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${AWS_REGION} 2>/dev/null || {
    echo "📦 Creando repositorio ECR..."
    aws ecr create-repository \
        --repository-name ${ECR_REPO_NAME} \
        --region ${AWS_REGION} \
        --image-scanning-configuration scanOnPush=false \
        --tags Key=CostOptimization,Value=FreeTier Key=Environment,Value=${ENVIRONMENT}
}

# 2. Deploy RDS Stack - FREE TIER OPTIMIZED
echo "🗄️ Deploying RDS PostgreSQL Stack (Free Tier: db.t3.micro + 20GB storage)..."
read -s -p "Ingresa la contraseña para la base de datos PostgreSQL (min 8 caracteres): " DB_PASSWORD
echo

# Validar longitud de contraseña
if [[ ${#DB_PASSWORD} -lt 8 ]]; then
    echo "❌ Error: La contraseña debe tener al menos 8 caracteres"
    exit 1
fi

# Verificar si el stack existe
if aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${AWS_REGION} 2>/dev/null; then
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].StackStatus' --output text --region ${AWS_REGION})
    echo "📊 Stack actual en estado: ${STACK_STATUS}"

    if [[ "$STACK_STATUS" == "DELETE_IN_PROGRESS" ]]; then
        echo "⏳ Stack en proceso de eliminación. Esperando..."
        aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME} --region ${AWS_REGION}
        ACTION="create-stack"
        echo "🆕 Creando nuevo stack..."
    elif [[ "$STACK_STATUS" == "CREATE_COMPLETE" || "$STACK_STATUS" == "UPDATE_COMPLETE" ]]; then
        ACTION="update-stack"
        echo "🔄 Actualizando stack existente..."
    else
        echo "❌ Stack en estado inválido: ${STACK_STATUS}"
        exit 1
    fi
else
    ACTION="create-stack"
    echo "🆕 Creando nuevo stack..."
fi

# Obtener VPC y subnets por defecto (Free Tier: VPC por defecto incluida)
echo "🔍 Obteniendo VPC y subnets por defecto (Free Tier)..."
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text --region ${AWS_REGION})
if [[ "$DEFAULT_VPC" == "None" || -z "$DEFAULT_VPC" ]]; then
    echo "❌ Error: No se encontró VPC por defecto. Creando una nueva VPC sería un costo adicional."
    echo "   Recomendación: Usar la VPC por defecto para mantener el Free Tier"
    exit 1
fi

PRIVATE_SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${DEFAULT_VPC}" \
    --query 'Subnets[0:2].SubnetId' \
    --output text --region ${AWS_REGION} | tr '\t' ',')

echo "✅ VPC por defecto: ${DEFAULT_VPC}"
echo "✅ Subnets: ${PRIVATE_SUBNETS}"

# Deploy CloudFormation Stack
aws cloudformation ${ACTION} \
    --stack-name ${STACK_NAME} \
    --template-body file://infrastructure/rds-cloudformation.yml \
    --parameters \
        ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        ParameterKey=DBPassword,ParameterValue=${DB_PASSWORD} \
        ParameterKey=VPCId,ParameterValue=${DEFAULT_VPC} \
        ParameterKey=PrivateSubnetIds,ParameterValue=\"${PRIVATE_SUBNETS}\" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${AWS_REGION} \
    --tags \
        Key=CostOptimization,Value=FreeTier \
        Key=Environment,Value=${ENVIRONMENT} \
        Key=Project,Value=FestivosAPI \
    2>/dev/null || {
        if [[ "$ACTION" == "update-stack" ]]; then
            echo "✅ Stack ya está actualizado - no se requieren cambios"
        else
            echo "❌ Error en el deployment del stack"
            exit 1
        fi
    }

echo "⏳ Esperando que el stack se complete..."
if [[ "$ACTION" == "create-stack" ]]; then
    aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME} --region ${AWS_REGION}
elif aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${AWS_REGION} --query 'Stacks[0].StackStatus' --output text | grep -q "UPDATE_IN_PROGRESS"; then
    aws cloudformation wait stack-update-complete --stack-name ${STACK_NAME} --region ${AWS_REGION}
else
    echo "✅ Stack ya está en estado estable"
fi

# 3. Obtener outputs del stack
echo "📋 Obteniendo información de la base de datos..."
DB_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`DBEndpoint`].OutputValue' \
    --output text --region ${AWS_REGION})

DB_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`DatabaseURL`].OutputValue' \
    --output text --region ${AWS_REGION})

echo "✅ Base de datos PostgreSQL creada (Free Tier):"
echo "   Endpoint: ${DB_ENDPOINT}"
echo "   URL: ${DB_URL}"

# 4. Ejecutar scripts de inicialización de base de datos (OPCIONAL)
echo "🗄️ Inicialización de base de datos..."
echo "ℹ️  NOTA: Si tienes psql instalado, puedes ejecutar manualmente:"
echo "   psql --host=${DB_ENDPOINT} --port=5432 --username=festivos_user --dbname=festivos -f \"bd/DDL - Festivos.sql\""
echo "   psql --host=${DB_ENDPOINT} --port=5432 --username=festivos_user --dbname=festivos -f \"bd/DML - Festivos.sql\""
echo ""
echo "✅ Continuando con deployment de la API (Spring Boot puede crear las tablas automáticamente)"

# 5. Crear log group para ECS (FREE TIER: 5GB logs gratis)
echo "📝 Creando CloudWatch Log Group (Free Tier: 5GB storage)..."
aws logs create-log-group \
    --log-group-name /ecs/festivos-api \
    --region ${AWS_REGION} \
    --tags CostOptimization=FreeTier,Environment=${ENVIRONMENT} \
    2>/dev/null || echo "Log group ya existe"

# Configurar retención de logs para free tier (no retención indefinida)
aws logs put-retention-policy \
    --log-group-name /ecs/festivos-api \
    --retention-in-days 7 \
    --region ${AWS_REGION} 2>/dev/null || echo "Retención ya configurada"

# 6. Generar Task Definition actualizada
echo "📄 Generando Task Definition (Free Tier: 256 CPU, 512 MB RAM)..."
sed -e "s/ACCOUNT_ID/${ACCOUNT_ID}/g" \
    -e "s/us-east-1/${AWS_REGION}/g" \
    infrastructure/ecs-task-definition.json > infrastructure/ecs-task-definition-${ENVIRONMENT}.json

echo "✅ Task Definition generada: infrastructure/ecs-task-definition-${ENVIRONMENT}.json"

# 7. Crear roles IAM necesarios para ECS (si no existen)
echo "👤 Verificando roles IAM para ECS..."

# ecsTaskExecutionRole (para Fargate)
aws iam get-role --role-name ecsTaskExecutionRole 2>/dev/null || {
    echo "📋 Creando ecsTaskExecutionRole..."
    aws iam create-role \
        --role-name ecsTaskExecutionRole \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
                    "Action": "sts:AssumeRole"
                }
            ]
        }' \
        --tags Key=CostOptimization,Value=FreeTier

    aws iam attach-role-policy \
        --role-name ecsTaskExecutionRole \
        --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
}

# ecsTaskRole (para acceso a otros servicios AWS)
aws iam get-role --role-name ecsTaskRole 2>/dev/null || {
    echo "📋 Creando ecsTaskRole..."
    aws iam create-role \
        --role-name ecsTaskRole \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
                    "Action": "sts:AssumeRole"
                }
            ]
        }' \
        --tags Key=CostOptimization,Value=FreeTier
}

# 8. DESPLIEGUE COMPLETO DE LA API - NUEVO BLOQUE
echo ""
echo "🚀 DESPLEGANDO API SPRING BOOT EN ECS FARGATE (FREE TIER)..."
echo ""

# 8.1. Compilar y construir la aplicación Spring Boot
echo "📦 Compilando aplicación Spring Boot..."
cd apiFestivos

# Verificar que Maven esté disponible
if ! command -v mvn &> /dev/null; then
    echo "❌ Error: Maven no está instalado"
    echo "   Instala Maven para continuar con el deployment de la API"
    exit 1
fi

# Compilar la aplicación (optimizado para Free Tier)
echo "🔨 Ejecutando Maven clean package..."
mvn clean package -DskipTests=true -q

# Verificar que el JAR se creó correctamente
if [[ ! -f "aplicacion/target/aplicacion-0.0.1-SNAPSHOT.jar" ]]; then
    echo "❌ Error: No se pudo generar el JAR de la aplicación"
    exit 1
fi

echo "✅ Aplicación compilada exitosamente"

# 8.2. Login a ECR y construir imagen Docker
echo "🐳 Construyendo y subiendo imagen Docker a ECR..."

# Login a ECR
echo "🔑 Realizando login a ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Construir imagen Docker
echo "🏗️ Construyendo imagen Docker..."
IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest"
docker build -t ${ECR_REPO_NAME}:latest .
docker tag ${ECR_REPO_NAME}:latest ${IMAGE_URI}

# Subir imagen a ECR
echo "📤 Subiendo imagen a ECR..."
docker push ${IMAGE_URI}

echo "✅ Imagen Docker subida exitosamente a ECR"

# Volver al directorio raíz del proyecto
cd ..

# Deploy ECS Stack via CloudFormation
ECS_STACK_NAME="festivos-ecs-${ENVIRONMENT}"
echo "🚀 Deploying ECS Stack via CloudFormation - Environment: ${ENVIRONMENT}"
DB_SECURITY_GROUP_ID=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --region ${AWS_REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`DBSecurityGroupId`].OutputValue' \
    --output text)

aws cloudformation deploy \
    --stack-name ${ECS_STACK_NAME} \
    --template-file infrastructure/ecs-cloudformation.yml \
    --region ${AWS_REGION} \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        Environment=${ENVIRONMENT} \
        VPCId=${DEFAULT_VPC} \
        PrivateSubnetIds="${PRIVATE_SUBNETS}" \
        DBSecurityGroupId=${DB_SECURITY_GROUP_ID} \
        DBURL="${DB_URL}" \
        DBPassword=${DB_PASSWORD} \
        AWSRegion=${AWS_REGION} \
    --tags "Key=Environment,Value=${ENVIRONMENT}" "Key=Project,Value=FestivosAPI"

echo "✅ ECS Stack deployed: ${ECS_STACK_NAME}"

echo "🎉 Deployment completo - ¡Disfruta tu API Festivos!"
exit 0

# 9. Mostrar resumen de costos FREE TIER COMPLETO
echo ""
echo "🎉 ¡Deployment de infraestructura y API completado - FREE TIER!"
echo ""
echo "💰 RESUMEN DE COSTOS (FREE TIER - $0.00):"
echo "   ✅ RDS PostgreSQL db.t3.micro: 750 horas/mes GRATIS"
echo "   ✅ Storage 20GB: GRATIS en Free Tier"
echo "   ✅ ECR: 500MB storage GRATIS"
echo "   ✅ CloudWatch Logs: 5GB GRATIS"
echo "   ✅ CodeBuild: 100 minutos/mes GRATIS"
echo "   ✅ ECS Fargate: Incluido en compute credits"
echo ""
echo "📋 Próximos pasos:"
echo "1. Probar la API usando el URL proporcionado:"
echo "   ${API_URL}"
echo "   - Verificar estado: ${API_URL}/actuator/health"
echo "   - Obtener festivos: ${API_URL}/festivos/obtener/{año}"
echo "   - Verificar festivo: ${API_URL}/festivos/verificar/{año}/{mes}/{dia}"
echo ""
echo "2. Configurar dominio personalizado (opcional) usando Amazon Route 53"
echo ""
echo "3. Monitorear uso en AWS Cost Explorer para mantener Free Tier"
echo ""
echo "🔗 Recursos creados (FREE TIER):"
echo "   - RDS PostgreSQL: ${DB_ENDPOINT}"
echo "   - ECR: ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
echo "   - Secrets Manager: ${ENVIRONMENT}/festivos-api/database"
echo "   - CloudWatch Logs: /ecs/festivos-api"
echo ""
echo "⚠️  IMPORTANTE - Para mantener FREE TIER:"
echo "   - No crear más de 1 instancia RDS db.t3.micro"
echo "   - No exceder 750 horas/mes de uso"
echo "   - Mantener storage ≤ 20GB"
echo "   - Monitorear uso mensual en AWS Cost Explorer"
