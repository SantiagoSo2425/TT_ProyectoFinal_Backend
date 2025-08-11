#!/usr/bin/env bash
set -e

# Directorios del script y raíz del proyecto
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# Cambiar al directorio raíz del proyecto para referencias relativas
cd "$PROJECT_ROOT"

# Script manual para deployar solo el stack de ECS
# Uso: ./deploy-ecs-manual.sh [dev|staging|prod]

ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
ECS_STACK_NAME="festivos-ecs-${ENVIRONMENT}"
RDS_STACK_NAME="festivos-rds-${ENVIRONMENT}"
ECR_REPO_NAME="festivos-api-${ENVIRONMENT}"

echo "🚀 Deploying ECS Stack manually - Environment: ${ENVIRONMENT}"

# Validar parámetros
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Error: Environment debe ser dev, staging o prod"
    exit 1
fi

# Verificar AWS CLI y credenciales
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI no está instalado"
    exit 1
fi

aws sts get-caller-identity > /dev/null || {
    echo "❌ Error: Credenciales AWS no configuradas"
    exit 1
}

# Obtener información necesaria del stack RDS
echo "📋 Obteniendo información del stack RDS..."
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text --region ${AWS_REGION})
# Cambiar a subnets públicas para que tengan acceso a internet y puedan conectarse a ECR
# Usando formato compatible con Windows PowerShell
SUBNET1=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${DEFAULT_VPC}" "Name=map-public-ip-on-launch,Values=true" \
    --query 'Subnets[0].SubnetId' \
    --output text --region ${AWS_REGION})
SUBNET2=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${DEFAULT_VPC}" "Name=map-public-ip-on-launch,Values=true" \
    --query 'Subnets[1].SubnetId' \
    --output text --region ${AWS_REGION})
PUBLIC_SUBNETS="${SUBNET1},${SUBNET2}"

DB_SECURITY_GROUP_ID=$(aws cloudformation describe-stacks \
    --stack-name ${RDS_STACK_NAME} \
    --region ${AWS_REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`DBSecurityGroupId`].OutputValue' \
    --output text)

DB_URL=$(aws cloudformation describe-stacks \
    --stack-name ${RDS_STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`DatabaseURL`].OutputValue' \
    --output text --region ${AWS_REGION})

# Solicitar contraseña de la base de datos
read -s -p "Ingresa la contraseña de la base de datos PostgreSQL: " DB_PASSWORD
echo

# Crear o actualizar el secret en AWS Secrets Manager
SECRET_NAME="festivos-db-password-${ENVIRONMENT}"
echo "🔐 Creando/actualizando secret en AWS Secrets Manager..."

# Verificar si el secret ya existe
if aws secretsmanager describe-secret --secret-id ${SECRET_NAME} --region ${AWS_REGION} 2>/dev/null; then
    echo "📝 Actualizando secret existente..."
    aws secretsmanager update-secret \
        --secret-id ${SECRET_NAME} \
        --secret-string "${DB_PASSWORD}" \
        --region ${AWS_REGION}
else
    echo "🆕 Creando nuevo secret..."
    aws secretsmanager create-secret \
        --name ${SECRET_NAME} \
        --description "Password for Festivos PostgreSQL database - ${ENVIRONMENT}" \
        --secret-string "${DB_PASSWORD}" \
        --region ${AWS_REGION} \
        --tags Key=Environment,Value=${ENVIRONMENT} Key=Project,Value=Festivos
fi

# Obtener el ARN del secret
DB_SECRET_ARN=$(aws secretsmanager describe-secret \
    --secret-id ${SECRET_NAME} \
    --query 'ARN' \
    --output text \
    --region ${AWS_REGION})

echo "✅ Secret creado/actualizado: ${DB_SECRET_ARN}"

# Verificar si el stack existe y eliminarlo si tiene problemas
if aws cloudformation describe-stacks --stack-name ${ECS_STACK_NAME} --region ${AWS_REGION} 2>/dev/null; then
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name ${ECS_STACK_NAME} --query 'Stacks[0].StackStatus' --output text --region ${AWS_REGION})
    echo "📊 Stack actual en estado: ${STACK_STATUS}"

    if [[ "$STACK_STATUS" =~ .*FAILED.* || "$STACK_STATUS" =~ .*ROLLBACK.* ]]; then
        echo "🗑️ Eliminando stack en estado fallido..."
        aws cloudformation delete-stack --stack-name ${ECS_STACK_NAME} --region ${AWS_REGION}
        echo "⏳ Esperando que el stack se elimine..."
        aws cloudformation wait stack-delete-complete --stack-name ${ECS_STACK_NAME} --region ${AWS_REGION}
        echo "✅ Stack eliminado exitosamente"
    fi
fi

# Obtener Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account: ${ACCOUNT_ID}"

# 1. Crear repositorio ECR si no existe
echo "📦 Verificando/creando repositorio ECR..."
aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${AWS_REGION} 2>/dev/null || {
    echo "📦 Creando repositorio ECR: ${ECR_REPO_NAME}..."
    aws ecr create-repository \
        --repository-name ${ECR_REPO_NAME} \
        --region ${AWS_REGION} \
        --image-scanning-configuration scanOnPush=false \
        --tags Key=Environment,Value=${ENVIRONMENT} Key=Project,Value=Festivos
}

# 2. Verificar si el JAR ya existe o compilar la aplicación Spring Boot
echo "📦 Verificando aplicación Spring Boot..."
cd apiFestivos

# Verificar si el JAR ya existe
if [[ -f "aplicacion/target/aplicacion-0.0.1-SNAPSHOT.jar" ]]; then
    echo "✅ JAR encontrado: aplicacion/target/aplicacion-0.0.1-SNAPSHOT.jar"
else
    # Verificar que Maven esté disponible
    if ! command -v mvn &> /dev/null; then
        echo "❌ Error: Maven no está instalado y el JAR no existe"
        echo "   Instala Maven o compila la aplicación manualmente"
        exit 1
    fi

    # Compilar la aplicación
    echo "🔨 Ejecutando Maven clean package..."
    mvn clean package -DskipTests=true -q

    # Verificar que el JAR se creó correctamente
    if [[ ! -f "aplicacion/target/aplicacion-0.0.1-SNAPSHOT.jar" ]]; then
        echo "❌ Error: No se pudo generar el JAR de la aplicación"
        exit 1
    fi
fi

echo "✅ Aplicación lista para deployment"

# 3. Construir y subir imagen Docker a ECR
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
echo "   Image URI: ${IMAGE_URI}"

# Volver al directorio raíz del proyecto
cd ..

# Deploy ECS Stack con tags corregidos
echo "🚀 Desplegando ECS Stack con CloudFormation..."
aws cloudformation deploy \
    --stack-name ${ECS_STACK_NAME} \
    --template-file "${PROJECT_ROOT}/infrastructure/ecs-cloudformation.yml" \
    --region ${AWS_REGION} \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        Environment=${ENVIRONMENT} \
        VPCId=${DEFAULT_VPC} \
        PrivateSubnetIds="${PUBLIC_SUBNETS}" \
        DBSecurityGroupId=${DB_SECURITY_GROUP_ID} \
        DBURL="${DB_URL}" \
        DBSecretArn=${DB_SECRET_ARN} \
        AWSRegion=${AWS_REGION} \
    --tags \
        Environment=${ENVIRONMENT} \
        Project=Festivos \
        CostOptimization=FreeTier

echo "✅ ECS Stack deployed successfully: ${ECS_STACK_NAME}"

# Obtener información del servicio desplegado
echo "📋 Información del servicio desplegado:"
CLUSTER_NAME=$(aws cloudformation describe-stacks \
    --stack-name ${ECS_STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`ECSClusterName`].OutputValue' \
    --output text --region ${AWS_REGION})

SERVICE_NAME=$(aws cloudformation describe-stacks \
    --stack-name ${ECS_STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`ServiceName`].OutputValue' \
    --output text --region ${AWS_REGION})

REPOSITORY_URI=$(aws cloudformation describe-stacks \
    --stack-name ${ECS_STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`RepositoryUri`].OutputValue' \
    --output text --region ${AWS_REGION})

echo "   Cluster: ${CLUSTER_NAME}"
echo "   Service: ${SERVICE_NAME}"
echo "   Repository: ${REPOSITORY_URI}"

echo "🎉 Deployment completado exitosamente!"
