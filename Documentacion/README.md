# Entrega Final CoderHouse DevOps — TO-DO API

API REST para gestión de tareas (TO-DO) desarrollada con Spring Boot 3.4.4 y SQLite. Incluye contenedorización con Docker, orquestación con Kubernetes, infraestructura como código con Terraform, pipeline CI/CD con GitHub Actions, y monitoreo con Prometheus + Grafana.

---

## Stack

| Componente | Tecnología | Puerto |
|---|---|---|
| API | Spring Boot 3.4.4 + Java 17 | `:8080` |
| Base de datos | SQLite (archivo local) | — |
| Contenedores | Docker + Docker Compose | — |
| Orquestación | Kubernetes (minikube / kind / EKS) | — |
| Infraestructura | Terraform (AWS EC2) | — |
| CI/CD | GitHub Actions | — |
| Monitoreo | Prometheus + Grafana | — |

---

## Estructura del proyecto

```
.
├── back/                          # API Spring Boot
│   ├── Dockerfile                 #   Multi-stage (Maven → JRE)
│   ├── pom.xml                    #   Dependencias (SQLite, JPA, Web)
│   └── src/
│       ├── main/
│       │   ├── java/.../demo/
│       │   │   ├── DemoApplication.java
│       │   │   ├── controller/
│       │   │   │   ├── HealthController.java      # GET /api/health
│       │   │   │   └── TareaController.java       # CRUD /api/tareas
│       │   │   ├── model/Tarea.java               # Entidad JPA
│       │   │   ├── repository/TareaRepository.java
│       │   │   └── service/TareaService.java
│       │   └── resources/application.properties    # SQLite config
│       └── test/
├── docker-compose.yml             # Entorno local (API + SQLite)
├── k8s/                           # Manifiestos Kubernetes
│   ├── 01-namespace.yml
│   ├── 03-backend-deployment.yml  #   Deployment con emptyDir
│   ├── 04-backend-service.yml
│   ├── 05-backend-hpa.yml
│   └── 06-ingress.yml
├── infraestructura/               # Terraform (AWS EC2 + Docker)
│   ├── versions.tf                #   providers (aws, tls, local)
│   ├── variables.tf               #   variables de entrada
│   ├── main.tf                    #   data sources + modules
│   ├── outputs.tf                 #   api_url, ec2_public_ip, ssh
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── security/              #   Security Group (SSH + API)
│       └── compute/               #   EC2 + EIP + user_data (Docker)
├── .github/workflows/ci.yml       # Pipeline CI/CD
└── Documentacion/README.md        # Esta documentación
```

---

## Endpoints de la API

| Método | Ruta | Descripción | Status |
|---|---|---|---|
| GET | `/api/health` | Health check | 200 |
| GET | `/api/tareas` | Listar todas las tareas | 200 |
| GET | `/api/tareas/{id}` | Obtener una tarea | 200 |
| POST | `/api/tareas` | Crear una tarea | 201 |
| PUT | `/api/tareas/{id}` | Actualizar una tarea | 200 |
| DELETE | `/api/tareas/{id}` | Eliminar una tarea | 204 |

### Modelo Tarea

```json
{
  "id": 1,
  "nombre": "Mi tarea",
  "descripcion": "Descripción de la tarea",
  "completada": false
}
```

---

## Cómo ejecutar localmente

### Requisitos

- Docker Desktop instalado y corriendo

### 1. Clonar el repositorio

```bash
git clone <URL_DEL_REPO>
cd EntregaFinalCoderHouseDevOps
```

### 2. Levantar la API

```bash
docker compose up --build
```

Esto construye la imagen y levanta el contenedor. La API queda disponible en `http://localhost:8080`.

### 3. Verificar

```bash
curl http://localhost:8080/api/health
# {"status":"OK","service":"EntregaFinal Backend"}

curl http://localhost:8080/api/tareas
# []

curl -X POST http://localhost:8080/api/tareas \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Test","descripcion":"Prueba","completada":false}'
```

### 4. Detener

```bash
docker compose down
```

Para eliminar también la base de datos SQLite:

```bash
docker compose down -v
```

---

## Despliegue en Kubernetes

### Prerrequisitos

- Cluster Kubernetes (Minikube, kind, k3s, o uno en la nube)
- `kubectl` configurado
- metrics-server instalado (para HPA)
- NGINX Ingress Controller instalado

#### Minikube

```bash
minikube start
minikube addons enable metrics-server
minikube addons enable ingress
```

#### kind

```bash
kind create cluster
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml
```

### Cargar la imagen

```bash
# Minikube
minikube image load todo-api:latest

# kind
kind load docker-image todo-api:latest
```

### Aplicar manifests

```bash
kubectl apply -f k8s/
```

### Verificar

```bash
kubectl get pods -n todo-app
kubectl get svc -n todo-app
kubectl get hpa -n todo-app
kubectl get ingress -n todo-app
```

### Acceder a la API

```bash
# Con Minikube
minikube service backend-service -n todo-app

# Con Ingress
kubectl get ingress -n todo-app
# Acceder a http://<INGRESS_IP>/api/tareas
```

---

## Infraestructura con Terraform (AWS)

Terraform provisiona una instancia EC2 con Docker Engine, clona el repositorio y levanta la API mediante Docker Compose con systemd.

### Arquitectura

```
                  Internet
                     │
         ┌───────────┴───────────┐
         │   Security Group EC2  │   :8080 y :22 abiertos a 0.0.0.0/0
         │   (EC2 t3.micro)      │
         │   Docker Compose      │◀── systemd (Restart=always)
         │   SQLite (/data)      │
         └───────────────────────┘
```

### Requisitos previos

| Herramienta | Verificación |
|---|---|
| Cuenta AWS | — |
| AWS CLI configurado | `aws sts get-caller-identity` |
| Terraform ≥ 1.5 | `terraform version` |

### Pasos

```bash
cd infraestructura

cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con la URL de TU repositorio

terraform init
terraform plan
terraform apply
```

Al finalizar, Terraform muestra los outputs:

- `api_url` → `http://<IP>:8080`
- `ec2_public_ip` → IP pública de la EC2
- `ssh_command` → comando SSH con la clave generada

### Limpieza

```bash
terraform destroy
```

---

## CI/CD con GitHub Actions

El pipeline se define en `.github/workflows/ci.yml` y se ejecuta automáticamente al hacer push a `main` o `master`.

### Jobs

| Job | Descripción |
|---|---|
| `build` | Compila el proyecto con Maven y sube el JAR como artifact |
| `deploy` | Se conecta por SSH a la EC2, hace `git pull` y `docker compose up --build` |

### Secrets requeridos

Configurar en GitHub → Settings → Secrets and variables → Actions:

| Secret | Descripción |
|---|---|
| `EC2_HOST` | IP pública de la EC2 |
| `EC2_SSH_KEY` | Contenido del archivo `clave.pem` generado por Terraform |

---

## Pendiente para próxima sesión

### Monitoreo con Prometheus y Grafana

> ⏳ Pendiente de implementar.

Se planea agregar:
- Dependencia `micrometer-registry-prometheus` en `pom.xml` para exponer métricas en `/actuator/prometheus`
- `docker-compose.monitoring.yml` con servicios de Prometheus y Grafana
- Config de Prometheus para scrapeo del backend
- Dashboard de Grafana con métricas de CPU, memoria, requests, etc.

### FinOps

> ⏳ Pendiente de implementar.

Se planea agregar:
- Etiquetado de recursos AWS con tags de costo (`Environment`, `Project`, `Owner`)
- Documentación de estimación de costos mensuales
- Scripts de apagado automático para entornos de prueba

---

## Evidencias para la entrega

Se recomienda capturar y adjuntar en el informe:

### Docker

1. `docker compose ps` mostrando el contenedor `Up`
2. `curl http://localhost:8080/api/health` respondiendo OK
3. `curl http://localhost:8080/api/tareas` lista de tareas
4. `docker compose logs backend` mostrando el inicio sin errores

### Kubernetes

5. `kubectl get pods -n todo-app` mostrando Pods Running
6. `kubectl get svc -n todo-app` mostrando Services
7. `kubectl get hpa -n todo-app` mostrando targets y réplicas
8. `kubectl get ingress -n todo-app` mostrando la IP
9. Prueba de curl a la API vía Ingress

### Terraform

10. `terraform init` y `terraform plan` ejecutándose sin errores
11. `terraform apply` completado con outputs visibles
12. `curl http://<IP>:8080/api/health` desde la EC2 desplegada
13. `terraform destroy` ejecutado exitosamente

### CI/CD

14. Log de GitHub Actions mostrando build y deploy exitosos
15. Captura de GitHub Actions con los jobs completados

### Monitoreo

16. Captura de Prometheus Target Discovery (endpoints activos)
17. Captura de dashboard de Grafana con métricas
18. Prueba de carga generando estrés y viendo el HPA escalar

---

## Comandos rápidos

```bash
# Local
docker compose up --build

# K8s
kubectl apply -f k8s/

# Terraform
cd infraestructura && terraform init && terraform apply

# CI/CD
git push origin main

# Logs
docker compose logs -f
kubectl logs -n todo-app -f deployment/backend-api

# Destroy
docker compose down -v
terraform destroy
kubectl delete -f k8s/
```
