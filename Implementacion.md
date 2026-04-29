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
ssh -i "testKey.pem" ubuntu@52.90.26.223 " sudo cat /etc/rancher/k3s/k3s.yaml" > k3s-config.yaml

# Abrir tunel SSH desde consola distinta u otra terminal
ssh -i "testKey.pem" -L 6443:127.0.0.1:6443 ubuntu@52.90.26.223 -N
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
terraform workspace select dev || terraform workspace new dev

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
  - Se pega lo de **n8n-secret.yaml**
  > validar la contraseña que se puso en la BD, y se pega en el campo de "password" del secret

- Se va a AWS:
  - Aurora and RDS
    - Databases (eliges tu BD)
    - Endpoints
    - Endpoint & port 
se saca el codigo de la BD para usarlo en N8N

  - Se abre **n8n-deployment.yaml**
    - Se cambia el endpoint de la BD en `DB_POSTGRESDB_HOST` por tu endpoint real.
    __Linea 56__: `value: "db-n8n-dev.cjg1jd3af1v1.us-east-1.rds.amazonaws.com"`  por tu endpoint real de RDS
    - Se deja el PVC como `efs-pvc-ia` (el que ya creaste en Proyecto 3).

- Se crea un nuevo recurso:
  - Se pega **n8n-deployment.yaml**


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
  - EJEMPLO: 52.90.26.223:30567

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

**Versión usada y motivo**

- **Imagen:** `ollama/ollama:0.1.48`
- **Por qué:** elegimos una versión específica y más ligera porque la etiqueta `latest` incluye capas grandes (CUDA, binarios adicionales) que causaron fallos de extracción por falta de espacio efímero en los nodos. La versión `0.1.48` es más pequeña, reproducible y adecuada para clusters con disco raíz limitado; así evitamos problemas de extracción y disminuimos el uso temporal de snapshot del runtime.
- **Si dispones de nodos con más espacio o GPU:** puedes cambiar a una imagen con soporte CUDA o a `latest`, pero ten en cuenta que necesitarás más espacio en `/var/lib/rancher/k3s/agent`.


### Pruebas de Ollama (cuando no tienes kubectl instalado en tu PC)

Abrir 3 terminales en tu PC:

- **Terminal A (PC):** tunel SSH para exponer el puerto local `11434`
```bash
ssh -i "testKey.pem" -L 11434:127.0.0.1:11434 ubuntu@52.90.26.223 -N
```

- **Terminal B (PC -> Master):** entrar al master y abrir `port-forward`
```bash
ssh -i "testKey.pem" ubuntu@52.90.26.223
kubectl get pods -l app=ollama -n default
kubectl get svc ollama -n default
kubectl port-forward svc/ollama 11434:11434 -n default
```

- **Terminal C (PC):** probar API de Ollama
```bash
curl http://localhost:11434/api/tags
```

Si responde `{"models":[]}` significa que Ollama esta bien, pero todavia no hay modelos descargados.

### Descargar modelo y probar inferencia

```bash
# Descargar modelo pequeno para pruebas
curl -X POST http://localhost:11434/api/pull -d "{\"name\":\"tinyllama\"}"

# Ver modelos instalados
curl http://localhost:11434/api/tags

# Prueba de generacion
curl -X POST http://localhost:11434/api/generate -d "{\"model\":\"tinyllama:latest\",\"prompt\":\"Hola, responde en una sola linea\",\"stream\":false}"
```


## Proyecto 6 "06-KAFKA"
Se recomienda desplegar Kafka con el operador Strimzi (más compatible y mantenido). A continuación están los pasos detallados y ejemplos de Custom Resources (CR) para un clúster KRaft moderno.

Pasos rápidos (resumen):
- Instalar Strimzi (Helm o YAML) en el namespace `default`.
- Aplicar el CR `Kafka` (config global) y uno o más `KafkaNodePool` (replicas, storage, roles).
- Comprobar CRs y pods, luego crear topics y probar producer/consumer desde el pod `my-cluster-mixed-0`.

Instalar Strimzi (ejemplo con Helm en Lens o CLI):
```bash
# Con Helm (si usas CLI):
helm repo add strimzi https://strimzi.io/charts/
helm repo update
helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator --namespace default --create-namespace
```

Comprobar que el operador está running:
```bash
kubectl -n default get pods -l name=strimzi
kubectl -n default get crd | grep kafka
```

Ejemplo mínimo de Custom Resources para un cluster KRaft (guarda como `06-KAFKA/strimzi-kafka-kraft.yaml` y apúralo con Lens o `kubectl apply -f`):

```yaml
apiVersion: kafka.strimzi.io/v1
kind: Kafka
metadata:
  name: my-cluster
  namespace: default
spec:
  # version: indica la versión de Kafka que deployará Strimzi
  version: "3.6.0"
  kafka:
    # config global del cluster
    config:
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
  # entity operator (topic/user management)
  entityOperator:
    topicOperator: {}
    userOperator: {}

---
# KafkaNodePool define nodos (replicas, storage y roles). Puedes crear varias pools.
apiVersion: kafka.strimzi.io/v1
kind: KafkaNodePool
metadata:
  name: mixed
  namespace: default
  labels:
    strimzi.io/cluster: my-cluster
spec:
  replicas: 1
  roles:
    - broker
    - controller
  storage:
    type: ephemeral
    # Para storage persistente usa:
    #   type: persistent-claim
    #   size: 20Gi
    #   storageClass: gp2

```

Notas sobre storage:
- `ephemeral` es más sencillo para pruebas (no crea PVCs). Para producción usa `persistent-claim` y define `size` y `storageClass`.

Comandos útiles para comprobar despliegue (desde master o con `kubectl` en tu máquina):
```bash
# Ver CRs de Strimzi
kubectl -n default get kafka
kubectl -n default get kafkanodepools

# Ver pods del cluster y del operador
kubectl -n default get pods

# Ver servicios (bootstrap service para clientes internos)
kubectl -n default get svc | grep my-cluster
```

Nombre del service bootstrap (ejemplo interno): `my-cluster-kafka-bootstrap:9092` — es el endpoint que usan clientes dentro del cluster.

Crear topics (desde dentro de un pod broker, ejemplo con `my-cluster-mixed-0`):
```bash
# Abrir shell en el pod (Lens Terminal o SSH -> kubectl exec):
# kubectl exec -it my-cluster-mixed-0 -n default -- bash

# Crear topic
/opt/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --topic prueba-kafka --partitions 1 --replication-factor 1

# Listar topics
/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092

# Describir topic
/opt/kafka/bin/kafka-topics.sh --describe --bootstrap-server localhost:9092 --topic prueba-kafka

# Enviar mensaje (producer)
echo "hola desde prueba" | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic prueba-kafka

# Consumir mensajes (consumer)
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic prueba-kafka --from-beginning --max-messages 1

# Comandos sin shell interactivo (desde master):
kubectl -n default exec my-cluster-mixed-0 -- /opt/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --topic prueba-kafka --partitions 1 --replication-factor 1
echo "hola" | kubectl -n default exec -i my-cluster-mixed-0 -- /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic prueba-kafka
kubectl -n default exec my-cluster-mixed-0 -- /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic prueba-kafka --from-beginning --max-messages 1
```

Exponer Kafka externamente (opciones):
- Para pruebas rápidas puedes cambiar listeners en el `Kafka` CR para crear un external listener con `type: nodeport` o `loadbalancer`. Consulta la documentación de Strimzi para `listeners.external`. Ejemplo básico:

```yaml
# Dentro del spec.kafka del Kafka CR:
listeners:
  - name: plain
    port: 9092
    type: internal
  - name: external
    port: 30992
    type: nodeport
    tls: false
```

Recomendaciones finales:
- Para pruebas usa `ephemeral` storage y `replicas: 1`.
- Para producción: múltiples replicas, `persistent-claim` storage y al menos 3 brokers (o según HA que necesites).
- Si usas Lens: pega el YAML en `Create Resource` y aplica; usa la Terminal del pod para ejecutar los binarios `kafka-*`.

Referencias:
- Documentación Strimzi: https://strimzi.io/docs/operators/latest/
  



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