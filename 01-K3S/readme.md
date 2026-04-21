# Proyecto AWS K3S - D-Una

Este proyecto automatiza la creación de un clúster de **K3s** altamente disponible en **AWS** utilizando **Terraform**.

## Estructura del Proyecto

El proyecto está organizado en módulos para una mejor gestión y escalabilidad:

- **`modules/network`**: Configura la VPC, subredes (Públicas, Privadas App, Privadas Datos), Internet Gateway y NAT Gateway.
- **`modules/security`**: Define los Security Groups para el Balanceador de Carga (ALB), los nodos Master y los nodos Worker.
- **`modules/compute`**: Despliega las instancias EC2 para los nodos Master (en subred pública) y Worker (distribuidos entre subred pública y privada), configurando K3s mediante `user_data`.
- **`modules/load_balancer`**: Configura un Application Load Balancer (ALB) para distribuir el tráfico hacia los workers en ambas subredes.

## Características Principales

- **Arquitectura Híbrida**: Nodo Master y el primer Worker en subred pública para facilitar la administración y pruebas iniciales.
- **Seguridad**: Workers adicionales y recursos de datos protegidos en subredes privadas. Acceso controlado mediante Security Groups y NAT Gateway.
- **Escalabilidad**: Definición de entornos (vía `locals` y `terraform.workspace`) para ajustar el tamaño del clúster (dev/prod).
- **Backend Remoto**: Configurado para usar un bucket S3 para el estado de Terraform.

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

## Diagrama de Arquitectura (Subred Mixta y Nombres de Rol)

El siguiente diagrama representa la arquitectura actual, donde el **Master** y el **Worker 1 (Front)** se encuentran en la subred pública, mientras que los **Workers 2 y 3 (BFF)** y los recursos de datos se mantienen en la subred privada de la Zona A para mayor seguridad:

```mermaid
architecture-beta
    group vpc(cloud)[AWS VPC]
        service igw(internet)[Internet Gateway] in vpc

        group pub_subnet(cloud)[Public Subnet A] in vpc
            service alb(server)[ALB] in pub_subnet
            service nat(server)[NAT Gateway] in pub_subnet
            service master(server)[K3s Master] in pub_subnet
            service worker1(server)[Worker Front] in pub_subnet
        
        group priv_subnet_app(cloud)[Private App Subnet A] in vpc
            service worker2(server)[Worker BFF] in priv_subnet_app
            service worker3(server)[Worker BFF] in priv_subnet_app
        
        group priv_subnet_data(cloud)[Private Data Subnet] in vpc
            service db(database)[DB Resources] in priv_subnet_data

    %% Relaciones
    igw:B -- T:alb
    igw:B -- T:master
    
    alb:B -- T:worker1
    alb:B -- T:worker2
    alb:B -- T:worker3
    
    master:B -- L:worker1
    master:B -- L:worker2
    master:B -- L:worker3

    worker2:T -- B:nat
    nat:L -- R:igw
```

### Características de la Configuración Actual
- **Master y Worker Front en Subred Pública**: Facilidad de acceso directo para administración y despliegue de componentes de cara al usuario.
- **Workers BFF en Subred Privada**: Capa de servicios internos (Backend-for-Frontend) protegida dentro de la red privada, con salida a internet vía un único **NAT Gateway**.
- **Consolidación en Zona de Disponibilidad A**: Todos los nodos de trabajo y el NAT Gateway se encuentran en la zona `us-east-1a` para simplificar la topología y reducir costos de transferencia de datos inter-zona.
- **Nombres de Rol**: Las instancias están etiquetadas según su función (`Front` y `BFF`) para una identificación rápida en la consola de AWS.

## Despliegue Actualizado
1. **Inicializar**: `terraform init`
2. **Validación**: `terraform validate` (Configuración simplificada y etiquetada validada exitosamente).
3. **Planificar**: `terraform plan`
4. **Aplicar**: `terraform apply`