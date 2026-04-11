# Implementacion y operacion del proyecto

## 1. Objetivo
Este documento describe el flujo completo para:

- Inicializar y desplegar infraestructura con Terraform.
- Verificar que el cluster K3s quede operativo.
- Conectarse a Kubernetes desde Lens usando Session Manager (SSM), sin IP publica en masters.

## 2. Estado actual de la arquitectura

- Masters: uno por cada subred privada App/K3s.
- Workers: dos (uno por cada subred privada App/K3s).
- Pods por worker: maximo 3.
- Roles actuales esperados: Worker 1 = Client-BFF, Worker 2 = Provider-BFF.
- Master con IP privada fija por subred App (host .10).
- Acceso administrativo a Kubernetes por SSM tunnel.

## 3. Prerrequisitos

## 3.1 Local (tu equipo)

- Terraform >= 1.5
- AWS CLI v2
- Session Manager Plugin
- Credenciales AWS configuradas (`aws configure` o perfil)
- Lens Desktop (opcional para UI)
- kubectl (opcional para validacion por CLI)

Validaciones sugeridas:

```powershell
terraform -version
aws --version
session-manager-plugin

winget install Amazon.SessionManagerPlugin

aws sts get-caller-identity
```

## 3.2 En AWS

- Key pair existente para EC2 (valor de `key_name` en tfvars/variables).
- Permisos IAM para crear red, EC2, ALB, WAF, RDS y recursos IAM.
- Salida a internet desde subredes privadas por NAT (ya contemplado en el modulo de red).

## 4. Archivos importantes

- Infra principal: `main.tf`, `variables.tf`, `terraform.tfvars`, `providers.tf`.
- Modulos: `modules/`.
- Scripts de conexion:
  - `scripts/export-lens-kubeconfig.ps1`
  - `scripts/start-lens-ssm-tunnel.ps1`

## 5. Flujo de Terraform (paso a paso)

Ejecutar desde la raiz del proyecto.

## 5.1 Inicializar Terraform

```powershell
terraform init
```

## 5.2 Seleccionar/crear workspace

```powershell
terraform workspace select dev
```

Si no existe:

```powershell
terraform workspace new dev
```

## 5.3 Validar sintaxis y referencias

```powershell
terraform validate
```

## 5.4 Revisar plan

```powershell
terraform plan -var-file "terraform.tfvars"
```

## 5.5 Aplicar cambios

```powershell
terraform apply -var-file "terraform.tfvars" -auto-approve
```

Opciones para cuentas con permisos IAM limitados:

- Usar un instance profile existente (no requiere permisos IAM adicionales):

```powershell
terraform apply -var="existing_instance_profile_name=MyExistingProfile" -var-file "terraform.tfvars" -auto-approve
```

- Permitir que Terraform cree el rol y el instance profile (requiere permisos `iam:CreateRole`, `iam:AttachRolePolicy`, etc.):

```powershell
terraform apply -var="create_ec2_iam_resources=true" -var-file "terraform.tfvars" -auto-approve
```

Nota: por defecto `create_ec2_iam_resources=false` y las EC2 se crearán sin `iam_instance_profile`. Si necesitas SSM (Session Manager), usa un `existing_instance_profile_name` que incluya `AmazonSSMManagedInstanceCore`.

## 5.6 Outputs clave despues de apply

```powershell
terraform output
terraform output -raw master_primary_instance_id
terraform output master_private_ips
terraform output worker_private_ips
```

## 6. Verificacion rapida post-deploy

## 6.1 Terraform state

```powershell
terraform state list
```

## 6.2 EC2 del cluster

```powershell
aws ec2 describe-instances --region us-east-1 `
  --filters "Name=tag:Name,Values=Master-dev-0,Master-dev-1,worker-dev-1-Client-BFF,worker-dev-2-Provider-BFF" `
  --query "Reservations[].Instances[].{Name:Tags[?Key=='Name']|[0].Value,State:State.Name,PrivateIP:PrivateIpAddress,InstanceId:InstanceId}" `
  --output table
```

## 6.3 Instancias registradas en SSM

```powershell
aws ssm describe-instance-information --query "InstanceInformationList[].{InstanceId:InstanceId,Ping:PingStatus,Platform:PlatformName}" --output table
```

## 7. Conexion a Kubernetes con scripts (Lens)

## 7.1 Exportar kubeconfig desde el master por SSM

Este comando:
- Detecta el master desde output Terraform (o usa ID manual)
- Obtiene `/etc/rancher/k3s/k3s.yaml` por SSM
- Reemplaza el endpoint a `https://127.0.0.1:6443`
- Guarda el archivo local para Lens

```powershell
.\scripts\export-lens-kubeconfig.ps1
```

Opcional con parametros:

```powershell
.\scripts\export-lens-kubeconfig.ps1 -Profile default -Region us-east-1 -LocalPort 6443
```

## 7.2 Abrir tunnel SSM local hacia K3s API

```powershell
.\scripts\start-lens-ssm-tunnel.ps1
```

Opcional con Instance ID manual:

```powershell
.\scripts\start-lens-ssm-tunnel.ps1 -TargetInstanceId i-xxxxxxxxxxxxxxxxx
```

## 7.3 Importar cluster en Lens

- Abrir Lens.
- Add Cluster -> From kubeconfig.
- Seleccionar archivo generado:

```text
C:\Users\<tu_usuario>\.kube\k3s-duna-lens.yaml
```

- Mantener abierta la terminal del tunnel mientras uses Lens.

## 7.4 Validar conexion por CLI (opcional)

```powershell
$env:KUBECONFIG="$HOME/.kube/k3s-duna-lens.yaml"
kubectl get nodes
kubectl get pods -A
```

## 8. Operacion diaria recomendada

1. Ejecutar `export-lens-kubeconfig.ps1` cuando necesites refrescar kubeconfig.
2. Ejecutar `start-lens-ssm-tunnel.ps1` antes de abrir/usar Lens.
3. Cerrar tunnel al terminar la administracion.

## 9. Troubleshooting

## 9.1 SSM no conecta

- Verificar que la instancia tenga rol con `AmazonSSMManagedInstanceCore`.
- Verificar que aparezca en `describe-instance-information`.
- Verificar salida a internet por NAT en subred privada.

## 9.2 El script no encuentra `master_primary_instance_id`

- Ejecutar `terraform apply` en el workspace correcto.
- Verificar:

```powershell
terraform workspace show
terraform output -raw master_primary_instance_id
```

## 9.3 Lens no conecta

- Confirmar que el tunnel sigue abierto.
- Confirmar que kubeconfig usa `https://127.0.0.1:6443`.
- Probar por CLI con `kubectl get nodes` usando el mismo kubeconfig.

## 10. Limpieza

Destruir recursos cuando termines pruebas para controlar costos:

```powershell
terraform destroy -var-file "terraform.tfvars"
```
