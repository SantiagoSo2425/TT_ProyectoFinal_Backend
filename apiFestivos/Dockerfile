# Etapa de construcción
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copiar archivos de configuración de Maven
COPY pom.xml .
COPY dominio/pom.xml dominio/
COPY core/pom.xml core/
COPY aplicacion/pom.xml aplicacion/
COPY infraestructura/pom.xml infraestructura/
COPY presentacion/pom.xml presentacion/

# Descargar dependencias
RUN mvn dependency:go-offline -B

# Copiar código fuente
COPY dominio/src dominio/src
COPY core/src core/src
COPY aplicacion/src aplicacion/src
COPY infraestructura/src infraestructura/src
COPY presentacion/src presentacion/src

# Compilar la aplicación
RUN mvn clean package -DskipTests

# Etapa de ejecución
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Instalar curl para health checks
RUN apk add --no-cache curl

# Crear usuario no privilegiado
RUN addgroup -S appuser && adduser -S appuser -G appuser

# Copiar el JAR desde la etapa de construcción
COPY --from=build /app/presentacion/target/*.jar app.jar

# Cambiar propietario
RUN chown appuser:appuser app.jar

USER appuser

# Exponer puerto
EXPOSE 8080

# Comando de inicio
ENTRYPOINT ["java", "-jar", "app.jar"]
