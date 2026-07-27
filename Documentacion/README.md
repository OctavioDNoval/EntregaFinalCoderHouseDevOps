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
├── monitoring/                    # Monitoreo Prometheus + Grafana
│   ├── prometheus.yml             #   Config de scrapeo
│   ├── docker-compose.monitoring.yml
│   └── grafana/provisioning/      #   Datasource + dashboards auto
├── k8s/                           # Manifiestos Kubernetes
│   ├── 01-namespace.yml
│   ├── 03-backend-deployment.yml  #   Deployment con emptyDir
│   ├── 04-backend-service.yml
│   ├── 05-backend-hpa.yml
│   ├── 06-ingress.yml
│   ├── 07-servicemonitor.yml      #   Prometheus auto-descubrimiento
│   └── 08-grafana-dashboard-configmap.yml
├── infraestructura/               # Terraform (AWS EC2 + Docker)
│   ├── versions.tf                #   providers (aws, tls, local)
│   ├── variables.tf               #   variables de entrada
│   ├── main.tf                    #   data sources + modules
│   ├── outputs.tf                 #   api_url, ec2_public_ip, ssh
│   ├── scheduler.tf               #   EventBridge auto-shutdown
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── security/              #   Security Group (SSH + API + monitoring)
│       └── compute/               #   EC2 + EIP + user_data (Docker)
├── .github/workflows/ci.yml       # Pipeline CI/CD
└── Documentacion/
    ├── README.md                  # Esta documentación
    └── FINOPS.md                  # Gestión de costos en AWS
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
- `monitoring_urls` → URLs de Prometheus y Grafana
- `shutdown_schedule` → Horario de apagado automático (dev)

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
| `deploy` | Se conecta por SSH a la EC2, hace `git pull` y reinicia `systemd` (que levanta API + monitoreo) |

### Secrets requeridos

Configurar en GitHub → Settings → Secrets and variables → Actions:

| Secret | Descripción |
|---|---|
| `EC2_HOST` | IP pública de la EC2 |
| `EC2_SSH_KEY` | Contenido del archivo `clave.pem` generado por Terraform |

---

## Funcionalidades implementadas

### ✅ Monitoreo con Prometheus y Grafana

La API expone métricas en `/actuator/prometheus` vía Micrometer. Prometheus scrapea cada 15s y Grafana visualiza con un dashboard precargado de 8 paneles (CPU, memoria, requests/s, latencia p95, errores, threads, GC, logs).

Disponible en 3 entornos:

| Entorno | Cómo se despliega |
|---|---|
| **Local** | `docker compose -f docker-compose.yml -f monitoring/docker-compose.monitoring.yml up` |
| **Kubernetes** | `helm install prometheus-stack prometheus-community/kube-prometheus-stack` + `kubectl apply -f k8s/07-servicemonitor.yml` |
| **AWS (EC2)** | Automático via `user_data.sh.tpl` (incluido en systemd) |

### ✅ FinOps — Gestión de costos en AWS

Se aplicaron las 3 fases del ciclo FinOps:

1. **Inform** — Tags de cost allocation (`Environment`, `Project`, `Owner`, `ManagedBy`) en todos los recursos AWS via `default_tags`
2. **Optimize** — Auto-shutdown con EventBridge Scheduler (apaga 20:00, enciende 08:00 ART, solo días hábiles). Ahorro estimado ~65%
3. **Operate** — Documentación en `Documentacion/FINOPS.md` con desglose de costos, budgets recomendados y estrategias de ahorro

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
# Local (solo API)
docker compose up --build

# Local (API + Monitoreo)
docker compose -f docker-compose.yml -f monitoring/docker-compose.monitoring.yml up --build

# K8s
kubectl apply -f k8s/

# K8s (monitoreo con kube-prometheus-stack)
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

# Terraform
cd infraestructura && cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tu repo URL y nombre
terraform init && terraform apply

# CI/CD
git push origin main

# Logs
docker compose logs -f
kubectl logs -n todo-app -f deployment/backend-api

# Prometheus UI
open http://localhost:9090

# Grafana
open http://localhost:3000   # admin/admin

# Destroy
docker compose down -v
terraform destroy
kubectl delete -f k8s/
helm uninstall prometheus-stack -n monitoring
```
