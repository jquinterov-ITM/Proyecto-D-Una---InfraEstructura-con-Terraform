# Diagrama de Arquitectura AWS (Proyecto D-Una)

Este documento resume la arquitectura objetivo y su estado de implementacion en Terraform.


## 1) Arquitectura actual
 - Pública: NAT Gateway y Master
- Privada: App/K3s (2 workers: Front y BFF)
- Privada: Data/DB (RDS y EFS)
 


```mermaid
flowchart LR
classDef cloud fill:#fff,stroke:#232F3E,stroke-width:2px;
classDef vpc fill:#fff,stroke:#3B48CC,stroke-width:2px,stroke-dasharray: 5 5;
classDef pub fill:#e1f8e9,stroke:#2e7d32,stroke-width:1px;
classDef priv fill:#e3f2fd,stroke:#1565c0,stroke-width:1px;
classDef db fill:#fff3e0,stroke:#ef6c00,stroke-width:1px;
classDef k3s fill:#326ce5,color:#fff,stroke-width:2px;

Cliente([fa:fa-laptop Cliente Web]) -- "HTTPS:443" --> ALB

subgraph AWS ["fa:fa-cloud AWS Cloud"]
    subgraph VPC ["VPC 172.16.20.0/22"]
        ALB[ALB]
        subgraph PUB1 [Red Pública]
            NAT1[NAT Gateway]
            M1{{Master K3s}}
        end
        subgraph PRIV1 [Red Privada K3s]
            W1[[Worker Front]]
            W2[[Worker BFF]]
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
M1 -- "Tráfico Interno" --> W1 & W2
W1 -- "DB: 5432" --> RDS
W2 -- "DB: 5432" --> RDS
W1 -- "EFS" --> EFS
W2 -- "EFS" --> EFS

class AWS cloud; class VPC vpc;
class PUB1 pub; class PRIV1 priv; class DB_SUB1 db;
class M1,W1,W2 k3s;
```                   


## 2) Estado actual implementado en Terraform

- Implementado: VPC, subredes públicas/app/data, IGW, NAT, SGs, 1 master K3s, 2 workers K3s, ALB HTTP, RDS, EFS.
- Seguridad: Solo los workers acceden a RDS/EFS. NAT restringe salida a internet.
- Pendiente: listener HTTPS con ACM y Route 53 (depende de variables de DNS).

Este diagrama representa la arquitectura real y simplificada de alta disponibilidad en AWS para una aplicación web orquestada con K3s.

**Notas:**
- El clúster se ha optimizado a 2 workers (Front y BFF) en subred privada.
- La capa de persistencia (RDS/EFS) está protegida y solo accesible desde los workers.
- El master está en subred pública solo para administración.
- Red Pública (Verde): Aloja los NAT Gateways. Es la única con salida directa a Internet. El tráfico del balanceador (ALB) pasa por aquí para llegar a la aplicación.

- Red Privada K3s (Azul): Donde vive la lógica. Contiene los Masters (cerebro del cluster) y Workers (donde corre tu App). Están aislados de Internet.
