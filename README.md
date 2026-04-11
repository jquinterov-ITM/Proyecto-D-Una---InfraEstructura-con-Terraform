# Proyecto D-Una — Despliegue de clúster K3s en AWS con Terraform

## Objetivo
Implementar infraestructura en AWS mediante Terraform para una arquitectura K3s de alta disponibilidad (Multi-AZ), con enfoque modular.

El alcance se divide en:
- **Estado actual (implementado):** red, seguridad, computo K3s, balanceo, WAF y capa de datos RDS.
- **Arquitectura objetivo (condicional):** HTTPS con ALB y WAF local.

## Actualizacion de cluster (Abril 2026)

- **Masters:** 1 master por cada subred privada de App/K3s.
- **Worker:** 2 workers (1 por cada subred privada App/K3s).
- **Capacidad de pods:** cada worker configurado con `max-pods=3` (kubelet).
- **IP de administracion:** masters con IP privada fija (host `.10` de cada subred App).
- **Acceso Kubernetes:** administracion recomendada por SSM tunnel + Lens (sin IP publica en master).

Detalle operativo completo: ver `implementacion.md`.

## Entrega de arquitectura

### 1) Descripcion de la infraestructura
La infraestructura propone una arquitectura de alta disponibilidad (Multi-AZ) para una aplicacion en AWS. Dentro de la VPC `172.16.20.0/22`, la red se segmenta en tres capas: publica (egreso por NAT), privada K3s (nodos master/worker) y privada de datos (reservada para RDS). Esta separacion mejora seguridad, control de trafico y resiliencia ante fallas de una zona de disponibilidad.

> Nota: en el entorno `dev` la VPC se etiqueta con `Name = VPC-Duna` (en otros entornos el tag usa el patrón `VPC-<env>`). Esto facilita identificar rápidamente la VPC en la consola de AWS.

### 2) Recursos de AWS

**Implementados en Terraform (hoy):**
- VPC personalizada con 2 subredes publicas y 4 privadas.
- Internet Gateway + 2 NAT Gateway (uno por AZ).
- Security Groups para ALB y K3s.
- EC2 para masters (uno por cada subred privada App/K3s) y 2 workers K3s.
- Application Load Balancer (ALB) con listener HTTP y target group a workers.
- AWS WAF regional asociado al ALB.
- Amazon RDS PostgreSQL Multi-AZ en subredes privadas de datos (o EC2 Standalone según configuración).

**Condicionales (se activan cuando hay DNS):**
- Certificado ACM (opcional) para habilitar tráfico HTTPS en el ALB.

**Almacenamiento (Estado actual):**
- Amazon S3 Bucket para alojamiento y persistencia de Assets y contenidos multimedia (con CORS habilitado y acceso controlado).

### 3) Diagrama (Mermaid)
> Nota: el diagrama es referencial de capas. La topologia efectiva de nodos la define la seccion "Actualizacion de cluster (Abril 2026)".


`mermaid
flowchart TB

    %% Estilos Profesionales
    classDef cloud fill:#f9f9f9,stroke:#232F3E,stroke-width:2px;
    classDef vpc fill:#fff,stroke:#3B48CC,stroke-width:2px,stroke-dasharray: 5 5;
    classDef az fill:#fff,stroke:#00A1C9,stroke-width:1px,stroke-dasharray: 5 5;
    classDef pub fill:#e1f8e9,stroke:#2e7d32,stroke-width:1px;
    classDef priv fill:#e3f2fd,stroke:#1565c0,stroke-width:1px;
    classDef db fill:#fff3e0,stroke:#ef6c00,stroke-width:1px;
    classDef k3s fill:#326ce5,color:#fff,stroke-width:2px;
    classDef admin fill:#f3e5f5,stroke:#6a1b9a,stroke-width:1px;
    classDef invisible fill:none,stroke:none,color:#232F3E,font-weight:bold,font-size:28px;
    classDef invisibleVPC fill:none,stroke:none,color:#3B48CC,font-weight:bold,font-size:20px;

    %% Usuarios / Actores Externos
    subgraph Usuarios [ ]
        direction LR
        Cliente([fa:fa-laptop Cliente])
        Proveedor([fa:fa-building Proveedor])
        Administrador([fa:fa-user-shield Administrador])
        Lens[fa:fa-desktop Lens]
    end

    Cliente & Proveedor & Administrador -- "HTTPS:443" ---> WAF[1. AWS WAF]

    subgraph AWS [" "]
        L1[fa:fa-cloud <br/> AWS <br/> Cloud]:::invisible
        L1 ~~~ WAF

        WAF --> ALB[2. AWS WAF]
        WAF --> ALB[3. Application Load Balancer]

        subgraph VPC [" "]
            L2[fa:fa-network-wired VPC <br/> 172.16.20.0/22]:::invisibleVPC

            %% AZ 1
            subgraph AZ1 [Availability Zone 1 - us-east-1a]
                subgraph PUB1 [Red Publica]
                    NAT1[NAT Gateway]
                end
                subgraph PRIV1 [Red Privada K3s]
                    M1{{Master K3s - 172.16.21.10}}
                    W1[[worker-dev-1-ppal<br/>172.16.21.58<br/>Client-BFF<br/>max-pods=3]]
                    P1[(Pod 1)]
                    P2[(Pod 2)]
                    P3[(Pod 3)]
                end
                subgraph DB_SUB1 [Red de Datos]
                    RDS_P[(RDS Primary)]
                end
            end

            %% AZ 2
            subgraph AZ2 [Availability Zone 2 - us-east-1d]
                subgraph PUB2 [Red Publica]
                    NAT2[NAT Gateway]
                end
                subgraph PRIV2 [Red Privada K3s]
                    M2{{Master K3s - 172.16.21.138}}
                    W2[[worker-dev-2-second<br/>172.16.21.183<br/>Provider-BFF<br/>max-pods=3]]
                    P4[(Pod 1)]
                    P5[(Pod 2)]
                    P6[(Pod 3)]
                end
                subgraph DB_SUB2 [Red de Datos]
                    RDS_S[(RDS Standby)]
                end
            end

            IGW[Internet Gateway]
        end

        SSM[AWS Systems Manager<br/>Session Manager]
    end

    %% Conexiones de aplicacion
    ALB --> W1
    ALB --> W2
    W1 -- "DB:5432" --> RDS_P
    W2 -- "DB:5432" --> RDS_P
    RDS_P -. "Sync" .-> RDS_S

    %% Cluster K3s
    W1 <-->|"K3s API/Node"| M1
    W2 <-->|"K3s API/Node"| M2
    M2 <-->|"Control-plane sync"| M1
    W1 --> P1
    W1 --> P2
    W1 --> P3
    W2 --> P4
    W2 --> P5
    W2 --> P6

    %% Egreso privado
    W1 -.-> NAT1
    W2 -.-> NAT2
    M1 -.-> NAT1
    M2 -.-> NAT2
    NAT1 --> IGW
    NAT2 --> IGW

    %% Administracion segura
    Lens -- "SSM Tunnel localhost:6443" --> SSM
    SSM -. "Port-forward 6443" .-> M1
    Administrador -. "AWS CLI + scripts" .-> Lens

    %% Forzar alineacion vertical
    PUB1 ~~~ PRIV1 ~~~ DB_SUB1
    PUB2 ~~~ PRIV2 ~~~ DB_SUB2

    %% Aplicacion de clases
    class AWS cloud; class VPC vpc; class AZ1,AZ2 az;
    class PUB1,PUB2 pub; class PRIV1,PRIV2 priv; class DB_SUB1,DB_SUB2 db;
    class M1,M2,W1,W2 k3s;
    class Lens,SSM admin;
``n

### Mapeo de roles por worker
- Worker 1 = Client-BFF
- Worker 2 = Provider-BFF

> Nota: la lista historica de roles se mantiene en el `user_data`; con `worker_count = 2` se utilizan los dos primeros roles.

> Nota: los `Name` tags de las instancias EC2 y el `hostname` se generan en el módulo `modules/compute` (ver `tags` y `user_data`).

> Version corta para entrega academica. El detalle tecnico completo se mantiene en `docs/diagrama-arquitectura-propuesto.md`.

## Cheat Sheet (rápido)

- Configura en `variables.tf`: `my_ip` (tu IP/32), `key_name` (llave existente en AWS) y CIDRs válidos dentro de `vpc_cidr`.

- Opciones IAM/SSM: si tu cuenta NO tiene permisos para crear roles IAM, puedes pasar un instance profile existente o dejar que Terraform no cree el rol.
  - `existing_instance_profile_name`: nombre del instance profile IAM existente para adjuntar a las EC2 (opcional).
  - `create_ec2_iam_resources`: booleano (default `false`). Si es `true`, Terraform intentará crear el rol y el instance profile (requiere permisos `iam:CreateRole`, `iam:AttachRolePolicy`, etc.).


## Arquitectura de referencia (prioridad: diagrama)
- Entrada actual: Application Load Balancer (ALB).
- Entrada objetivo: AWS WAF -> Application Load Balancer (ALB).
- VPC personalizada: `172.16.20.0/22`.
- 2 Availability Zones: `us-east-1a` y `us-east-1d`.
- Capa publica (2 subredes): NAT Gateway por AZ + salida por Internet Gateway.
- Capa privada K3s (2 subredes): masters distribuidos (1 por subred App) y 2 workers (1 por subred App) con maximo 3 pods cada uno.
- Capa privada de datos (2 subredes): reservada para RDS Primary + Standby (pendiente).
- Security Groups segmentados por capa (WAF/ALB, K3s y datos).

> Nota: para este proyecto, el diagrama en `docs/diagrama-arquitectura-propuesto.md` se toma como fuente principal de arquitectura.

## Organización del proyecto
- `main.tf`: orquesta los módulos.
- `providers.tf`: versión de Terraform/proveedor AWS y backend local.
- `variables.tf`: variables globales y configuración por entorno (`dev`).
- `terraform.tfvars`: valores recomendados para ejecución.
- `modules/network`: red base.
- `modules/security`: reglas de seguridad.
- `modules/compute`: EC2 + bootstrap K3s.
- `modules/load_balancer`: ALB y target group.
- `modules/edge`: Route53 + WAF.
- `modules/data`: RDS Multi-AZ.
- `docs/infraestructura.md`: estado implementado y pendientes de la arquitectura.
- `docs/diagrama-arquitectura-propuesto.md`: arquitectura objetivo y flujos.

## Parámetros principales (entorno dev)
- `vpc_cidr = 172.16.20.0/22`
- `pub_subnets = [172.16.20.0/25, 172.16.20.128/25]`  - capa publica/NAT (AZ1, AZ2)
- `app_subnets = [`
  - `"172.16.21.0/25", "172.16.21.128/25"`      - capa privada K3s (AZ1, AZ2)
- `]`
- `data_subnets = [`
  - `"172.16.22.0/26", "172.16.22.64/26"`       - capa privada de datos (AZ1, AZ2)
  - `]`
- `master_type = t3.medium` (referencia para nodos master)
- `worker_type = t3.large` (referencia para nodos worker)
- `master_count = length(app_subnets)` (1 master por cada subred privada App)
- `worker_count = 2`
- `worker_max_pods = 3`
- `my_ip = <IP_PUBLICA>/32` para acceso administrativo al master.
- `key_name` debe existir en AWS.

## Flujo de despliegue
0. `Acortar ruta: ` `function prompt { "PS $(Split-Path -Leaf (Get-Location))> " }`

1. `terraform init`
2. `terraform workspace select dev || terraform workspace new dev`
3. `terraform validate`
4. `terraform plan -var-file "terraform.tfvars"`
5. `terraform fmt --recursive` Para mejorar, estructurar el proyecto
6. `terraform apply -var-file "terraform.tfvars"`

## Conexion a Kubernetes (SSM + Lens)

Los scripts en `scripts/` permiten conectarte a Kubernetes sin exponer IP publica en masters:

1. Exportar kubeconfig adaptado para Lens (server en localhost)

```powershell
.\scripts\export-lens-kubeconfig.ps1
```

2. Abrir tunel SSM al API server de K3s

```powershell
.\scripts\start-lens-ssm-tunnel.ps1
```

3. Importar en Lens el archivo kubeconfig generado (ruta por defecto)

```text
C:\Users\<tu_usuario>\.kube\k3s-duna-lens.yaml
```

4. Opcional: iniciar tunel indicando Instance ID manual

```powershell
.\scripts\start-lens-ssm-tunnel.ps1 -TargetInstanceId i-xxxxxxxxxxxxxxxxx
```

Guia detallada, prerequisitos y validaciones: ver `implementacion.md`.

## Fase 2 (estado y activación)
- `create_waf = true` y `create_rds = true` están activos por defecto.
- `enable_https`, `create_acm_certificate` y `create_route53_record` también están en `true` por defecto, pero su activación efectiva depende de tener datos DNS.
- Si `route53_zone_id` y `route53_record_name` están vacíos, Terraform desactiva automáticamente ACM/HTTPS/Route53 para evitar fallos.
- Si `db_password` está vacío, Terraform genera una contraseña aleatoria para RDS.

Variables realmente necesarias:
- Despliegue base (sin dominio): no necesitas `route53_zone_id` ni `route53_record_name`.
- TLS/Route53 (solo si quieres dominio propio y HTTPS con ACM): necesitas `route53_zone_id` y `route53_record_name`.
- RDS: `db_password` es opcional.

## Flujo de limpieza
- `terraform destroy`


## Recomendaciones
- Restringir `my_ip` a la IP real del administrador.
- Evitar exposición SSH amplia en producción.
- Usar HTTPS extremo a extremo (ACM + listener 443) entre cliente y ALB.
- Mantener WAF delante del ALB como capa obligatoria de proteccion.
- Definir politicas de backup/retencion para RDS (Primary/Standby).
- Ejecutar `destroy` al finalizar pruebas para controlar costos.

## Verificación post-deploy
- terraform state list
- terraform state show module.compute.aws_instance.master_primary
- terraform state show module.compute.aws_instance.master_secondary[0]
- terraform state show module.load_balancer.aws_lb.main
- terraform state show module.edge.aws_wafv2_web_acl.main[0]
- terraform state show module.data.aws_db_instance.main[0]
- aws route53 list-hosted-zones --output table
- aws wafv2 list-web-acls --scope REGIONAL --region us-east-1 --output table
- aws rds describe-db-instances --region us-east-1 --output table

### Secuencia recomendada de validacion (post-apply)
1. Validar estado de Terraform
  - terraform state list

2. Ver los outputs del root module (si existen)
  - terraform output
  - Si aparece "No outputs found", continuar con state show y AWS CLI.

3. Confirmar recursos criticos en Terraform state
  - terraform state show module.load_balancer.aws_lb.main
  - terraform state show module.compute.aws_instance.master_primary
  - terraform state show module.data.aws_db_instance.main[0]

4. Validar en AWS el ALB
  - aws elbv2 describe-load-balancers --names ALB-dev --region us-east-1 --query "LoadBalancers[0].{DNS:DNSName,State:State.Code,Type:Type,Scheme:Scheme}" --output table
  - Resultado esperado: State = active

5. Validar en AWS las instancias EC2 del cluster
  - aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Name,Values=Master-dev-0,Master-dev-1,worker-dev-1-Client-BFF,worker-dev-2-Provider-BFF" "Name=instance-state-name,Values=running,pending,stopped" --query "Reservations[].Instances[].{Name:Tags[?Key=='Name']|[0].Value,State:State.Name,PrivateIP:PrivateIpAddress,InstanceId:InstanceId}" --output table
  - Resultado esperado: State = running en masters y workers

6. Validar en AWS la base de datos RDS
  - aws rds describe-db-instances --db-instance-identifier duna-postgres-dev --region us-east-1 --query "DBInstances[0].{Status:DBInstanceStatus,Engine:Engine,Version:EngineVersion,Endpoint:Endpoint.Address,MultiAZ:MultiAZ}" --output table
  - Resultado esperado: Status = available, MultiAZ = True

7. (Opcional) Validar WAF y Route53 cuando aplique DNS
  - aws wafv2 list-web-acls --scope REGIONAL --region us-east-1 --output table
  - aws route53 list-hosted-zones --output table

### Nota sobre Route Tables en AWS Console
- Es normal ver una route table adicional sin subnets asociadas.
- Esa tabla suele ser la route table principal de la VPC (Main = True), creada automaticamente por AWS.
- En este proyecto, las 6 subnets se asocian explicitamente a 1 tabla publica y 2 privadas, por eso la tabla principal queda sin subnets.
- No es un error y no debe eliminarse mientras exista la VPC.
- Comando rapido para validarlo:
  - aws ec2 describe-route-tables --region us-east-1 --filters "Name=vpc-id,Values=<VPC_ID>" --query "RouteTables[].{RouteTableId:RouteTableId,Main:Associations[0].Main,AssocCount:length(Associations[?SubnetId!=null]),Routes:length(Routes)}" --output table



## Troubleshooting
1) InvalidSubnet.Range
Causa: subred fuera del bloque VPC.
Acción: validar que todas las subredes estén contenidas en vpc_cidr.

2) DependencyViolation al destruir VPC
Causa común: NAT/ALB/ENI aún activos.
Acción:
```bash
  terraform destroy
```



Si falla, esperar unos minutos y reintentar.
Si persiste, revisar dependencias con AWS CLI:
  ```bash
  aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=<VPC_ID>
  aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=<VPC_ID>
  aws elbv2 describe-load-balancers
```

3) Destroy muy lento
Normal en NAT Gateway/ALB. Puede tardar 10–30+ minutos según estado interno de AWS.

### Validar recursos disponibles
- **Base EC2**
  - `aws ec2 describe-addresses --region us-east-1 --output table`  (EIP/NAT)
  - `aws ec2 describe-key-pairs --region us-east-1 --output table`  (llaves SSH)
  - `aws ec2 describe-instances --region us-east-1 --output table`  (master/worker)
- **Red (VPC/Subredes)**
  - `aws ec2 describe-vpcs --region us-east-1 --output table`
  - `aws ec2 describe-subnets --region us-east-1 --output table`
- **Seguridad**
  - `aws ec2 describe-security-groups --region us-east-1 --output table`
- **Balanceador (ALB)**
  - `aws elbv2 describe-load-balancers --region us-east-1 --output table`
  - `aws elbv2 describe-target-groups --region us-east-1 --output table`
- **Cómo identificarlas rápido**
  - `ec2 describe-*` = cómputo, red y seguridad base en EC2/VPC.
  - `elbv2 describe-*` = recursos del balanceador (ALB/NLB).



## Valida residuos en AWS (costos)
- **Elastic IP (EIP)**
  - `aws ec2 describe-addresses --region us-east-1 --output table`
- **NAT Gateway**
  - `aws ec2 describe-nat-gateways --region us-east-1 --filter Name=state,Values=available,pending,deleting --output table`
- **Load Balancer (ALB)**
  - `aws elbv2 describe-load-balancers --region us-east-1 --output table`






