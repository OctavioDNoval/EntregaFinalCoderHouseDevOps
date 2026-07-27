# FinOps — Gestión de Costos en AWS

## ¿Qué es FinOps?

FinOps (Financial Operations) es un marco operativo y una práctica cultural que combina **finanzas**, **ingeniería** y **negocios** para tomar decisiones informadas sobre el gasto en cloud. Se organiza en 3 fases iterativas:

```
  ┌─────────────────────────────────────────────────┐
  │                 FinOps Lifecycle                 │
  ├──────────┬──────────────────┬───────────────────┤
  │  INFORM  │    OPTIMIZE      │     OPERATE       │
  │          │                  │                   │
  │ ¿Qué     │ ¿Cómo reducir    │ ¿Cómo mantener    │
  │ gastamos?│ el gasto?        │ el control?       │
  │          │                  │                   │
  │• Tags    │• Auto-shutdown   │• Budgets          │
  │• Cost    │• Right-sizing    │• Alertas          │
  │  Explorer│• Spot instances  │• Reportes         │
  └──────────┴──────────────────┴───────────────────┘
```

---

## 1. INFORM — Visibilidad con Tags

Todos los recursos de AWS creados por Terraform tienen los siguientes **tags de cost allocation**:

| Tag | Valor | Propósito |
|---|---|---|
| `Environment` | `dev` | Identifica el entorno (dev/staging/prod) |
| `Project` | `todo-api` | Agrupa costos por proyecto |
| `Owner` | *(configurable)* | Responsable del recurso |
| `ManagedBy` | `Terraform` | Origen del recurso |

**Recursos etiquetados:**

| Recurso | Tag Name adicional |
|---|---|
| EC2 Instance | `todo-api-ec2` |
| Security Group | `todo-api-ec2-sg` |
| Elastic IP | `todo-api-eip` |
| Key Pair | `todo-api-key` |

> 💡 **Cómo visualizar costos por tag:**  
> AWS Console → **Cost Explorer** → `Group by: Tag (Project)`  
> O filtrar por `Environment: dev` para ver solo este entorno.

---

## 2. OPTIMIZE — Auto-shutdown con EventBridge Scheduler

### Arquitectura

```
EventBridge Scheduler                   IAM Role
┌────────────────────────┐             ┌─────────────────────┐
│ 08:00 LU-VIE           │── start ──► │ ec2:StartInstances  │──► EC2 i-xxx
│ cron(0 8 ? * MON-FRI *)│             │ ec2:StopInstances   │
│ 20:00 LU-VIE           │── stop ───► └─────────────────────┘
│ cron(0 20 ? * MON-FRI *)│
│ Zone: America/Arg/BsAs │
└────────────────────────┘
```

### Horario

| Días | Encendido | Apagado |
|---|---|---|
| Lunes a Viernes | 08:00 ART | 20:00 ART |
| Sábado y Domingo | Apagado | Apagado |

### Cómo se comporta la app cuando la EC2 vuelve a iniciar

El `user_data` de Terraform configura un servicio **systemd** (`app.service`) con:
```
Restart=always
WantedBy=multi-user.target
```

Cuando la EC2 arranca, systemd inicia automáticamente el servicio → ejecuta `docker compose up` → la API y el monitoreo se levantan solos.

### Ahorro estimado

| Métrica | 24/7 (sin scheduler) | Solo horario laboral |
|---|---|---|
| Horas/mes | 730 | ~260 |
| Costo EC2 t3.micro | ~$8.47/mes | ~$3.01/mes |
| **Ahorro** | — | **~64%** |

---

## 3. OPERATE — Budgets y control

### Presupuesto recomendado (AWS Budgets)

Configurar en AWS Console:  
**AWS Budgets → Create budget → Cost budget**

| Campo | Valor sugerido |
|---|---|
| Period | Monthly |
| Budget amount | $15 USD |
| Budget scope | Tag: `Project` = `todo-api` |
| Alert threshold | 80% y 100% |

Esto envía una alerta por email si el gasto del proyecto supera los $12 o $15 en el mes.

### Recomendaciones de ahorro adicional

| Estrategia | Ahorro estimado | Cuándo aplica |
|---|---|---|
| **Reserved Instance** (1 año, parcial por adelantado) | ~30% | Si corre 24/7 por +6 meses |
| **Spot Instance** | ~60-70% | Si es tolerante a interrupciones |
| **Graviton (t4g)** | ~20% | Si la app es compatible con ARM |

---

## 4. Desglose de costos mensual estimado

| Recurso | Configuración | Costo estimado |
|---|---|---|
| EC2 t3.micro | 2 vCPU, 1 GB RAM, on-demand us-east-1 | **$8.47/mes** |
| Elastic IP | Asociada a instancia en ejecución | **$0.00/mes** |
| Data Transfer | Salida estimada ~1 GB | **~$0.09/mes** |
| EventBridge Scheduler | 2 schedules básicos | **$0.00/mes** |
| **Total 24/7** | | **~$8.56/mes** |
| **Total con auto-shutdown** (~260h/mes) | | **~$3.05/mes** |

> Los precios son referenciales a us-east-1, Julio 2026.  
> Verificar en https://aws.amazon.com/ec2/pricing/on-demand/

---

## 5. Comandos útiles

```bash
# Ver costo del mes actual por recurso (CLI)
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE

# Ver etiquetas aplicadas a la EC2
aws ec2 describe-tags --filters "Name=resource-id,Values=$(terraform output -raw ec2_public_ip | xargs -I{} aws ec2 describe-instances --filters Name=ip-address,Values={} --query 'Reservations[0].Instances[0].InstanceId' --output text)"

# Ver schedules de EventBridge
aws scheduler list-schedules --group-name default
```
