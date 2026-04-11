# Diagrama de Arquitectura AWS (Proyecto D-Una)

Este documento resume la arquitectura objetivo y su estado de implementacion en Terraform.


## 1) Arquitectura objetivo

 - Publica: NAT Gateway (2 subredes)
 - Privada: App/K3s (2 subredes)
 - Privada: Data/DB (2 subredes)

```mermaid
%%{init: {"flowchart": {"htmlLabels": true}, "themeVariables": {"fontSize": "18px"}, "themeCSS": ".cluster-label text { font-size: 22px !important; font-weight: 700; } .nodeLabel { font-size: 18px !important; }"} }%%
flowchart LR

    %% Estilos Profesionales
    classDef cloud fill:#f9f9f9,stroke:#232F3E,stroke-width:2px,font-size:18px,font-weight:bold;
    classDef vpc fill:#fff,stroke:#3B48CC,stroke-width:2px,stroke-dasharray: 5 5;
    classDef az fill:#fff,stroke:#00A1C9,stroke-width:1px,stroke-dasharray: 5 5;
    classDef pub fill:#e1f8e9,stroke:#2e7d32,stroke-width:1px;
    classDef priv fill:#e3f2fd,stroke:#1565c0,stroke-width:1px;
    classDef db fill:#fff3e0,stroke:#ef6c00,stroke-width:1px;
    classDef k3s fill:#326ce5,color:#fff,stroke-width:2px;
    classDef invisibleVPC fill:none,stroke:none,color:#3B48CC,font-weight:bold,font-size:20px;

    Cliente([fa:fa-laptop Cliente Web]) -- "HTTPS:443" --> WAF[1. AWS WAF]
    
    subgraph AWS [AWS Cloud]
        
        WAF --> ALB[2. Application Load Balancer]

        S3[(Amazon S3<br/>Storage)]

        subgraph VPC [" "]
            %% Título de VPC a la izquierda
            L2[fa:fa-network-wired VPC <br/> 172.16.20.0/22]:::invisibleVPC
            %%L2 ~~~ ALB
            
            ALB[3. Application Load Balancer]

            %% AZ 1         
            subgraph AZ1 [Availability Zone 1 - us-east-1a]
                subgraph PUB1 [Red Pública]
                    NAT1[NAT Gateway]
                end
                subgraph PRIV1 [Red Privada K3s]
                    M1{{Master K3s - HA}} 
                    W1[[Worker Node - App-1]]
                end
                subgraph DB_SUB1 [Red de Datos]
                    RDS_P[(RDS Primary)]
                end
            end

            %% AZ 2        
            subgraph AZ2 [Availability Zone 2 - us-east-1d]
                subgraph PUB2 [Red Pública]
                    NAT2[NAT Gateway]
                end
                subgraph PRIV2 [Red Privada K3s]
                    M2{{Master K3s - HA}}
                    W2[[Worker Node - App-2]]
                end
                subgraph DB_SUB2 [Red de Datos]
                    RDS_S[(RDS Standby)]
                end
            end
        
            IGW[Internet Gateway]
        end
       
    end
    
    %% Conexión de ALB hacia la Red Pública y luego Privada
    ALB ====> PUB1 & PUB2
    NAT1 <-.-> W1
    NAT2 <-.-> W2
    NAT1 & NAT2 ------> IGW

    %% Comunicación K3s y DB
    M1 <-->|Puerto 6443 / 10250<br/>Tráfico Interno| W1
    M2 <-->|Puerto 6443 / 10250<br/>Tráfico Interno| W2
    W1 & W2 -- "DB: 5432" --> RDS_P
    RDS_P -. "Sync" .-> RDS_S

    %% S3 
    W1 & W2 -. "S3 API" .-> S3

    %% Forzar alineación vertical
    PUB1 ~~~ PRIV1 ~~~ DB_SUB1
    PUB2 ~~~ PRIV2 ~~~ DB_SUB2
    %%DB_SUB1 ~~~ DB_SUB2

                           
    %% Aplicación de clases
    class AWS cloud; class VPC vpc; class AZ1,AZ2 az;
    class PUB1,PUB2 pub; class PRIV1,PRIV2 priv; class DB_SUB1,DB_SUB2 db;
    class M1,M2,W1,W2 k3s;
    class S3 db;
```

## 2) Estado actual implementado en Terraform

- Implementado: VPC, subredes públicas/app/data, IGW, NAT por AZ, SGs, 2 masters K3s, 2 workers K3s, ALB HTTP.
- Configurado: Módulo AWS WAF regional y de Base de datos (RDS PostgreSQL Multi-AZ).
- Almacenamiento: Amazon S3 (Assets) provisioning con políticas y CORS.
- Pendiente: listener HTTPS con ACM y Route 53 (depende de variables de DNS).

Este diagrama representa la arquitectura objetivo de alta disponibilidad (Multi-AZ) en AWS para una aplicacion web orquestada con K3s.

**1. Flujo de Entrada y Seguridad (Capas 1, 2 y 3)**

- Punto de Inicio: El cliente accede vía HTTPS (puerto 443).

- WAF (Web Application Firewall): Filtra ataques (como inyecciones SQL o ataques de bots) antes de que lleguen a la aplicación.
- ALB (Load Balancer): Distribuye el tráfico entrante de manera equitativa entre las dos Zonas de Disponibilidad (us-east-1a y us-east-1d).

**2. Estructura de Red (VPC)**

La red está segmentada en 3 capas de subredes para maximizar la seguridad:

- Red Pública (Verde): Aloja los NAT Gateways. Es la única con salida directa a Internet. El tráfico del balanceador (ALB) pasa por aquí para llegar a la aplicación.
- Red Privada K3s (Azul): Donde vive la lógica. Contiene los Masters (cerebro del cluster) y Workers (donde corre tu App). Están aislados de Internet.
- Red de Datos (Naranja): La capa más profunda y protegida, exclusiva para la base de datos RDS.

**3. Alta Disponibilidad y Resiliencia**

- Multi-AZ: Si una zona de AWS (como la 1a) falla, la 1d sigue operando sin interrupción.
- K3s HA Sync: Los nodos Master están sincronizados para que el orquestador nunca caiga.
- RDS Primary/Standby: La base de datos principal (RDS_P) replica los datos en tiempo real a una de respaldo (RDS_S). Si la principal falla, la de respaldo toma el control automáticamente.

**4. Flujo de Salida (Mantenimiento)**

Como los nodos de K3s están en una red privada, no pueden "ver" Internet directamente. Cuando necesitan descargar una actualización o una imagen de contenedor, envían el tráfico a través del NAT Gateway en la red pública, que sale por el Internet Gateway (IGW).

