# Proyecto D-Una — Despliegue de clúster K3s en AWS con Terraform

## Objetivo
Implementar infraestructura en AWS mediante Terraform para un clúster K3s básico con arquitectura modular, separando red, seguridad, cómputo y balanceo.

## Cheat Sheet (rápido)

- Configura en `variables.tf`: `my_ip` (tu IP/32), `key_name` (llave existente en AWS) y CIDRs válidos dentro de `vpc_cidr`.


## Arquitectura implementada
- VPC personalizada.
- 2 subredes públicas y 6 privadas.
- Internet Gateway y NAT Gateway.
- Tablas de ruteo pública/privada.
- Security Groups para ALB, nodo master y nodo worker.
- 2 instancias EC2:
  - Master (subred pública).
  - Worker (subred privada).
- Application Load Balancer (ALB) público con listener HTTP hacia el worker.

## Organización del proyecto
- `main.tf`: orquesta los módulos.
- `providers.tf`: versión de Terraform/proveedor AWS y backend local.
- `variables.tf`: variables globales y configuración por entorno (`dev`).
- `modules/network`: red base.
- `modules/security`: reglas de seguridad.
- `modules/compute`: EC2 + bootstrap K3s.
- `modules/load_balancer`: ALB y target group.

## Parámetros principales (entorno dev)
- `vpc_cidr = 172.16.20.0/22`
- `pub_subnets = [172.16.20.0/25, 172.16.20.128/25]  ------ Hosts`
- `priv_subnets = [`
  - `"172.16.21.0/25", "172.16.21.128/25"` — Back
  - `"172.16.22.0/26", "172.16.22.64/26"` — DB
  - `"172.16.22.128/26", "172.16.22.192/26"` — Users
  - `]`
- `master_type = t3.medium`
- `worker_type = t3.large`
- `my_ip = <IP_PUBLICA>/32` para acceso administrativo al master.
- `key_name` debe existir en AWS.

## Flujo de despliegue
1. `terraform init`
2. `terraform workspace select dev || terraform workspace new dev`
3. `terraform validate`
4. `terraform plan`
5. `terraform apply`

## Flujo de limpieza
- `terraform destroy`


## Recomendaciones
- Restringir `my_ip` a la IP real del administrador.
- Evitar exposición SSH amplia en producción.
- Considerar HTTPS (ACM + listener 443) para el ALB.
- Ejecutar `destroy` al finalizar pruebas para controlar costos.

## Verificación post-deploy
- terraform state list
- terraform state show module.compute.aws_instance.master
- terraform state show module.load_balancer.aws_lb.main



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