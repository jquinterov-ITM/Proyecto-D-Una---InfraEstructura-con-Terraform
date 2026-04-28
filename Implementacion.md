## Abrir AWS
- Iniciar sesion en AWS
- Sacar las credenciales para poner en IDE

## Crear un S3
Para que guarde los estados de terraform, con el nombre: `aws-proyecto-d-una` (o el que quieras, pero se tiene que cambiar en el archivo `backend.tf`)
- Se crea un Bucket de proposito general
  - en mi caso es `jquinterov.seminario2`

## Ejecutar SH en "Git Bash"
Para cargar las variables (no me funciona bien)
- MAC o Windows en "Git Bash"
  > source Locals/setup/dev.sh


## Iniciar Proyecto 1 [01-K3S]
```bash
#Acortar ruta en PS (opcional- Windows)
function prompt { "PS $(Split-Path -Leaf (Get-Location))> " }

# ir al proyecto 1
cd .\01-K3S\
```

### Comandos Terraform
```bash
# Inicializar Terraform
terraform init

# Seleccionar workspace (opcional)
terraform workspace select dev

# Validar configuración
terraform validate

# Ver plan de ejecución
terraform plan

# Aplicar cambios
terraform apply
  - yes
```
Cuando termina de montar muestra la ip publica del master, la copiamos y ponemos en los siguientes comandos. y archivo de configuracion de lens.
> .\locals\setup\lens.sh

## **SSH**
Tener a la mano el archivo **testKey.pem** (o el keypair tuyo y poner el nombre)para conectarnos a la maquina y sacar el archivo de configuracion de k3s para lens, ademas de abrir el tunel ssh para que lens pueda conectarse al cluster.
```bash
# Comprobar tu IP pública:
(Invoke-RestMethod -Uri "https://api.ipify.org")

# USUARIO: Ubuntu@**ipPublicaDelMaster** o como sea la maquina

# Descargar el archivo de configuracion
ssh -i "testKey.pem" ubuntu@3.82.45.66 " sudo cat /etc/rancher/k3s/k3s.yaml" > k3s-config.yaml

# Abrir tunel SSH desde consola distinta u otra terminal
ssh -i "testKey.pem" -L 6443:127.0.0.1:6443 ubuntu@3.82.45.66 -N
```
- Con el archivo de configuracion [k3s-config.yaml], copiamos lo que trajo y se pasa a lens
- en **lens** (Se elimina default si existe)
  - click derecho 
  - add kubeconfigs, paste


## Iniciar Proyecto 2 [02-PERSISTENCE]
```bash
# ir al proyecto 2
cd ..\02-PERSISTENCE\
```
### Comandos Terraform
```bash
# Inicializar Terraform
terraform init

# Seleccionar workspace (opcional)
terraform workspace select dev

# Validar configuración
terraform validate

# Ver plan de ejecución
terraform plan

# Pide clave para la BD [1-8]

# Aplicar cambios
terraform apply
# Pide clave para la BD [1-8]
  - yes
```


## **Se abre LENS**
Confirmar que se hicieron los pasos de *Descargar el archivo de configuracion* y *Abrir tunel SSH*

**&darr;&darr;&darr;Esto se hace solo una vez, despues no es necesario &darr;&darr;&darr;**
  - en configuracion (preferencias)
    - kubernetes
    - Agregar: en helm
      - https://kubernetes-sigs.github.io/aws-efs-csi-driver/

**&uarr;&uarr;&uarr;Esto se hace solo una vez, despues no es necesario &uarr;&uarr;&uarr;**

  - Se va al menu de la izquierda "Helm"
    - Charts
    - Buscar **\*.AWS** 
    - **Instalar** aws-efs-csi-driver/aws-efs-csi-driver
    - en nameSpace "Kube-system"
    - Guardar (boton izquierda de disquette)

  - Se confirma instalacion: 
    - en menu de la izquierda "Workloads"
    - Da click en "DaemonSet" y se confirma que el controlador esta corriendo   
    - Pods: que se esta ejecutando. 



## Proyecto "03-K3S-Storage"
se va a AWS ---> EFS
  - File system ID (se copia)
  - Se pega en archivo **03-K3S-Storage/pv-pvc-k3s.yaml**
    - volumeHandle: fs-0a0ef43bc6dae9f9b # <--- COLOCA TU FS-ID DE EFS AQUÍ

**Volvemos a Lens**
  - Storage
    - Persistent Volumes - Icono + (crear recurso)
    - Se pega el contenido del archivo **pv-pvc-k3s.yaml** y se guarda    
    - Se pasa a "persistent Volume Claims", se elige "default", para ver lo creado.



## Proyecto 4
Se saca la informacion del proyecto 4 (**04-N8N**)
- Se crea un nuevo recurso:
  - Se pega lo de secrets.yaml
  > validar la contraseña que se puso en la BD, y se pega en el campo de "password" del secret

- Se va a AWS:
  - Aurora and RDS
    - Databases (eliges tu BD)
    - Endpoints
    - Endpoint & port 
se saca el codigo de la BD para usarlo en N8N

  - Se abre **n8n-deployment.yaml**
    - Se cambia lo de la db (linea 46)
    Se pega lo que sacamos antes [Endpoint & port]:
    > db-n8n-dev.cjg1jd3af1v1.us-east-1.rds.amazonaws.com
- Se crea un nuevo recurso:

Se valida en:
- Workloads
  - Deployments
    - Se confirma que n8n esta corriendo
    De lo contrario clic en los puntos y "restart"
  - Pods

El servicio esta en:
- Network
  - Services
    - Se confirma que el servicio esta corriendo y se saca la ip externa

Prueba de N8N
- Se abre el navegador con la ip externa que te asigno
  - EJEMPLO: 3.82.45.66:30567

---
## Proyecto 5 "05-OLLAMA"
- Se crea un nuevo recurso:
- Se pega el contenido del archivo **ollama-deployment.yaml**
- Se guarda y se confirma que el despliegue esta corriendo

Se valida en:
- Workloads
  - Deployments
    - Se confirma que Ollama esta corriendo
    De lo contrario clic en los puntos y "restart"
  - Pods
  Si en "Status" dice "Running" y no tiene errores, esta bien.
  Pero si dice ""Evited" o "CrashLoopBackOff", es que hay un error, y se puede revisar los logs para ver que esta pasando.
  **“Evicted”** significa que Kubernetes eliminó esos pods porque el nodo (la máquina) se quedó sin recursos (memoria RAM o disco).
  **“Pending”** significa que Kubernetes no encuentra dónde crear el pod, normalmente por falta de recursos.


## Proyecto 6 "06-KAFKA"
- Se va al menu de la izquierda "Helm"
    - Charts
    - Buscar **\*.kafka** 
    - **Instalar** bitnami/kafka
    - en nameSpace "default"
      1. DEJARLO COMO ESTA, SI FALLA PROBAR PASO 2
      2. En "Set values" se pega el contenido del archivo **Kafka_values.yaml**
    - Guardar (boton izquierda de disquette)

  - Se confirma instalacion: 
    - en menu de la izquierda "Workloads" 
    - Pods: que se esta ejecutando. 


PRUEBAS
nslookup google.com
nslookup registry.bitnami.com

### otro 
Agrega el repositorio de Strimzi manualmente:
1. En Lens, ve a la sección de “Helm” → “Repositories” (o “Repos”).
2. Haz clic en “Add Custom Repository” o “+ Add”.
3. Ponle de nombre: strimzi
4. En la URL, escribe:

5. Haz clic en “Add”.

Ahora vuelve a “Helm” → “Charts”, busca “strimzi” y ya debería aparecer el chart strimzi-kafka-operator.

## Enlaces útiles para Kafka con Strimzi

Si eliges la ruta de Strimzi, usa esta documentación oficial:

- Guía principal de despliegue: https://strimzi.io/docs/operators/latest/full/deploying.html
- Quick starts: https://strimzi.io/quickstarts/

## Ruta recomendada para principiantes

1. Verifica que K3s esté funcionando.
2. Instala el operador de Strimzi.
3. Aplica el manifiesto de Kafka.
4. Espera a que los pods queden en estado Running.
5. Crea topics y usuarios si los necesitas.
6. Desde ahí conecta tus aplicaciones como n8n.

### mis pasos para instalar Strimzi con Lens
1. Ve a “Helm” → “Charts” y busca “strimzi”.
2. Selecciona el chart strimzi-kafka-operator y haz clic en “Install”.
3. Elige el namespace (puedes dejar “default”) y haz clic en “Install”.

Cuando termine la instalación:
4. Ve a “Workloads” → “Pods” y espera a que el pod del operador esté en estado Running.

Luego:
5. En Lens, ve a “+” → “Create Resource”.
6. Pega este manifiesto YAML para crear un clúster Kafka sencillo:
  - strimzi_values.yaml
  



---
# FINALIZAR
Se ingresa al proyecto 2 y despues al 1 para destruir
```bash
# Destruir infraestructura
terraform destroy -auto-approve

```

## Apéndice: Accesos rápidos (n8n, Ollama, Kafka)

Estas notas resumen cómo acceder a las aplicaciones una vez desplegadas.

- n8n (NodePort):
  - Servicio: `n8n-service` escucha en `5678` internamente y expone `nodePort: 30567`.
  - Acceso desde navegador (ejemplo): `http://<IP-PUBLICA-DEL-NODO>:30567`.
  - Comprobar servicio:
    ```bash
    kubectl get svc n8n-service -n default
    kubectl get pods -l app=n8n -n default
    ```

- Ollama (ClusterIP):
  - Servicio: `ollama` en el puerto `11434` (solo dentro del clúster).
  - Para probar desde tu equipo local usa port-forward:
    ```bash
    kubectl port-forward svc/ollama 11434:11434 -n default
    # luego abrir http://localhost:11434
    ```

- Kafka:
  - Ruta A (Bitnami Helm): por defecto queda interno (ClusterIP). Para exponerlo, modifica `06-KAFKA/Kafka_values.yaml` y cambia `service.type` a `NodePort` o `LoadBalancer`.
  - Ruta B (Strimzi): revisa el `Kafka` CR y el bootstrap service creado por Strimzi. Para exponer listeners, configura los `listeners` en el manifiesto.
  - Comandos útiles:
    ```bash
    kubectl get pods -l app.kubernetes.io/name=kafka -n default
    kubectl get kafka -n default  # si usas Strimzi
    ```

Guarda estas líneas en un lugar fácil (o copia al README) para acceso rápido durante pruebas.
```