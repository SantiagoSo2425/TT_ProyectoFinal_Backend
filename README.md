# API de Festivos - Docker Setup

Esta API gestiona festivos de diferentes países usando Spring Boot, PostgreSQL y análisis de código con SonarQube.

## Arquitectura

- **API**: Spring Boot con arquitectura hexagonal
- **Base de Datos**: PostgreSQL 15
- **Análisis de Código**: SonarQube Community
- **Cobertura de Código**: JaCoCo
- **Contenedores**: Docker & Docker Compose

## Prerequisitos

- Docker Desktop
- Docker Compose
- Git

## Estructura del Proyecto

```
├── apiFestivos/           # Código fuente de la API
│   ├── dominio/          # Entidades y DTOs
│   ├── core/             # Interfaces de servicios
│   ├── aplicacion/       # Implementación de servicios
│   ├── infraestructura/  # Repositorios
│   ├── presentacion/     # Controladores y configuración
│   └── Dockerfile        # Imagen Docker para la API
├── bd/                   # Scripts de base de datos
├── docker-compose.yml    # Configuración de servicios
└── Makefile             # Comandos útiles
```

## Servicios Incluidos

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| api-festivos | 8080 | API REST de festivos |
| postgres | 5432 | Base de datos PostgreSQL |
| sonarqube | 9000 | Análisis de calidad de código |

## Inicio Rápido

### 1. Clonar y navegar al proyecto
```bash
git clone <repositorio>
cd TT_ANI_ProyectoFestivos
```

### 2. Levantar servicios base
```bash
docker-compose up -d postgres sonarqube
```

### 3. Esperar inicialización (30-60 segundos)
```bash
# Verificar que PostgreSQL esté listo
docker-compose logs postgres

# Verificar que SonarQube esté listo
docker-compose logs sonarqube
```

### 4. Levantar la API
```bash
docker-compose up -d api-festivos
```

### 5. Verificar servicios
```bash
# Health check de la API
curl http://localhost:8080/actuator/health

# Acceder a SonarQube
# http://localhost:9000 (admin/admin)
```

## Pruebas y Calidad de Código

### Configuración de Cobertura de Código

El proyecto está configurado con **JaCoCo** para generar reportes de cobertura en proyectos multi-módulo:

#### Configuración en POM padre (`pom.xml`)
```xml
<properties>
    <jacoco.version>0.8.10</jacoco.version>
    <!-- Configuración para SonarQube multi-módulo -->
    <sonar.java.coveragePlugin>jacoco</sonar.java.coveragePlugin>
    <sonar.coverage.jacoco.xmlReportPaths>
        **/target/site/jacoco/jacoco.xml,
        **/target/site/jacoco-aggregate/jacoco.xml
    </sonar.coverage.jacoco.xmlReportPaths>
</properties>

<build>
    <plugins>
        <plugin>
            <groupId>org.jacoco</groupId>
            <artifactId>jacoco-maven-plugin</artifactId>
            <version>${jacoco.version}</version>
            <executions>
                <execution>
                    <id>prepare-agent</id>
                    <goals>
                        <goal>prepare-agent</goal>
                    </goals>
                </execution>
                <execution>
                    <id>report</id>
                    <phase>test</phase>
                    <goals>
                        <goal>report</goal>
                    </goals>
                </execution>
                <execution>
                    <id>report-aggregate</id>
                    <phase>verify</phase>
                    <goals>
                        <goal>report-aggregate</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

### Ejecutar Pruebas con Cobertura

#### Opción 1: Maven Local
```bash
# Ejecutar todas las pruebas con cobertura
cd apiFestivos
mvn clean verify

# Solo pruebas (sin agregación)
mvn clean test

# Generar reportes agregados de cobertura
mvn clean verify jacoco:report-aggregate
```

#### Opción 2: Docker
```bash
# Ejecutar todas las pruebas
docker-compose exec api-festivos mvn clean verify

# Solo pruebas unitarias
docker-compose exec api-festivos mvn test

# Ver reportes de cobertura
docker-compose exec api-festivos find . -name "jacoco.xml" -type f
```

### Ubicación de Reportes de Cobertura

Los reportes se generan en las siguientes ubicaciones:

```
apiFestivos/
├── aplicacion/target/site/jacoco/          # Reporte individual del módulo aplicacion
├── presentacion/target/site/jacoco/        # Reporte individual del módulo presentacion
├── aplicacion/target/site/jacoco-aggregate/ # Reporte agregado desde aplicacion
├── presentacion/target/site/jacoco-aggregate/ # Reporte agregado desde presentacion
└── target/site/jacoco-aggregate/           # Reporte agregado principal
```

**Archivos importantes:**
- `jacoco.xml` - Reporte en formato XML para SonarQube
- `index.html` - Reporte visual HTML
- `jacoco.exec` - Datos de ejecución binarios

### Análisis con SonarQube

#### 1. Configuración Inicial de SonarQube

**Primera configuración:**
```bash
# Levantar SonarQube
docker-compose up -d sonarqube

# Esperar inicialización (2-3 minutos)
docker-compose logs -f sonarqube

# Acceder a la interfaz web
# URL: http://localhost:9000
# Usuario: admin
# Contraseña: admin (cambiar en primer acceso)
```

#### 2. Configurar Proyecto en SonarQube

1. **Crear nuevo proyecto:**
   - Acceder a http://localhost:9000
   - Click en "Create Project" → "Manually"
   - Project key: `festivos-api`
   - Display name: `API Festivos`

2. **Generar token:**
   - Click en "Generate Token"
   - Nombre: `festivos-api-token`
   - Copiar y guardar el token generado

#### 3. Ejecutar Análisis de SonarQube

**Con Maven local:**
```bash
cd apiFestivos

# Ejecutar análisis completo con cobertura
mvn clean verify sonar:sonar \
  -Dsonar.projectKey=festivos-api \
  -Dsonar.projectName="API Festivos" \
  -Dsonar.projectVersion=1.0 \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=TU_TOKEN_AQUI
```

**Con Docker:**
```bash
# Ejecutar análisis desde el contenedor
docker-compose exec api-festivos mvn clean verify sonar:sonar \
  -Dsonar.projectKey=festivos-api \
  -Dsonar.projectName="API Festivos" \
  -Dsonar.projectVersion=1.0 \
  -Dsonar.host.url=http://sonarqube:9000 \
  -Dsonar.token=TU_TOKEN_AQUI
```

**Usando variables de entorno:**
```bash
# Configurar variables
export SONAR_TOKEN=tu_token_aqui
export SONAR_PROJECT_KEY=festivos-api

# Ejecutar análisis
mvn clean verify sonar:sonar \
  -Dsonar.projectKey=$SONAR_PROJECT_KEY \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=$SONAR_TOKEN
```

#### 4. Interpretar Resultados

**Métricas principales:**
- **Coverage**: Porcentaje de código cubierto por pruebas
- **Lines of Code**: Líneas de código analizadas
- **Bugs**: Problemas que pueden causar errores
- **Vulnerabilities**: Problemas de seguridad
- **Code Smells**: Problemas de mantenibilidad
- **Duplications**: Código duplicado

**Acceder a resultados:**
- Dashboard: http://localhost:9000/dashboard?id=festivos-api
- Ver detalles por módulo, archivo y línea
- Métricas históricas y tendencias

### Integración Continua

#### Script de Análisis Automatizado

Crear archivo `scripts/analyze.sh`:
```bash
#!/bin/bash
set -e

echo "🚀 Iniciando análisis de código..."

# Ejecutar pruebas con cobertura
echo "📋 Ejecutando pruebas con cobertura..."
mvn clean verify

# Verificar que los reportes existen
echo "🔍 Verificando reportes de cobertura..."
find . -name "jacoco.xml" -type f

# Ejecutar análisis de SonarQube
echo "📊 Ejecutando análisis de SonarQube..."
mvn sonar:sonar \
  -Dsonar.projectKey=festivos-api \
  -Dsonar.projectName="API Festivos" \
  -Dsonar.projectVersion=1.0 \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=${SONAR_TOKEN}

echo "✅ Análisis completado. Ver resultados en: http://localhost:9000"
```

#### Makefile Actualizado

```makefile
# Análisis de código
.PHONY: test-coverage sonar analyze

test-coverage: ## Ejecutar pruebas con cobertura
	cd apiFestivos && mvn clean verify

sonar: ## Ejecutar análisis de SonarQube
	cd apiFestivos && mvn sonar:sonar \
		-Dsonar.projectKey=festivos-api \
		-Dsonar.host.url=http://localhost:9000 \
		-Dsonar.token=${SONAR_TOKEN}

analyze: test-coverage sonar ## Ejecutar análisis completo (pruebas + SonarQube)
```

### Solución de Problemas

#### Cobertura en 0.0%

Si SonarQube muestra 0% de cobertura:

1. **Verificar reportes generados:**
   ```bash
   find apiFestivos -name "jacoco.xml" -type f
   find apiFestivos -name "jacoco.exec" -type f
   ```

2. **Verificar configuración de rutas:**
   ```bash
   # Verificar en logs de SonarQube
   grep -i "jacoco" apiFestivos/target/sonar/report-task.txt
   ```

3. **Regenerar reportes:**
   ```bash
   cd apiFestivos
   mvn clean verify
   mvn jacoco:report-aggregate
   ```

#### SonarQube no encuentra reportes

1. **Verificar configuración en POM:**
   ```xml
   <sonar.coverage.jacoco.xmlReportPaths>
       **/target/site/jacoco/jacoco.xml,
       **/target/site/jacoco-aggregate/jacoco.xml
   </sonar.coverage.jacoco.xmlReportPaths>
   ```

2. **Usar rutas absolutas:**
   ```bash
   mvn sonar:sonar -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco-aggregate/jacoco.xml
   ```

#### Problemas de Memoria

Si SonarQube falla por memoria:
```bash
# Aumentar memoria de Docker
# Docker Desktop → Settings → Resources → Memory: 4GB+

# Verificar memoria disponible
docker stats sonarqube
```

### Métricas de Calidad Recomendadas

**Objetivos de cobertura:**
- **Cobertura mínima**: 80%
- **Cobertura objetivo**: 90%
- **Cobertura crítica**: 95% (servicios core)

**Umbrales de calidad:**
- **Bugs**: 0
- **Vulnerabilities**: 0
- **Code Smells**: < 10 por 1000 líneas
- **Duplications**: < 3%

## Comandos Útiles

### Usando Makefile (Linux/Mac/WSL)
```bash
make help        # Ver todos los comandos
make build       # Construir imágenes
make up          # Levantar servicios
make down        # Detener servicios
make test        # Ejecutar pruebas
make test-coverage # Ejecutar pruebas con cobertura
make sonar       # Análisis de SonarQube
make analyze     # Análisis completo (pruebas + SonarQube)
make logs        # Ver logs de la API
make clean       # Limpiar todo
```

### Usando Docker Compose directamente
```bash
# Construir imágenes
docker-compose build

# Levantar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f api-festivos

# Ejecutar pruebas con cobertura
docker-compose exec api-festivos mvn clean verify

# Ejecutar análisis de SonarQube
docker-compose exec api-festivos mvn sonar:sonar \
  -Dsonar.projectKey=festivos-api \
  -Dsonar.host.url=http://sonarqube:9000 \
  -Dsonar.token=TU_TOKEN

# Detener servicios
docker-compose down

# Limpiar volúmenes
docker-compose down -v
```

## Endpoints de la API

### Países
- `GET /pais` - Listar todos los países
- `GET /pais/{id}` - Obtener país por ID

### Tipos de Festivo
- `GET /tipo` - Listar todos los tipos
- `GET /tipo/{id}` - Obtener tipo por ID

### Festivos
- `GET /festivo` - Listar todos los festivos
- `GET /festivo/{id}` - Obtener festivo por ID
- `GET /festivo/verificar/{año}/{mes}/{dia}` - Verificar si una fecha es festivo

## Base de Datos

### Conexión Local
```
Host: localhost
Puerto: 5432
Base de datos: festivos
Usuario: postgres
Contraseña: sa
```

### Estructura
- **Tipo**: Tipos de festivos (Fijo, Ley Puente, etc.)
- **Pais**: Países disponibles
- **Festivo**: Festivos por país con reglas de cálculo

## Troubleshooting

### La API no se conecta a la base de datos
```bash
# Verificar que PostgreSQL esté ejecutándose
docker-compose ps postgres

# Ver logs de PostgreSQL
docker-compose logs postgres

# Reiniciar servicios
docker-compose restart postgres api-festivos
```

### SonarQube no responde
```bash
# SonarQube necesita tiempo para inicializar
docker-compose logs sonarqube

# Verificar memoria disponible (SonarQube necesita ~2GB RAM)
docker stats
```

### Limpiar y reiniciar todo
```bash
# Detener todo
docker-compose down -v

# Limpiar imágenes
docker system prune -f

# Reconstruir y levantar
docker-compose build --no-cache
docker-compose up -d
```

## Configuración de Desarrollo

### Variables de Entorno
Las siguientes variables se configuran automáticamente en Docker:

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/festivos
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=sa
SPRING_PROFILES_ACTIVE=docker
```

### Perfiles de Spring
- `default`: Configuración local
- `docker`: Configuración para contenedores

## Monitoreo

### Health Checks
- API: http://localhost:8080/actuator/health
- Base de datos: Verificación automática en Docker Compose

### Logs
```bash
# Todos los servicios
docker-compose logs

# Solo la API
docker-compose logs api-festivos

# Seguir logs en tiempo real
docker-compose logs -f
```

## CI/CD con AWS CodeBuild

### Pipeline de Integración Continua

El proyecto incluye un pipeline completo de CI/CD usando **AWS CodeBuild** que automatiza:

- ✅ **Pruebas unitarias** con Maven
- ✅ **Cobertura de código** con JaCoCo
- ✅ **Construcción de imagen Docker**
- ✅ **Push a Amazon ECR**
- ✅ **Generación de artefactos** para deployment

### Estructura del Pipeline

```
ci/
└── buildspec-backend.yml    # Configuración de AWS CodeBuild
```

### Configuración del Buildspec

#### Variables de Entorno Requeridas

Configurar en **AWS CodeBuild Environment Variables**:

```bash
# Variables de ECR (requeridas)
AWS_ACCOUNT_ID=123456789012
AWS_DEFAULT_REGION=us-east-1
IMAGE_REPO_NAME=festivos-api

# Variables opcionales
SONAR_HOST_URL=https://sonarcloud.io
```

#### Variables en AWS Parameter Store

Para análisis de SonarQube (opcional):
```bash
/festivos-api/sonar/token = squ_1234567890abcdef...
```

### Fases del Pipeline

#### 📦 **Install Phase**
```yaml
runtime-versions:
  java: corretto17
  docker: 20
```
- Instala Java 17 (Amazon Corretto)
- Configura Docker 20
- Verifica versiones de herramientas

#### 🔧 **Pre-build Phase**
- **Genera IMAGE_TAG único**: `{commit-hash}-{timestamp}`
  ```bash
  # Ejemplo: a1b2c3d4-20250810-143022
  IMAGE_TAG=${CODEBUILD_RESOLVED_SOURCE_VERSION:0:8}-$(date +%Y%m%d-%H%M%S)
  ```
- **Login automático a ECR**:
  ```bash
  aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin
  ```
- Configura URIs dinámicamente

#### 🏗️ **Build Phase**
1. **Ejecuta pruebas con cobertura**:
   ```bash
   mvn clean verify -B
   ```

2. **Genera artefactos**:
   ```bash
   mvn package -DskipTests
   ```

3. **Construye imagen Docker**:
   ```bash
   docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
   docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $IMAGE_URI
   ```

#### 🚀 **Post-build Phase**
1. **Push a Amazon ECR**:
   ```bash
   docker push $IMAGE_URI
   docker push $REPOSITORY_URI:latest
   ```

2. **Genera `imagedefinitions.json`**:
   ```json
   [
     {
       "name": "festivos-api-container",
       "imageUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/festivos-api:a1b2c3d4-20250810-143022"
     }
   ]
   ```

3. **Genera metadata del build**:
   ```json
   {
     "buildId": "festivos-api:12345",
     "sourceVersion": "a1b2c3d4...",
     "imageTag": "a1b2c3d4-20250810-143022",
     "imageUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/festivos-api:a1b2c3d4-20250810-143022",
     "timestamp": "2025-08-10T19:30:22Z"
   }
   ```

### Reportes y Artefactos

#### Reportes Automáticos
- **JUnit Tests**: `**/target/surefire-reports/TEST-*.xml`
- **JaCoCo Coverage**: `**/target/site/jacoco/jacoco.xml`

#### Artefactos Generados
- `imagedefinitions.json` - Para ECS deployment
- `build-metadata.json` - Metadata del build  
- `target/site/jacoco-aggregate/**/*` - Reportes de cobertura

#### Cache Optimizado
```yaml
cache:
  paths:
    - '/root/.m2/**/*'        # Dependencias Maven
    - 'apiFestivos/target/**/*' # Artefactos compilados
```

### Configuración en AWS

#### 1. Crear Repositorio ECR

```bash
# Crear repositorio
aws ecr create-repository --repository-name festivos-api

# Verificar repositorio
aws ecr describe-repositories --repository-names festivos-api
```

#### 2. Configurar CodeBuild Project

**Configuración básica**:
- **Source**: GitHub/CodeCommit con `ci/buildspec-backend.yml`
- **Environment**: 
  - Compute: `BUILD_GENERAL1_MEDIUM` (3 GB RAM, 2 vCPUs)
  - Image: `aws/codebuild/amazonlinux2-x86_64-standard:5.0`
  - Service role: Con permisos ECR y Parameter Store

**Permisos IAM requeridos**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:GetAuthorizationToken",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/festivos-api/*"
    }
  ]
}
```

#### 3. Configurar Pipeline Completo

**CodePipeline stages**:
1. **Source**: GitHub/CodeCommit
2. **Build**: CodeBuild (usa `buildspec-backend.yml`)
3. **Deploy**: ECS usando `imagedefinitions.json`

### Comandos de Desarrollo

#### Simular Pipeline Localmente

```bash
# Simular build completo
make aws-build

# Ejecutar solo pruebas con cobertura
make test-coverage

# Análisis completo local
make analyze
```

#### Verificar Configuración

```bash
# Verificar buildspec syntax
aws codebuild batch-get-builds --ids <build-id>

# Ver logs de build
aws logs get-log-events --log-group-name /aws/codebuild/festivos-api

# Verificar imágenes en ECR
aws ecr list-images --repository-name festivos-api
```

### Integración con ECS

#### Task Definition Ejemplo

```json
{
  "family": "festivos-api-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "festivos-api-container",
      "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/festivos-api:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "SPRING_PROFILES_ACTIVE",
          "value": "aws"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/festivos-api",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### Monitoreo del Pipeline

#### CloudWatch Metrics
- **Build Duration**: Tiempo de ejecución del build
- **Build Success Rate**: Porcentaje de builds exitosos
- **Test Results**: Resultados de pruebas unitarias

#### Notificaciones
Configurar SNS/Slack para notificar:
- ✅ Build exitoso
- ❌ Build fallido
- 📊 Reportes de cobertura

### Mejores Prácticas

#### Optimización de Performance
- **Cache de dependencias Maven**: Reduce tiempo de build en ~60%
- **Multi-stage builds**: Imágenes Docker más ligeras
- **Parallel testing**: Ejecutar pruebas en paralelo

#### Seguridad
- **Secrets en Parameter Store**: No hardcodear tokens
- **IAM roles específicos**: Principio de menor privilegio
- **Scan de vulnerabilidades**: Integrar con Amazon Inspector

#### Calidad de Código
- **Gates de calidad**: Fallar build si cobertura < 80%
- **Análisis estático**: Integración con SonarQube/SonarCloud
- **Pruebas de seguridad**: SAST/DAST automatizado

### Troubleshooting Pipeline

#### Build Falla en Tests
```bash
# Ver reportes detallados
aws codebuild batch-get-build-batches --ids <build-id>

# Descargar logs
aws logs filter-log-events --log-group-name /aws/codebuild/festivos-api
```

#### Push a ECR Falla
```bash
# Verificar permisos
aws ecr get-authorization-token

# Verificar repositorio existe
aws ecr describe-repositories --repository-names festivos-api
```

#### Imagen No Se Actualiza en ECS
```bash
# Verificar imagedefinitions.json
cat imagedefinitions.json

# Forzar deployment
aws ecs update-service --cluster <cluster> --service <service> --force-new-deployment
```

## Migración a AWS RDS

### Configuración para Producción en AWS

Para el deployment en AWS, la API utiliza **Amazon RDS PostgreSQL** en lugar de la base de datos containerizada. Esto proporciona:

- ✅ **Alta disponibilidad** y backup automático
- ✅ **Escalabilidad** automática de storage
- ✅ **Seguridad** con encryption y VPC isolation
- ✅ **Monitoreo** con CloudWatch y Performance Insights

### Estructura de Archivos AWS

```
infrastructure/
├── rds-cloudformation.yml     # CloudFormation para RDS
├── ecs-task-definition.json   # Task Definition para ECS
└── ecs-task-definition-dev.json # Generado automáticamente

scripts/
└── deploy-aws.sh              # Script de deployment

apiFestivos/presentacion/src/main/resources/
└── application-aws.properties # Configuración para AWS
```

### Configuración de Spring Boot para AWS

El perfil `aws` está configurado para conectarse a RDS:

```properties
# application-aws.properties
spring.profiles.active=aws
spring.datasource.url=${RDS_DB_URL}
spring.datasource.username=${RDS_DB_USERNAME}
spring.datasource.password=${RDS_DB_PASSWORD}

# Pool de conexiones optimizado para RDS
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000

# SSL habilitado para RDS
spring.datasource.hikari.data-source-properties.ssl=true
spring.datasource.hikari.data-source-properties.sslmode=require
```

### Despliegue Inicial en AWS

#### 1. Prerequisitos

```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
```

#### 2. Ejecutar Script de Deployment

```bash
# Hacer script ejecutable
chmod +x scripts/deploy-aws.sh

# Desplegar ambiente de desarrollo
./scripts/deploy-aws.sh dev

# Desplegar ambiente de producción
./scripts/deploy-aws.sh prod
```

#### 3. ¿Qué hace el script?

1. **Verifica credenciales AWS** y obtiene Account ID
2. **Crea repositorio ECR** si no existe
3. **Despliega stack RDS** usando CloudFormation
4. **Ejecuta scripts DDL/DML** en la nueva base de datos
5. **Genera Task Definition** con variables actualizadas
6. **Crea CloudWatch Log Group** para ECS

### Infraestructura como Código

#### CloudFormation para RDS

El template crea automáticamente:

- **RDS PostgreSQL 15.4** con encryption habilitada
- **Subnet Group** en subnets privadas (multi-AZ)
- **Security Groups** con acceso restringido
- **Secrets Manager** para credenciales
- **Enhanced Monitoring** y Performance Insights

**Características principales:**
```yaml
Resources:
  DBInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      Engine: postgres
      EngineVersion: '15.4'
      DBInstanceClass: db.t3.micro
      StorageEncrypted: true
      BackupRetentionPeriod: 7
      EnablePerformanceInsights: true
```

#### ECS Task Definition

La Task Definition incluye:

- **Fargate deployment** (512 CPU, 1024 MB memory)
- **Variables de entorno** para Spring Boot
- **Secrets desde Secrets Manager** para RDS
- **Health checks** automáticos
- **CloudWatch logging**

```json
{
  "environment": [
    {"name": "SPRING_PROFILES_ACTIVE", "value": "aws"}
  ],
  "secrets": [
    {
      "name": "RDS_DB_URL",
      "valueFrom": "arn:aws:secretsmanager:...:secret:dev/festivos-api/database:url::"
    }
  ]
}
```

### Variables de Entorno AWS

#### En CodeBuild
```bash
# Variables requeridas en CodeBuild Environment
AWS_ACCOUNT_ID=123456789012
AWS_DEFAULT_REGION=us-east-1
IMAGE_REPO_NAME=festivos-api
```

#### En Secrets Manager
El CloudFormation crea automáticamente:
```bash
# Secret: /dev/festivos-api/database
{
  "username": "festivos_user",
  "password": "tu_password_seguro",
  "host": "festivos-rds.cluster-xxx.amazonaws.com",
  "port": 5432,
  "dbname": "festivos",
  "url": "jdbc:postgresql://festivos-rds.cluster-xxx.amazonaws.com:5432/festivos"
}
```

### Pipeline CI/CD Completo

#### Buildspec Actualizado

El `buildspec-backend.yml` ahora incluye:

```yaml
secrets-manager:
  RDS_DB_PASSWORD: /dev/festivos-api/database:password
  RDS_DB_URL: /dev/festivos-api/database:url
  RDS_DB_USERNAME: /dev/festivos-api/database:username
```

#### Pipeline Stages

1. **Source**: GitHub/CodeCommit trigger
2. **Build**: CodeBuild con tests + Docker build
3. **Deploy**: ECS usando `imagedefinitions.json`

### Monitoreo en AWS

#### CloudWatch Dashboards

Métricas automáticas disponibles:
- **RDS**: CPU, memoria, conexiones, I/O
- **ECS**: CPU, memoria, tareas en ejecución
- **Application**: Logs estructurados con Spring Boot

#### Alertas Recomendadas

```bash
# Crear alertas CloudWatch
aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-CPU-High" \
  --alarm-description "RDS CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

### Seguridad en AWS

#### Network Security
- **VPC isolation**: RDS en subnets privadas
- **Security Groups**: Solo puerto 5432 desde ECS
- **SSL/TLS**: Conexiones encriptadas obligatorias

#### Secrets Management
- **AWS Secrets Manager**: Credenciales rotadas automáticamente
- **IAM roles**: Acceso granular por servicio
- **Parameter Store**: Configuración no sensible

#### Compliance
- **Encryption**: En tránsito y en reposo
- **Backups**: Automatizados con retention de 7 días
- **Monitoring**: All API calls logged en CloudTrail

### Costos Estimados (us-east-1)

#### Desarrollo
- **RDS db.t3.micro**: ~$13/mes
- **ECS Fargate**: ~$6/mes (0.5 vCPU, 1GB)
- **ECR storage**: ~$1/mes
- **CloudWatch logs**: ~$2/mes
- **Total**: ~$22/mes

#### Producción
- **RDS db.t3.small**: ~$26/mes
- **ECS Fargate**: ~$12/mes (1 vCPU, 2GB)
- **Load Balancer**: ~$16/mes
- **Total**: ~$54/mes

### Comandos de Gestión AWS

#### Verificar Deployment
```bash
# Estado del stack RDS
aws cloudformation describe-stacks --stack-name festivos-rds-dev

# Estado del servicio ECS
aws ecs describe-services --cluster festivos-cluster --services festivos-api

# Logs de la aplicación
aws logs get-log-events --log-group-name /ecs/festivos-api
```

#### Troubleshooting
```bash
# Conectar a RDS directamente
aws rds describe-db-instances --db-instance-identifier dev-festivos-db

# Verificar secrets
aws secretsmanager get-secret-value --secret-id dev/festivos-api/database

# Logs de CodeBuild
aws logs filter-log-events --log-group-name /aws/codebuild/festivos-api
```

#### Rollback
```bash
# Rollback de ECS service
aws ecs update-service \
  --cluster festivos-cluster \
  --service festivos-api \
  --task-definition festivos-api-task:PREVIOUS_REVISION

# Eliminar stack RDS (cuidado!)
aws cloudformation delete-stack --stack-name festivos-rds-dev
```

### Migración de Datos

#### Desde Docker a RDS
```bash
# Backup desde container local
docker exec postgres pg_dump -U postgres festivos > backup_local.sql

# Restore a RDS
psql -h your-rds-endpoint.amazonaws.com -U festivos_user -d festivos -f backup_local.sql
```

#### Estrategia Blue-Green
1. **Crear nuevo ambiente** con RDS
2. **Migrar datos** en ventana de mantenimiento
3. **Switchear tráfico** usando Route 53
4. **Verificar funcionalidad** completa
5. **Eliminar ambiente anterior**

### Próximos Pasos

Una vez deployado en AWS:

1. **Configurar dominio personalizado** con Route 53
2. **Implementar HTTPS** con ACM + ALB
3. **Setup de alertas** y dashboards
4. **Backup strategy** para disaster recovery
5. **Auto-scaling** basado en métricas
