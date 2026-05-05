## Abrir AWS
- Iniciar sesion en AWS
- Sacar las credenciales para poner en IDE

## Crear un S3
Para que guarde los estados de terraform, con el nombre: `aws-proyecto-d-una` (o el que quieras, pero se tiene que cambiar en el archivo `01-K3S\providers.tf` en la parte  `backend`)
- Se crea un Bucket de proposito general
  - en mi caso es `jquinterov.seminario2` deberia ser `s3-duna-servicios`

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
terraform workspace select dev || terraform workspace new dev

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
ssh -i "testKey.pem" ubuntu@100.31.60.195 " sudo cat /etc/rancher/k3s/k3s.yaml" > k3s-config.yaml

# Abrir tunel SSH desde consola distinta u otra terminal
ssh -i "testKey.pem" -L 6443:127.0.0.1:6443 ubuntu@100.31.60.195 -N
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



    - volumeHandle: fs-0a0ef43bc6dae9f9b # <--- COLOCA TU FS-ID DE EFS AQUÍ

**Volvemos a Lens**
  - Storage
    - Persistent Volumes - Icono + (crear recurso)
    - Se pega el contenido del archivo **pv-pvc-k3s.yaml** y se guarda    
    - Se pasa a "persistent Volume Claims", se elige "default", para ver lo creado.



## Proyecto 4 "04-N8N" - Despliegue base de n8n

Este bloque instala n8n conectado a la base de datos RDS y usando el PVC de EFS creado en el Proyecto 3.

### Paso 1: preparar secret de n8n

- Crear un nuevo recurso en Lens con el contenido de **n8n-secret.yaml**.
- Validar que la contraseña del secret coincida con la clave real de la BD.

### Paso 2: actualizar el deployment con tu endpoint real de RDS

- Ir a AWS.
- Abrir `Aurora and RDS`.
- Entrar a `Databases` y elegir tu BD.
- Copiar `Endpoint & port`.
- Abrir **04-N8N/n8n-deployment.yaml**.
- Cambiar `DB_POSTGRESDB_HOST` por tu endpoint real de RDS.
- Mantener `DB_POSTGRESDB_DATABASE` apuntando a `n8ndb`.
- Dejar el PVC como `efs-pvc-ia`.

### Paso 3: aplicar deployment base de n8n

- Crear un nuevo recurso en Lens y pegar **n8n-deployment.yaml**.

### Paso 4: validar que n8n ya quedo operativo

Validar en Lens:
- `Workloads > Deployments`: confirmar que `n8n` esta corriendo.
- `Workloads > Pods`: confirmar que el pod esta en `Running`.
- `Network > Services`: confirmar que el servicio existe y tomar el puerto publicado.

Prueba de acceso:
- Abrir en el navegador la IP publica del master con el puerto de n8n.
- Ejemplo: `100.31.60.195:30567`

Si n8n no levanta y usa `efs-pvc-ia`, primero confirmar que el driver `aws-efs-csi-driver` siga instalado y en estado `Running` en `kube-system`.

## Proyecto 4.1 "Monitor de n8n" - Alertas operativas (K8s API + correo)

Este bloque va despues del despliegue base. Aqui n8n ya debe estar funcionando antes de activar el monitoreo.

Objetivo:
- Dar permisos de solo lectura a n8n para consultar el API interno de Kubernetes.
- Generar un token para consumir ese API.
- Importar o crear el workflow que envia alertas por correo.

### Paso 1: aplicar RBAC del monitor de n8n

Lo mas practico en tu flujo actual es hacerlo desde Lens.

#### Opcion recomendada: desde Lens

- Ir a `default`.
- Abrir `Create Resource`.
- Pegar el contenido de **04-N8N/n8n-monitor-rbac.yaml** y guardar.
- Luego ir a `Workloads > Deployments > n8n`.
- Reiniciar el deployment desde el menu de acciones si aun no toma la nueva ServiceAccount.

#### Opcion alternativa: conectado al master con kubectl

```bash
kubectl rollout restart deployment n8n -n default
kubectl rollout status deployment n8n -n default
```

Resultado esperado:
- Se crea la ServiceAccount `n8n-monitor`.
- Queda activo el `ClusterRoleBinding` de solo lectura.
- El deployment de n8n reinicia usando esa ServiceAccount.

### Paso 2: generar token para la ServiceAccount

```bash
kubectl -n default create token n8n-monitor
```

Guardar el token. Se usa en credenciales HTTP de n8n con este formato:

- Header Name: `Authorization`
- Header Value: `Bearer <TOKEN>`

### Paso 3: configurar workflow de alertas en n8n

La forma recomendada es importar el JSON que ya existe.

#### Opcion recomendada: importar el workflow JSON

Archivo disponible:
- **04-N8N/n8n-workflow-alertas-operativas.json**

En n8n:
1. Ir a `Workflows`.
2. Seleccionar `Import from File`.
3. Cargar **04-N8N/n8n-workflow-alertas-operativas.json**.
4. Asignar la credencial HTTP Header Auth para Kubernetes.
5. Asignar la credencial SMTP para correo.
6. Revisar el nodo `Send Email` y ajustar `fromEmail` y `toEmail`.
7. Guardar y activar el workflow.

#### Opcion alternativa: construirlo manualmente en n8n

Si prefieres crearlo desde cero, el flujo incluye:

1. `Cron` cada 2 minutos.
2. `HTTP Request` a `https://kubernetes.default.svc/api/v1/pods`.
3. `Function` para clasificar severidad (`CRITICAL`, `WARNING`).
4. `IF` para validar si hay alertas.
5. `Function` para construir asunto y cuerpo de correo.
6. `Send Email` para envio al equipo.

### Referencia detallada del procedimiento

Todo el paso a paso, incluyendo import del JSON y codigo de los nodos Function, esta en:

- `04-N8N/N8N-ALERTAS-OPERATIVAS-PASOS.md`

Si en el nodo HTTP aparece error de certificado interno del cluster, habilita `Ignore SSL Issues` en ese nodo.

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
ssh -i "testKey.pem" -L 11434:127.0.0.1:11434 ubuntu@100.31.60.195 -N
```

- **Terminal B (PC -> Master):** entrar al master y abrir `port-forward`
```bash
ssh -i "testKey.pem" ubuntu@100.31.60.195
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
Se recomienda desplegar Kafka con Strimzi porque ya esta probado en este proyecto.

Archivo usado en este proyecto:
- `06-KAFKA/strimzi-deployment.yaml`

### Paso 1 - Validar que Strimzi Operator ya exista

En shell conectado al master:

```bash
kubectl -n default get deploy,pods | grep -i strimzi
kubectl get crd | grep -i kafka
```

Si ves `strimzi-cluster-operator` en Running y CRDs como `kafkas.kafka.strimzi.io`, no reinstales Strimzi.

### Paso 2 - Crear Kafka desde Lens (recomendado)

1. Abre Lens y entra al cluster.
2. Usa namespace `default`.
3. Ve a `Create Resource`.
4. Pega o carga el archivo `06-KAFKA/strimzi-deployment.yaml`.
5. Aplica el recurso.
6. En Lens valida que aparezcan:
   - `Kafka` con nombre `my-cluster`.
   - `KafkaNodePool` con nombre `mixed`.
7. Ve a `Pods` y espera que `my-cluster-mixed-0` este en `Running`.

### Paso 3 - Alternativa por shell (si no quieres usar Create Resource)

```bash
kubectl apply -f 06-KAFKA/strimzi-deployment.yaml
kubectl -n default get kafka
kubectl -n default get kafkanodepools
kubectl -n default get pods
```

### Paso 4 - Pruebas funcionales por consola (shell al cluster)

Cuando `my-cluster-mixed-0` este `Running`, ejecuta:

```bash
kubectl -n default exec my-cluster-mixed-0 -- /opt/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --topic prueba-kafka --partitions 1 --replication-factor 1

kubectl -n default exec my-cluster-mixed-0 -- /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092

echo "hola" | kubectl -n default exec -i my-cluster-mixed-0 -- /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic prueba-kafka

kubectl -n default exec my-cluster-mixed-0 -- /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic prueba-kafka --from-beginning --max-messages 1
```

Resultado esperado:
- Se crea el topic `prueba-kafka`.
- El consumer imprime el mensaje `hola`.

Comandos de chequeo rapido:

```bash
kubectl -n default get kafka
kubectl -n default get kafkanodepools
kubectl -n default get pods
kubectl -n default get svc | grep my-cluster
```

Nota de laboratorio:
- `storage: ephemeral` es ideal para pruebas rapidas.
- Para produccion cambia a `persistent-claim`.

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