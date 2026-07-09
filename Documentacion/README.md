# Entrega Final CoderHouse DevOps — TO-DO App

Aplicación TO-DO fullstack containerizada con Docker. Frontend en React + Vite, backend Spring Boot, base de datos MySQL.

## Stack

| Componente | Tecnología | Puerto |
|---|---|---|
| Frontend | React 19 + Vite + TypeScript + Nginx | `:80` |
| Backend | Spring Boot 3.4.4 + Java 17 | `:8080` |
| Base de datos | MySQL 8.0 | `:3306` (mapeado a `:3307` en host) |

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y corriendo
- Git (opcional, para clonar)

## Estructura del proyecto

```
.
├── docker-compose.yml
├── front/
│   ├── Dockerfile
│   ├── .env
│   └── src/
├── back/
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
└── README.md
```

## Cómo ejecutar

```bash
# 1. Parar MySQL local si está usando el puerto 3306
#    (o el compose ya mapea al 3307 para evitar conflicto)

# 2. Levantar todos los servicios
docker compose up -d

# 3. Verificar que los 3 contenedores estén corriendo
docker compose ps
```

**Salida esperada:**
```
NAME              IMAGE               STATUS
todo_db           mysql:8.0           Up (healthy)
todo-backend      back-backend        Up
todo-frontend     front-frontend      Up
```

### Reconstruir después de cambios

```bash
docker compose build frontend   # solo front
docker compose build backend    # solo back
docker compose up -d            # levantar con imágenes nuevas
```

### Detener todo

```bash
docker compose down
```

Si querés eliminar también los datos de la base de datos:

```bash
docker compose down -v
```

## Servicios

### db (MySQL 8.0)

- Imagen oficial `mysql:8.0`
- Crea automáticamente la base de datos `todo_db`
- Puerto host `3307` → contenedor `3306`
- Volumen `db_data` para persistencia de datos
- Healthcheck cada 10s vía `mysqladmin ping`

### backend (Spring Boot)

- Dockerfile multi-stage (build con Maven, runtime con JRE)
- Expone puerto `8080`
- Lee configuración de BD desde variables de entorno (spring.datasource.*)
- Depende del healthcheck de MySQL para no arrancar antes de tiempo

### frontend (React + Nginx)

- Dockerfile multi-stage (build con Node 24, runtime con Nginx)
- Servido en puerto `80`
- La URL de la API se configura en `front/.env` como `VITE_API_URL`
- Depende del backend

## Validación

### 1. Healthcheck del backend

```bash
curl http://localhost:8080/api/health
```

**Respuesta esperada:**
```json
{"status":"OK","service":"EntregaFinal Backend"}
```

### 2. Listar tareas (GET)

```bash
curl http://localhost:8080/api/tareas
```

**Respuesta esperada:** `[]` (array vacío si no hay tareas) o lista de tareas existentes.

### 3. Crear una tarea (POST)

```bash
curl -X POST http://localhost:8080/api/tareas \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Test","descripcion":"Prueba Docker","completada":false}'
```

**Respuesta esperada:** la tarea creada con `id` asignado.

### 4. Frontend desde el navegador

Abrir [http://localhost](http://localhost). Debería verse la interfaz TO-DO y poder agregar, completar y eliminar tareas.

### 5. Logs de servicios

```bash
docker compose logs backend     # logs del backend
docker compose logs db          # logs de MySQL
docker compose logs frontend    # logs de Nginx
docker compose logs -f          # seguir todos los logs en tiempo real
```

## Evidencias para la entrega

Se recomienda capturar:

1. `docker compose ps` mostrando los 3 servicios `Up`
2. `curl http://localhost:8080/api/health` respondiendo OK
3. Captura del navegador en `http://localhost` con la app funcionando
4. `docker compose logs backend` mostrando el inicio sin errores
5. `curl -X POST` creando una tarea y `curl` listándola después

## Variables de entorno

### Backend (definidas en docker-compose.yml)

| Variable | Valor | Descripción |
|---|---|---|
| `SPRING_DATASOURCE_URL` | `jdbc:mysql://db:3306/todo_db?...` | Conexión a MySQL vía red interna |
| `SPRING_DATASOURCE_USERNAME` | `root` | Usuario de BD |
| `SPRING_DATASOURCE_PASSWORD` | `123456` | Password de BD |

### Frontend (definidas en front/.env)

| Variable | Valor | Descripción |
|---|---|---|
| `VITE_API_URL` | `http://localhost:8080/api/tareas` | URL base de la API |

---

## Despliegue en Kubernetes

### Prerrequisitos

- Cluster Kubernetes (Minikube, kind, k3s, o uno en la nube)
- `kubectl` configurado
- **metrics-server** instalado (necesario para HPA)
- **NGINX Ingress Controller** instalado (necesario para Ingress)

#### Instalar metrics-server (Minikube)

```bash
minikube addons enable metrics-server
```

#### Instalar metrics-server (kind / otros)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

#### Instalar NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml
```

Para Minikube:

```bash
minikube addons enable ingress
```

### Cargar imágenes al cluster

Si usás Minikube:

```bash
minikube image load backend-app
minikube image load frontend-app
```

Si usás kind:

```bash
kind load docker-image backend-app
kind load docker-image frontend-app
```

### Aplicar todos los manifests

```bash
kubectl apply -f k8s/
```

Verificar que todo esté corriendo:

```bash
kubectl get pods -n todo-app
kubectl get svc -n todo-app
kubectl get hpa -n todo-app
kubectl get ingress -n todo-app
```

### Orden de creación (si se aplica uno por uno)

```bash
kubectl apply -f k8s/01-namespace.yml
kubectl apply -f k8s/02-secret.yml
kubectl apply -f k8s/03-configmap.yml
kubectl apply -f k8s/04-mysql-service-headless.yml
kubectl apply -f k8s/05-mysql-service-clusterip.yml
kubectl apply -f k8s/06-mysql-statefulset.yml
kubectl apply -f k8s/07-backend-deployment.yml
kubectl apply -f k8s/08-backend-service.yml
kubectl apply -f k8s/09-frontend-deployment.yml
kubectl apply -f k8s/10-frontend-service.yml
kubectl apply -f k8s/11-frontend-nginx-configmap.yml
kubectl apply -f k8s/12-backend-hpa.yml
kubectl apply -f k8s/13-frontend-hpa.yml
kubectl apply -f k8s/14-ingress.yml
```

### Acceder a la aplicación

Con Ingress (puerto 80 del controlador):

```bash
# Obtener la IP del Ingress Controller
kubectl get ingress -n todo-app
# Acceder desde el navegador a http://<INGRESS_IP>
```

Con Minikube:

```bash
minikube service frontend-service -n todo-app
```

Con NodePort directo:

```bash
kubectl get svc -n todo-app frontend-service
# Acceder a http://localhost:<NODE_PORT>
```

---

## HorizontalPodAutoscaler (HPA)

### archivos

| Archivo | Recurso | Mínimo | Máximo | Target CPU | Target Memoria |
|---|---|---|---|---|---|
| `k8s/12-backend-hpa.yml` | `backend-api` | 2 réplicas | 6 réplicas | 50% | 70% |
| `k8s/13-frontend-hpa.yml` | `frontend-app` | 2 réplicas | 5 réplicas | 50% | 70% |

### ¿Qué hace?

El HPA monitorea el consumo de CPU y memoria de los Pods. Cuando el uso promedio supera el target, Kubernetes crea más réplicas (hasta el máximo). Cuando baja, reduce las réplicas (hasta el mínimo).

### Verificar el HPA

```bash
kubectl get hpa -n todo-app -w
```

Salida esperada:

```
NAME               REFERENCE                 TARGETS                MINPODS   MAXPODS   REPLICAS
backend-api-hpa    Deployment/backend-api    15%/50%, 30%/70%       2          6         2
frontend-app-hpa   Deployment/frontend-app   10%/50%, 20%/70%       2          5         2
```

Para generar carga de prueba y ver el escalado:

```bash
# Instalar hey (herramienta de load testing)
# hey https://github.com/rakyll/hey

hey -n 10000 -c 50 http://localhost:8080/api/tareas
```

Mientras corre, en otra terminal:

```bash
kubectl get hpa -n todo-app -w
kubectl get pods -n todo-app -w
```

---

## Ingress

### archivo

| Archivo | Host | Path | Backend |
|---|---|---|---|
| `k8s/14-ingress.yml` | Cualquiera | `/` | `frontend-service:80` |

### ¿Qué hace?

El Ingress expone el frontend en el puerto 80 del NGINX Ingress Controller, permitiendo acceso HTTP desde fuera del cluster sin usar NodePort. El frontend internamente redirige `/api/` al backend vía el proxy de Nginx.

### Verificar el Ingress

```bash
kubectl get ingress -n todo-app
```

Salida esperada:

```
NAME               CLASS   HOSTS   ADDRESS        PORTS   AGE
frontend-ingress   nginx   *       <INGRESS_IP>   80      5m
```

Obtener la IP y acceder:

```bash
# Si usás Minikube
minikube ip

# Si usás kind / otro
kubectl get nodes -o wide
```

---

## Terraform (estructura propuesta)

> ⚠️ **Pendiente de implementación completa.** Esta sección describe la estructura planeada para aprovisionar infraestructura cloud con Terraform.

La idea es crear un módulo de Terraform que aprovisione:

```
terraform/
├── main.tf              # Provider y recursos principales
├── variables.tf         # Variables de entrada
├── outputs.tf           # Outputs (cluster endpoint, etc.)
├── modules/
│   ├── networking/      # VPC, subnets, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── kubernetes/      # Cluster K8s (EKS / AKS / GKE)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── terraform.tfvars.example   # Ejemplo de variables
```

### Recursos a provisionar

| Módulo | Recursos |
|---|---|
| **networking** | VPC, subnets pública/privada, Internet Gateway, Security Groups |
| **kubernetes** | Cluster K8s, Node Group, kubeconfig |
| **Post-deploy** | Aplicar manifests de `k8s/` con `kubectl` vía `null_resource` o `helm` |

### Comandos planeados

```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -auto-approve
terraform destroy  # Para FinOps, apagar recursos cuando no se usan
```

---

## Evidencias para la entrega

Se recomienda capturar y adjuntar en el informe:

### Docker

1. `docker compose ps` mostrando los 3 servicios `Up`
2. `curl http://localhost:8080/api/health` respondiendo OK
3. Captura del navegador en `http://localhost` con la app funcionando
4. `docker compose logs backend` mostrando el inicio sin errores

### Kubernetes

5. `kubectl get pods -n todo-app` mostrando todos los Pods Running
6. `kubectl get svc -n todo-app` mostrando todos los Services
7. `kubectl get hpa -n todo-app` mostrando targets y réplicas
8. `kubectl get ingress -n todo-app` mostrando la IP asignada
9. `kubectl describe pod -n todo-app <backend-pod>` (salida de health checks)
10. Captura del navegador accediendo vía Ingress o NodePort

### CI/CD (cuando se implemente)

11. Log de GitHub Actions mostrando build, test y deploy exitosos
12. Captura del SAST/DAST sin vulnerabilidades críticas

### Monitoreo (cuando se implemente)

13. Captura del dashboard de Grafana con métricas de los Pods
14. Captura de Prometheus Target Discovery mostrando los endpoints activos
