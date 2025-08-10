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
