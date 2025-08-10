# Makefile para API Festivos

.PHONY: help build up down test logs clean sonar

help: ## Mostrar ayuda
	@echo "Comandos disponibles:"
	@echo "  build    - Construir las imágenes Docker"
	@echo "  up       - Levantar todos los servicios"
	@echo "  down     - Detener todos los servicios"
	@echo "  test     - Ejecutar pruebas"
	@echo "  logs     - Ver logs de la API"
	@echo "  sonar    - Ejecutar análisis de SonarQube"
	@echo "  clean    - Limpiar contenedores y volúmenes"

build: ## Construir las imágenes Docker
	docker-compose build --no-cache

up: ## Levantar todos los servicios
	docker-compose up -d postgres sonarqube
	@echo "Esperando a que los servicios estén listos..."
	sleep 30
	docker-compose up -d api-festivos

down: ## Detener todos los servicios
	docker-compose down

test: ## Ejecutar pruebas en la API
	docker-compose exec api-festivos mvn test

logs: ## Ver logs de la API
	docker-compose logs -f api-festivos

sonar: ## Ejecutar análisis de SonarQube
	@echo "Ejecutando pruebas y generando reportes..."
	docker-compose exec api-festivos mvn clean test jacoco:report
	@echo "Ejecutando análisis de SonarQube..."
	docker-compose --profile analysis up sonar-scanner

clean: ## Limpiar contenedores y volúmenes
	docker-compose down -v
	docker system prune -f
