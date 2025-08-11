# Dockerfile optimizado para Spring Boot API Festivos - Free Tier
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Instalar curl para health checks
RUN apk add --no-cache curl

# Crear usuario no privilegiado
RUN addgroup -S appuser && adduser -S appuser -G appuser

# Copiar el JAR ya compilado localmente
COPY presentacion/target/presentacion-*.jar app.jar

# Cambiar propietario
RUN chown appuser:appuser app.jar

USER appuser

# Exponer puerto
EXPOSE 8080

# Variables de entorno optimizadas para Free Tier
ENV JAVA_OPTS="-Xmx400m -Xms200m -XX:MaxMetaspaceSize=128m"
ENV SPRING_PROFILES_ACTIVE=aws

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Comando de inicio optimizado para contenedores
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
