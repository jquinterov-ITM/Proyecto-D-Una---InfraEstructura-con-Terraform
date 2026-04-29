# Instalación de Apache Kafka en K3s con Strimzi

Esta guía usa Strimzi como ruta principal porque evita los problemas de imagen que tuvimos con Bitnami y deja Kafka administrado de forma nativa en Kubernetes.

## Requisitos previos
- Clúster K3s funcionando.
- `kubectl` apuntando al clúster o acceso por SSH al master.
- Lens instalado si prefieres usar GUI.

## Paso 1. Instalar el operador de Strimzi

### Opción A: con Lens
1. Abre Lens.
2. Ve a `Helm` > `Repositories`.
3. Agrega este repositorio:
   ```text
   https://strimzi.io/charts/
   ```
4. Busca `strimzi-kafka-operator` en `Helm` > `Charts`.
5. Instálalo en el namespace `default`.

### Opción B: con Helm en el master
```bash
helm repo add strimzi https://strimzi.io/charts/
helm repo update
helm install strimzi-operator strimzi/strimzi-kafka-operator -n default
```

## Paso 2. Crear el clúster Kafka

El manifiesto está en `06-KAFKA/strimzi-deployment.yaml`.

### En Lens
1. Ve a `+` > `Create Resource`.
2. Pega el contenido de `strimzi-deployment.yaml`.
3. Guarda el recurso.

### Con kubectl
```bash
kubectl apply -f 06-KAFKA/strimzi-deployment.yaml
```

## Paso 3. Validar el despliegue

```bash
kubectl get kafka -n default
kubectl get pods -n default
kubectl get svc -n default
```

Espera a que los pods estén en `Running`.

## Paso 4. Probar Kafka desde dentro del clúster

```bash
kubectl exec -it <NOMBRE_DEL_POD_KAFKA> -n default -- bash
```

Dentro del contenedor:
```bash
bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic prueba
bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

## Paso 5. Probar productor y consumidor

Productor:
```bash
echo "hola desde Strimzi" | kubectl exec -i <NOMBRE_DEL_POD_KAFKA> -n default -- bash -c 'bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic prueba'
```

Consumidor:
```bash
kubectl exec -it <NOMBRE_DEL_POD_KAFKA> -n default -- bash -c 'bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic prueba --from-beginning --max-messages 1'
```

## Paso 6. Desinstalar

```bash
kubectl delete -f 06-KAFKA/strimzi-deployment.yaml
helm uninstall strimzi-operator -n default
```

## Enlace oficial
- https://strimzi.io/docs/operators/latest/full/deploying.html

**Recomendación:** usa Strimzi para el laboratorio; es más estable que seguir peleando con tags de Bitnami.
