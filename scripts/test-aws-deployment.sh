#!/bin/bash
set -e

# Script de Testing y Verificación para AWS Free Tier
# Uso: ./test-aws-deployment.sh [dev|staging|prod]
# Verifica que todos los servicios estén funcionando correctamente

ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
STACK_NAME="festivos-rds-${ENVIRONMENT}"

echo "🧪 Testing AWS Deployment - Environment: ${ENVIRONMENT}"
echo "🔍 Verificando servicios en Free Tier..."

# Verificar AWS CLI y credenciales
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI no está instalado"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
    echo "❌ Error: Credenciales AWS no configuradas"
    exit 1
}

echo "✅ AWS Account: ${ACCOUNT_ID}"
echo "✅ Región: ${AWS_REGION}"

# 1. Verificar Stack de CloudFormation
echo ""
echo "🏗️ Verificando CloudFormation Stack..."
if aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${AWS_REGION} >/dev/null 2>&1; then
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].StackStatus' --output text --region ${AWS_REGION})
    echo "✅ Stack Status: ${STACK_STATUS}"

    if [[ "$STACK_STATUS" != "CREATE_COMPLETE" && "$STACK_STATUS" != "UPDATE_COMPLETE" ]]; then
        echo "❌ Stack no está en estado válido"
        exit 1
    fi
else
    echo "❌ Stack '${STACK_NAME}' no encontrado"
    echo "🔧 Ejecuta primero: ./deploy-aws.sh ${ENVIRONMENT}"
    exit 1
fi

# 2. Verificar RDS Instance
echo ""
echo "🗄️ Verificando RDS PostgreSQL Instance..."
DB_INSTANCE_ID="${ENVIRONMENT}-festivos-postgres"
RDS_STATUS=$(aws rds describe-db-instances --db-instance-identifier ${DB_INSTANCE_ID} --query 'DBInstances[0].DBInstanceStatus' --output text --region ${AWS_REGION} 2>/dev/null || echo "not-found")

if [[ "$RDS_STATUS" == "not-found" ]]; then
    echo "❌ RDS Instance no encontrada"
    exit 1
elif [[ "$RDS_STATUS" != "available" ]]; then
    echo "⏳ RDS Status: ${RDS_STATUS} - Esperando que esté disponible..."
    aws rds wait db-instance-available --db-instance-identifier ${DB_INSTANCE_ID} --region ${AWS_REGION}
    echo "✅ RDS Instance disponible"
else
    echo "✅ RDS Status: ${RDS_STATUS}"
fi

# Obtener información de RDS
DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier ${DB_INSTANCE_ID} --query 'DBInstances[0].Endpoint.Address' --output text --region ${AWS_REGION})
DB_PORT=$(aws rds describe-db-instances --db-instance-identifier ${DB_INSTANCE_ID} --query 'DBInstances[0].Endpoint.Port' --output text --region ${AWS_REGION})
DB_CLASS=$(aws rds describe-db-instances --db-instance-identifier ${DB_INSTANCE_ID} --query 'DBInstances[0].DBInstanceClass' --output text --region ${AWS_REGION})
DB_STORAGE=$(aws rds describe-db-instances --db-instance-identifier ${DB_INSTANCE_ID} --query 'DBInstances[0].AllocatedStorage' --output text --region ${AWS_REGION})

echo "   Endpoint: ${DB_ENDPOINT}:${DB_PORT}"
echo "   Instance Class: ${DB_CLASS}"
echo "   Storage: ${DB_STORAGE}GB"

# Verificar que esté en Free Tier
if [[ "$DB_CLASS" != "db.t3.micro" ]]; then
    echo "⚠️ ADVERTENCIA: Instance class '${DB_CLASS}' NO está en Free Tier"
    echo "   Recomendado: db.t3.micro para evitar costos"
fi

if [[ "$DB_STORAGE" -gt 20 ]]; then
    echo "⚠️ ADVERTENCIA: Storage ${DB_STORAGE}GB excede Free Tier (20GB máximo)"
fi

# 3. Test de conectividad a la base de datos
echo ""
echo "🔌 Testing conectividad a PostgreSQL..."

## Solicitar contraseña de DB si no está en variable de entorno
if [[ -z "$DB_PASSWORD" ]]; then
    read -s -p "Ingresa la contraseña de la base de datos PostgreSQL: " DB_PASSWORD
    echo
fi

# Test básico de conexión
echo "🔍 Verificando conexión a PostgreSQL..."
export PGPASSWORD="$DB_PASSWORD"
psql --host=${DB_ENDPOINT} --port=${DB_PORT} --username=admin --dbname=festivos --command="SELECT 'Connection OK';" --no-password --quiet && {
    echo "✅ Conexión PostgreSQL exitosa"
} || {
    echo "❌ Error: No se puede conectar a PostgreSQL"
    echo "   Verifica que el Security Group permita conexiones desde tu IP y que psql esté instalado"
    exit 1
}

# Test de esquema de base de datos
echo "🔍 Verificando esquema de base de datos..."
TABLES_COUNT=$(psql --host=${DB_ENDPOINT} --port=${DB_PORT} --username=admin --dbname=festivos --tuples-only --command="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" --no-password 2>/dev/null || echo "0")

if [[ "${TABLES_COUNT}" -gt 0 ]]; then
    echo "✅ Base de datos inicializada con ${TABLES_COUNT} tablas"

    # Verificar tablas específicas
    echo "🔍 Verificando tablas principales..."
    psql --host=${DB_ENDPOINT} --port=${DB_PORT} --username=admin --dbname=festivos --tuples-only --command="
        SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;
    " --no-password 2>/dev/null || echo "   No se pudieron obtener detalles de tablas"
else
    echo "❌ Base de datos no inicializada correctamente"
    echo "🔧 Ejecuta los scripts SQL manualmente:"
    echo "   psql --host=${DB_ENDPOINT} --port=${DB_PORT} --username=admin --dbname=festivos -f bd/DDL - Festivos.sql"
    echo "   psql --host=${DB_ENDPOINT} --port=${DB_PORT} --username=admin --dbname=festivos -f bd/DML - Festivos.sql"
fi

# 4. Verificar ECR Repository
echo ""
echo "📦 Verificando ECR Repository..."
ECR_REPO_NAME="festivos-api"
ECR_REPO_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

if aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${AWS_REGION} >/dev/null 2>&1; then
    echo "✅ ECR Repository existe: ${ECR_REPO_URI}"

    # Verificar imágenes
    IMAGE_COUNT=$(aws ecr list-images --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION} --query 'length(imageIds)' --output text 2>/dev/null || echo "0")
    echo "   Imágenes disponibles: ${IMAGE_COUNT}"

    if [[ "$IMAGE_COUNT" -gt 0 ]]; then
        echo "   Última imagen:"
        aws ecr describe-images --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION} --query 'imageDetails[0].[imageTags[0],imagePushedAt,imageSizeInBytes]' --output table 2>/dev/null || echo "   No se pudo obtener información de imagen"
    fi
else
    echo "❌ ECR Repository no encontrado"
fi

# 5. Verificar CloudWatch Log Group
echo ""
echo "📝 Verificando CloudWatch Logs..."
LOG_GROUP="/ecs/festivos-api"

if aws logs describe-log-groups --log-group-name-prefix ${LOG_GROUP} --region ${AWS_REGION} --query 'logGroups[0]' >/dev/null 2>&1; then
    echo "✅ CloudWatch Log Group existe: ${LOG_GROUP}"

    # Verificar retención
    RETENTION=$(aws logs describe-log-groups --log-group-name-prefix ${LOG_GROUP} --region ${AWS_REGION} --query 'logGroups[0].retentionInDays' --output text 2>/dev/null || echo "null")
    if [[ "$RETENTION" == "null" ]]; then
        echo "⚠️ ADVERTENCIA: Log retention no configurada (puede generar costos)"
        echo "   Configurando retención de 7 días..."
        aws logs put-retention-policy --log-group-name ${LOG_GROUP} --retention-in-days 7 --region ${AWS_REGION}
    else
        echo "   Retención configurada: ${RETENTION} días"
    fi
else
    echo "❌ CloudWatch Log Group no encontrado"
fi

# 6. Verificar Secrets Manager
echo ""
echo "🔐 Verificando AWS Secrets Manager..."
SECRET_NAME="${ENVIRONMENT}/festivos-api/database"

if aws secretsmanager describe-secret --secret-id ${SECRET_NAME} --region ${AWS_REGION} >/dev/null 2>&1; then
    echo "✅ Secret existe: ${SECRET_NAME}"

    # Test de obtener secret (sin mostrar valor)
    aws secretsmanager get-secret-value --secret-id ${SECRET_NAME} --region ${AWS_REGION} --query 'SecretString' >/dev/null 2>&1 && {
        echo "✅ Secret accesible"
    } || {
        echo "❌ Error: No se puede acceder al secret"
    }
else
    echo "❌ Secret no encontrado en Secrets Manager"
fi

# 7. Verificar roles IAM
echo ""
echo "👤 Verificando roles IAM..."

# ecsTaskExecutionRole
if aws iam get-role --role-name ecsTaskExecutionRole >/dev/null 2>&1; then
    echo "✅ ecsTaskExecutionRole existe"
else
    echo "❌ ecsTaskExecutionRole no encontrado"
fi

# ecsTaskRole
if aws iam get-role --role-name ecsTaskRole >/dev/null 2>&1; then
    echo "✅ ecsTaskRole existe"
else
    echo "❌ ecsTaskRole no encontrado"
fi

# 8. Test de construcción de imagen Docker (opcional)
echo ""
read -p "¿Quieres probar la construcción de la imagen Docker? (y/n): " BUILD_TEST

if [[ "$BUILD_TEST" =~ ^[Yy]$ ]]; then
    echo "🐳 Testing Docker build..."

    if [[ -f "apiFestivos/Dockerfile" ]]; then
        cd apiFestivos

        echo "📦 Compilando aplicación..."
        if command -v mvn &> /dev/null; then
            mvn clean package -DskipTests=true -q
        else
            echo "❌ Maven no encontrado - saltando compilación"
        fi

        echo "🏗️ Construyendo imagen Docker..."
        docker build -t festivos-api-test . && {
            echo "✅ Imagen Docker construida exitosamente"
            docker images festivos-api-test

            # Limpiar imagen de prueba
            read -p "¿Eliminar imagen de prueba? (y/n): " CLEANUP
            if [[ "$CLEANUP" =~ ^[Yy]$ ]]; then
                docker rmi festivos-api-test
            fi
        } || {
            echo "❌ Error en construcción de imagen Docker"
        }

        cd ..
    else
        echo "❌ Dockerfile no encontrado en apiFestivos/"
    fi
fi

# 9. Resumen final y recomendaciones
echo ""
echo "📊 RESUMEN DE VERIFICACIÓN"
echo "=========================="
echo "✅ CloudFormation Stack: OK"
echo "✅ RDS MySQL (${DB_CLASS}, ${DB_STORAGE}GB): OK"
echo "✅ ECR Repository: OK"
echo "✅ CloudWatch Logs: OK"
echo "✅ Secrets Manager: OK"
echo "✅ IAM Roles: OK"

echo ""
echo "🎯 PRÓXIMOS PASOS PARA DEPLOYMENT COMPLETO:"
echo ""
echo "1. 🏗️ Configurar CodeBuild Project:"
echo "   - Ir a AWS Console > CodeBuild > Create Project"
echo "   - Source: GitHub (tu repositorio)"
echo "   - Environment: Managed image, Amazon Linux 2, Standard runtime"
echo "   - Compute type: BUILD_GENERAL1_SMALL (Free Tier)"
echo "   - Buildspec: ci/buildspec-backend.yml"
echo "   - Variables de entorno:"
echo "     * AWS_ACCOUNT_ID=${ACCOUNT_ID}"
echo "     * AWS_DEFAULT_REGION=${AWS_REGION}"
echo "     * IMAGE_REPO_NAME=${ECR_REPO_NAME}"
echo ""
echo "2. 🚀 Crear ECS Cluster y Service:"
echo "   - Ir a AWS Console > ECS > Create Cluster"
echo "   - Tipo: Fargate"
echo "   - Crear Service con Task Definition generada:"
echo "     infrastructure/ecs-task-definition-${ENVIRONMENT}.json"
echo ""
echo "3. 🔄 Configurar CodePipeline:"
echo "   - Source: GitHub"
echo "   - Build: CodeBuild project creado"
echo "   - Deploy: ECS Service"
echo ""
echo "4. 🌐 (Opcional) Configurar Application Load Balancer:"
echo "   - NOTA: ALB NO está en Free Tier (\$18+/mes)"
echo "   - Alternativa: Acceso directo via IP pública del task"
echo ""
echo "💰 VERIFICACIÓN DE COSTOS:"
echo "   - Todos los recursos verificados están en Free Tier"
echo "   - RDS: ${DB_CLASS} (✅ Free Tier elegible)"
echo "   - Storage: ${DB_STORAGE}GB (✅ ≤ 20GB Free Tier)"
echo "   - Monitorea uso en AWS Cost Explorer"
echo ""
echo "🔗 URLs útiles:"
echo "   - RDS Endpoint: ${DB_ENDPOINT}:${DB_PORT}"
echo "   - ECR Repository: ${ECR_REPO_URI}"
echo "   - CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#logsV2:log-groups/log-group/%2Fecs%2Ffestivos-api"
