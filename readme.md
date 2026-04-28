# Proyecto AWS K3S - D-Una

Este proyecto automatiza la creación de un clúster de **K3s** altamente disponible en **AWS** utilizando **Terraform**.

## Estructura del Proyecto

El proyecto está organizado en módulos para una mejor gestión y escalabilidad:

- **`01-K3S/`**: Infraestructura base distribuida en módulos:
    - **`network`**: Configura la VPC, subredes (Públicas, Privadas App, Privadas Datos), Internet Gateway y NAT Gateway.
    - **`security`**: Define los Security Groups para el Balanceador de Carga (ALB), los nodos Master y los nodos Worker.
    - **`compute`**: Despliega las instancias EC2 para los nodos Master (en subred pública) y Worker (en subred privada), configurando K3s mediante `user_data`.
    - **`load_balancer`**: Configura un Application Load Balancer (ALB) para distribuir el tráfico hacia los workers.
- **`02-PERSISTENCE/`**: Servicios de persistencia de datos:
    - **`db`**: Instancia de Amazon RDS (PostgreSQL) para n8n, protegida en subredes de datos.
    - **`storage`**: Amazon EFS (Elastic File System) para almacenamiento compartido/persistente del clúster K3s.

## Características Principales

- **Arquitectura Híbrida**: Nodo Master en subred pública para administración y Workers protegidos en subred privada.
- **Persistencia Robusta**: Base de datos gestionada (RDS) y almacenamiento compartido (EFS) con acceso restringido solo a los Workers.
- **Seguridad**: Uso de subredes privadas, NAT Gateway para salida a internet y Security Groups específicos por rol.
- **Infraestructura como Código (IaC)**: Organizado en capas (K3S y Persistence) para modularizar el despliegue.

## Requisitos Previos

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- Configuración de credenciales de AWS (profile `default` por defecto).
- Una llave SSH en AWS llamada `testKey` (configurable en `variables.tf`).

## Despliegue

1. Inicializar Terraform:
   ```bash
   terraform init
   ```

2. Validar la configuración:
   ```bash
   terraform validate
   ```

3. Visualizar el plan de ejecución:
   ```bash
   terraform plan
   ```

4. Aplicar los cambios:
   ```bash
   terraform apply
   ```

## Diagrama de Arquitectura (Subred Privada - 4 Workers)

El siguiente diagrama representa la arquitectura simplificada, donde el **Master** se encuentra en la subred pública para administración, y los **4 Workers** (`worker_1`, `worker_2`, `worker_3`, `worker_4`) se encuentran protegidos en la subred privada:

```mermaid
flowchart TB
    classDef cloud fill:#fff,stroke:#232F3E,stroke-width:4px;
    classDef vpc stroke:#3B48CC,stroke:#3B48CCstroke-width:2px,stroke-dasharray: 5 5;
    classDef pub fill:#e1f8e9,stroke:#2e7d32,stroke-width:1px;
    classDef priv fill:#e3f2fd,stroke:#1565c0,stroke-width:1px;
    classDef db fill:#fff,stroke:#ef6c00,stroke-width:1px;
    classDef k3s fill:#326ce5,color:#fff,stroke-width:2px;
    classDef invisibleVPC fill:none,stroke:none,color:#3B48CC,font-weight:bold,font-size:25px;


    %% Usuarios 
    subgraph Usuarios [ ]
        direction LR
        Cliente([fa:fa-laptop Cliente])
        Proveedor([fa:fa-building Proveedor])
        Administrador([fa:fa-user-shield Administrador])
        Lens[fa:fa-desktop Lens]
    end
    
    Cliente & Proveedor & Administrador -- "HTTPS:443" ---> HTTPS([fa:fa-globe Https])
    
    HTTPS --> ALB
    
    subgraph AWS ["fa:fa-cloud AWS Cloud"]
        ALB[ALB]
        S3[(Amazon S3<br/>Assets)]
        
        subgraph VPC [" "]
            L2[fa:fa-network-wired VPC <br/> 172.16.20.0/22]:::invisibleVPC
            
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
                RDS_S[(RDS Standby)]
                EFS[(EFS Storage)]
            end
            IGW[Internet Gateway]
        end
    end
    Internet([fa:fa-globe Internet])

    %% Administracion segura
    Administrador --> Lens -- "SSM Tunnel localhost:6443" --> M1

    %% Conexiones de aplicacion
    ALB --> PUB1
    M1 -- "Tráfico Interno" --> PRIV1
    PRIV1 -- "DB: 5432" --> RDS
    RDS -. "Sync" .-> RDS_S
    PRIV1 -- "EFS" --> EFS
   

    %% S3 Assets (GAP-INFRA-002)
    PRIV1 -. "S3 API" .-> S3
    HTTPS -. "GET" .-> S3

    %% Salida a Internet restringida por NAT
    PRIV1 ==Salida a internet==> NAT1 ==Salida a internet==> IGW ==> Internet

    class AWS cloud; class VPC vpc; class PUB1 pub;
    class PRIV1 priv; class DB_SUB1,S3 db; class M1,W1,W2,W3,W4 k3s;
```


### Cambios Recientes (Actualizado)
- **Capa de Persistencia**: Se implementó el módulo `02-PERSISTENCE` con RDS (Postgres 17.6) y EFS.
- **Aumento a 4 Workers**: El clúster ahora tiene 4 workers en subred privada, nombrados genéricamente `worker_1`, `worker_2`, `worker_3`, `worker_4`.
- **Seguridad de Datos**: Los servicios de persistencia (RDS/EFS) solo permiten tráfico desde el Security Group de los Workers.

## Despliegue Actualizado
1. **Inicializar**: `terraform init`
2. **Validación**: `terraform validate` (Configuración de 4 workers privados validada exitosamente).
3. **Planificar**: `terraform plan`
4. **Aplicar**: `terraform apply`