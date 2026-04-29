# Plan de Reanudacion del Proyecto D-Una

## Objetivo
Reanudar el trabajo en una sesion nueva o con otra IA sin dar mucho contexto. El proyecto es una infraestructura en AWS con K3s, EFS, n8n, Ollama y Kafka.

## Estado actual resumido
- Terraform de infraestructura base ya se ejecuto en:
  - `01-K3S` para el cluster K3s.
  - `02-PERSISTENCE` para EFS/Persistencia.
- Se obtuvo el kubeconfig del master con SSH.
- El cluster K3s esta corriendo en AWS.
- Se uso Lens para cargar recursos en Kubernetes.
- Kafka ya se valido con Strimzi y se creo el topic `prueba-kafka`.
- Ollama ya fue corregido para usar una imagen mas pequena.
- n8n fue simplificado a menos archivos y usa EFS.

## Datos importantes
- Master AWS: `52.90.26.223`
- Usuario SSH: `ubuntu`
- Key SSH: `01-K3S/testKey.pem`
- Namespace usado para la mayoria de recursos: `default`
- PVC EFS usado por las apps: `efs-pvc-ia`
- Pod de Kafka validado: `my-cluster-mixed-0`
- Cluster Kafka Strimzi: `my-cluster`

## Archivos clave del repo
- `Implementacion.md`
- `03-K3S-Storage/pv-pvc-k3s.yaml`
- `04-N8N/n8n-secret.yaml`
- `04-N8N/n8n-deployment.yaml`
- `05-OLLAMA/ollama-deployment.yaml`
- `06-KAFKA/strimzi-deployment.yaml`
- `06-KAFKA/Kafka_values.yaml` (ya no es la ruta principal, pero queda como referencia)
- `Locals/setup/lens.sh`

## Reglas de trabajo
- No asumir que `kubectl` existe en Windows local; si hace falta usar Kubernetes, hacerlo por SSH al master.
- Preferir archivos YAML versionados y `kubectl apply -f` sobre crear recursos manualmente en Lens.
- Usar Lens solo para verificar estados, pods, servicios y logs.
- Mantener las respuestas en espanol y con pasos practicos.

## Flujo recomendado si se destruye y se recrea todo
1. Ejecutar `terraform destroy` en `02-PERSISTENCE`.
2. Ejecutar `terraform destroy` en `01-K3S`.
3. Recrear primero `01-K3S`.
4. Obtener el kubeconfig del master.
5. Configurar Lens con el kubeconfig y el tunel SSH.
6. Ejecutar `02-PERSISTENCE`.
7. Aplicar `03-K3S-Storage/pv-pvc-k3s.yaml`.
8. Aplicar `04-N8N/n8n-secret.yaml` y `04-N8N/n8n-deployment.yaml`.
9. Aplicar `05-OLLAMA/ollama-deployment.yaml`.
10. Instalar Strimzi y aplicar `06-KAFKA/strimzi-deployment.yaml`.
11. Validar pods, servicios y logs.

## Comandos utiles
### Obtener kubeconfig del master
```bash
ssh -i "01-K3S/testKey.pem" ubuntu@52.90.26.223 "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s-config.yaml
```

### Abrir tunel SSH para Lens
```bash
ssh -i "01-K3S/testKey.pem" -L 6443:127.0.0.1:6443 ubuntu@52.90.26.223 -N
```

### Verificar Kafka dentro del master
```bash
kubectl -n default get pods | grep my-cluster
kubectl -n default exec my-cluster-mixed-0 -- /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
kubectl -n default exec my-cluster-mixed-0 -- /opt/kafka/bin/kafka-topics.sh --describe --bootstrap-server localhost:9092 --topic prueba-kafka
```

## Kafka con Strimzi
### CRs que deben existir
- `Kafka` con nombre `my-cluster`
- `KafkaNodePool` con nombre `mixed`
- `entityOperator` habilitado

### YAML minimo esperado
- `Kafka` define la version y la configuracion global.
- `KafkaNodePool` define `replicas`, `roles` y `storage`.
- Para pruebas se puede usar `storage: ephemeral`.

### Validacion rapida
- `kubectl -n default get kafka`
- `kubectl -n default get kafkanodepools`
- `kubectl -n default get pods`
- `kubectl -n default get svc | grep my-cluster`

## OLLAMA
- Imagen usada: `ollama/ollama:0.1.48`
- Motivo: reducir uso de disco y evitar errores de extraccion.
- Montaje recomendado: EFS en `/root/.ollama`
- Validacion:
```bash
kubectl port-forward svc/ollama 11434:11434 -n default
curl http://localhost:11434/api/tags
```

## N8N
- Usar un deployment simple y un secret.
- Mantener el PVC `efs-pvc-ia`.
- Validar con el service NodePort en el navegador.

## Si una nueva IA retoma el trabajo
1. Leer este archivo primero.
2. Leer `Implementacion.md`.
3. Revisar el estado real con `kubectl get pods -n default` por SSH al master.
4. No rehacer manualmente lo que ya este automatizado en YAML.
5. Si se va a limpiar todo, borrar primero con Terraform y luego recrear en orden.

## Notas finales
- El objetivo ahora es reducir pasos manuales en Lens.
- La mayor parte del flujo ya deberia quedar en Terraform, YAML y Helm.
- Lens queda como visor y herramienta de diagnostico, no como paso principal de despliegue.
