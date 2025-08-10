#!/bin/bash
set -e

# Script de deployment para AWS RDS + ECS
# Uso: ./deploy-aws.sh [dev|staging|prod]

ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
STACK_NAME="festivos-rds-${ENVIRONMENT}"

echo "🚀 Deploying API Festivos to AWS - Environment: ${ENVIRONMENT}"

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

# 1. Crear repositorio ECR si no existe
echo "📦 Verificando repositorio ECR..."
ECR_REPO_NAME="festivos-api"
aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${AWS_REGION} 2>/dev/null || {
    echo "📦 Creando repositorio ECR..."
    aws ecr create-repository \
        --repository-name ${ECR_REPO_NAME} \
        --region ${AWS_REGION} \
        --image-scanning-configuration scanOnPush=true
}

# 2. Deploy RDS Stack
echo "🗄️ Deploying RDS Stack..."
read -s -p "Ingresa la contraseña para la base de datos (min 8 caracteres): " DB_PASSWORD
echo

# Verificar si el stack existe
if aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${AWS_REGION} 2>/dev/null; then
    ACTION="update-stack"
    echo "🔄 Actualizando stack existente..."
else
    ACTION="create-stack"
    echo "🆕 Creando nuevo stack..."
fi

# Obtener VPC y subnets por defecto
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
PRIVATE_SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${DEFAULT_VPC}" --query 'Subnets[0:2].SubnetId' --output text | tr '\t' ',')

aws cloudformation ${ACTION} \
    --stack-name ${STACK_NAME} \
    --template-body file://infrastructure/rds-cloudformation.yml \
    --parameters \
        ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        ParameterKey=DBPassword,ParameterValue=${DB_PASSWORD} \
        ParameterKey=VPCId,ParameterValue=${DEFAULT_VPC} \
        ParameterKey=PrivateSubnetIds,ParameterValue=\"${PRIVATE_SUBNETS}\" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${AWS_REGION}

echo "⏳ Esperando que el stack se complete..."
aws cloudformation wait stack-${ACTION/create/create}-complete --stack-name ${STACK_NAME} --region ${AWS_REGION}

# 3. Obtener outputs del stack
echo "📋 Obteniendo información de la base de datos..."
DB_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`DBEndpoint`].OutputValue' \
    --output text)

DB_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`DatabaseURL`].OutputValue' \
    --output text)

echo "✅ Base de datos creada:"
echo "   Endpoint: ${DB_ENDPOINT}"
echo "   URL: ${DB_URL}"

# 4. Ejecutar scripts de inicialización de base de datos
echo "🗄️ Ejecutando scripts de inicialización..."
export PGPASSWORD=${DB_PASSWORD}

# Conectar y ejecutar scripts
psql -h ${DB_ENDPOINT} -U festivos_user -d festivos -f bd/DDL\ -\ Festivos.sql
psql -h ${DB_ENDPOINT} -U festivos_user -d festivos -f bd/DML\ -\ Festivos.sql

echo "✅ Scripts de base de datos ejecutados correctamente"

# 5. Crear log group para ECS
aws logs create-log-group --log-group-name /ecs/festivos-api --region ${AWS_REGION} 2>/dev/null || echo "Log group ya existe"

# 6. Generar Task Definition actualizada
echo "📄 Generando Task Definition..."
sed -e "s/ACCOUNT_ID/${ACCOUNT_ID}/g" \
    -e "s/us-east-1/${AWS_REGION}/g" \
    infrastructure/ecs-task-definition.json > infrastructure/ecs-task-definition-${ENVIRONMENT}.json

echo "✅ Task Definition generada: infrastructure/ecs-task-definition-${ENVIRONMENT}.json"

# 7. Mostrar siguiente pasos
echo ""
echo "🎉 ¡Deployment de infraestructura completado!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Configurar CodeBuild project con las variables:"
echo "   - AWS_ACCOUNT_ID=${ACCOUNT_ID}"
echo "   - AWS_DEFAULT_REGION=${AWS_REGION}"
echo "   - IMAGE_REPO_NAME=${ECR_REPO_NAME}"
echo ""
echo "2. Crear ECS Cluster y Service usando:"
echo "   infrastructure/ecs-task-definition-${ENVIRONMENT}.json"
echo ""
echo "3. Configurar CodePipeline para auto-deployment"
echo ""
echo "🔗 Recursos creados:"
echo "   - RDS: ${DB_ENDPOINT}"
echo "   - ECR: ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
echo "   - Secrets Manager: ${ENVIRONMENT}/festivos-api/database"
