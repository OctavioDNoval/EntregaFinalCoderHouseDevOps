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
