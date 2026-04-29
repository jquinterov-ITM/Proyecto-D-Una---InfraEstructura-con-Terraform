# Especificacion de Infraestructura - Proyecto D-Una

Este documento detalla la arquitectura de infraestructura, los recursos de nube y los pipelines de CI/CD para la plataforma Duna, basándose en el enfoque **IaC (Infrastructure as Code)**.


## 1. Estado actual (implementado)

La infraestructura desplegada hoy en AWS con Terraform incluye:
- VPC `172.16.20.0/22`.
- Subred pública (Master, NAT, ALB).
 - Subred privada App/K3s (4 workers: worker_1, worker_2, worker_3, worker_4).
- Subred privada Data/DB (RDS y EFS).
- Internet Gateway y NAT Gateway.
- Security Groups para ALB, master y workers.
- 1 nodo master K3s en subred pública (admin).
- 4 nodos worker K3s en subred privada (worker_1, worker_2, worker_3, worker_4).
- ALB (HTTP:80) con target group a workers.
- RDS PostgreSQL (Multi-AZ) y EFS en subred de datos.

---

## 2. Topologia de Red (AWS VPC)

| Recurso | Configuración | Propósito |
| :--- | :--- | :--- |
| **VPC** | `172.16.20.0/22` | Red aislada para todo el ecosistema. |
| **VPC Name (tag)** | `VPC-Duna` (cuando `env = dev`, en otros entornos `VPC-<env>`) | Etiqueta `Name` aplicada a la VPC para facilitar identificación en la consola |
| **Subnets Publicas** | 2 AZs (Multi-AZ) | Hosting de ALB y NAT Gateways. |
| **Subnets Privadas (App)** | 2 AZs | Nodos de K3s/EKS para BFFs, Monolito y Workers. |
| **Subnets Privadas (Data)** | 2 AZs | PostgreSQL (RDS) y Redis (ElastiCache). |

---

## 3. Recursos IaC por modulo Terraform

### 3.1 `modules/network`
- VPC, subredes publicas/app/data.
- Internet Gateway.
- NAT Gateway por AZ.
- Route tables y asociaciones.

### 3.2 `modules/security`
- Security Group ALB.
- Security Group Master K3s.
- Security Group Worker K3s.

### 3.3 `modules/compute`
- 1 master K3s (público).
- 4 workers K3s (privados).

Se utiliza un clúster ligero para optimizar costos mientras se mantiene la compatibilidad con K8s:
- **Ingress Controller:** NGINX Ingress para ruteo basado en host (`cliente.duna.com`, `api.duna.com`).
- **Certificados:** Cert-Manager con Let's Encrypt (HTTPS).
- **HPA (Horizontal Pod Autoscaler):** Configurado para los BFFs basado en uso de CPU (>70%).

### 3.4 `modules/load_balancer`
- ALB.
- Target Group.
- Listener HTTP (80).
- Attachments de workers al target group.

### 3.5 Base de Datos (RDS PostgreSQL)
- **Instancia:** `db.t3.medium` (MVP).
- **Configuración:** Multi-AZ activado, Cifrado con AWS KMS.
- **Acceso:** Solo permitido desde el Security Group del clúster de aplicaciones.

### 3.6 Broker de Eventos (Kafka/MSK)
- **Opción MVP:** Cluster de Kafka gestionado (Amazon MSK) o Bitnami Kafka sobre Kubernetes.
- **Tópico Principal:** `duna.orders.events` (Particiones: 3, Replicación: 2).

### 3.7 Secretos y Configuración
- **AWS Secrets Manager:** Almacena:
    - `DB_PASSWORD`
    - `KAFKA_SASL_PASSWORD`
    - `JWT_PRIVATE_KEY`
    - `SENDGRID_API_KEY`
    - `AES_ENCRYPTION_KEY` (Para PII Ley 1581).

### 3.8 `modules/storage`
- Bucket de Amazon S3 (`var.env-assets-...`).
- Políticas de acceso (`aws_s3_bucket_policy`).
- Configuración CORS (`aws_s3_bucket_cors_configuration`).
---

## 4. Arquitectura objetivo (condicional)

Recursos que se implementan cuando se suministra configuracion DNS/certificado:

- ACM + listener HTTPS (443).

Mejoras recomendadas adicionales:
- Endurecimiento de acceso administrativo (Bastion o SSM Session Manager).


---

## 5. Validacion de Terraform

Comando ejecutado en este repositorio:
- `terraform init -backend=false`
- `terraform validate`

Resultado: configuracion valida.

### Activacion fase 2 (opcional por componente)

- Estado por defecto:
    - `create_waf = true`
    - `create_rds = true`
    - `enable_https = true`
    - `create_acm_certificate = true`
    - `create_route53_record = true`
- Comportamiento seguro:
    - Si `route53_zone_id` y `route53_record_name` estan vacios, HTTPS/Route53 se omiten automaticamente.
    - Si `db_password` esta vacio, Terraform genera password aleatoria para RDS.
- Ejecucion recomendada:
    - `terraform plan -var-file=terraform.tfvars`
    - `terraform apply -var-file=terraform.tfvars`
- WAF:
    - Ya activo por defecto.
- RDS Multi-AZ:
    - Ya activo por defecto.
    - `db_password` es opcional.

---

## 6. Gaps de Infraestructura Identificados

| ID | GAP | Descripción / Riesgo |
| :--- | :--- | :--- |
| **GAP-INF-01** | **DNS/TLS** | Route53 y HTTPS dependen de definir `route53_zone_id` y `route53_record_name`. |
| **GAP-INF-02** | **Capa de Datos** | RDS esta implementado; falta definir estrategia operativa (credenciales, rotacion y backups gestionados). |
| **GAP-INF-03** | **Acceso administrativo** | No hay bastion/SSM formal para operar nodos en subred privada. |
| **GAP-INF-04** | **Observabilidad/Backups** | Falta definir monitoreo y politicas de respaldo para capa de datos. |

---

## 7. Recomendaciones de Escalabilidad
- Transicionar de K3s a **Amazon EKS** cuando el tráfico supere los 10k usuarios concurrentes.
- Implementar **Redis ElastiCache** para el caché de búsqueda (Wilson Score) y sesiones de BFF.

---

## 8. Mapeo de roles y verificación rápida

El despliegue actual define 4 workers en el clúster K3s, todos en subred privada:

 - Worker 1 — worker_1
 - Worker 2 — worker_2
 - Worker 3 — worker_3
 - Worker 4 — worker_4

Los nombres visibles en la consola EC2 (`tag:Name`) siguen el patrón `worker-<env>-<n>-<rol>` (ejemplo: `worker-dev-1-front`).

Comando útil para verificar desde tu máquina local (AWS CLI):

```bash
aws ec2 describe-instances --region us-east-1 --filters \
    "Name=tag:Name,Values=Master-*,worker-*" \
    --query "Reservations[].Instances[].{Name:Tags[?Key=='Name']|[0].Value,State:State.Name,PrivateIP:PrivateIpAddress,InstanceId:InstanceId}" \
    --output table
```

---

## 9. Diagrama (objetivo)

### 9.1 Comprobar tags y atributos desde Terraform

Además de usar AWS CLI y `jq`, puedes inspeccionar recursos y exponer valores directamente desde Terraform:

- Inspeccionar un recurso en el state:

```bash
# Muestra los atributos del primer worker (incluye tags)
terraform state show module.compute.aws_instance.worker[0]
```

- Exponer valores como outputs del módulo `compute` (ya añadidos en `modules/compute/outputs.tf`):

```hcl
output "worker_names" {
    value = [for w in aws_instance.worker : w.tags["Name"]]
}

output "worker_private_ips" {
    value = aws_instance.worker[*].private_ip
}
```

- Después de `terraform apply`, desde el root puedes mostrar los outputs del módulo (si los exportas en el root) con:

```bash
terraform output compute_worker_names
terraform output compute_worker_private_ips
```

Si no quieres exportar outputs en el root, usa `terraform state show` para leer atributos individuales.

```mermaid
flowchart TB
    classDef cloud fill:#fff,stroke:#232F3E,stroke-width:2px;
    classDef vpc fill:#fff,stroke:#3B48CC,stroke-width:2px,stroke-dasharray: 5 5;
    classDef pub fill:#e1f8e9,stroke:#2e7d32,stroke-width:1px;
    classDef priv fill:#e3f2fd,stroke:#1565c0,stroke-width:1px;
    classDef db fill:#fff3e0,stroke:#ef6c00,stroke-width:1px;
    classDef k3s fill:#326ce5,color:#fff,stroke-width:2px;

    Cliente([fa:fa-laptop Cliente Web]) -- "HTTPS:443" --> ALB

    subgraph AWS ["fa:fa-cloud AWS Cloud"]
        direction TB
        ALB[Application Load Balancer]
        subgraph VPC [VPC - 172.16.20.0/22]
            direction TB
            subgraph PUB1 [Red Pública]
                NAT1[NAT Gateway]
                M1{{Master K3s}}
            end
            subgraph PRIV1 [Red Privada K3s]
                W1[[worker_1]]
                W2[[worker_2]]
                W3[[worker_3]]
                W4[[worker_4]]
            end
            subgraph DB_SUB1 [Red de Datos]
                RDS[(RDS Postgres)]
                EFS[(EFS Storage)]
            end
            IGW[Internet Gateway]
        end
    end

    ALB ====> PUB1
    NAT1 ------> IGW
    M1 -- "Tráfico Interno" --> W1 & W2 & W3 & W4
    W1 -- "DB: 5432" --> RDS
    W2 -- "DB: 5432" --> RDS
    W3 -- "DB: 5432" --> RDS
    W4 -- "DB: 5432" --> RDS
    W1 -- "EFS" --> EFS
    W2 -- "EFS" --> EFS
    W3 -- "EFS" --> EFS
    W4 -- "EFS" --> EFS

    class AWS cloud; class VPC vpc;
    class PUB1 pub; class PRIV1 priv; class DB_SUB1 db;
    class M1,W1,W2,W3,W4 k3s;
```


