# Instalación de Apache Kafka en K3s (Kubernetes)

Esta guía te ayudará a desplegar un clúster de Kafka (y Zookeeper) en tu entorno K3s usando Helm.

## Requisitos previos
- Clúster K3s funcionando
- `kubectl` configurado
- [Helm](https://helm.sh/) instalado

## Pasos para instalar Kafka

1. **Agregar el repositorio de Bitnami:**
   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   ```

2. **Instalar Kafka (incluye Zookeeper):**
   ```bash
   helm install kafka bitnami/kafka
   ```

3. **Verificar el estado de los pods:**
   ```bash
   kubectl get pods -l app.kubernetes.io/name=kafka
   ```

4. **Acceder a Kafka:**
   - Por defecto, el servicio es interno. Para exponerlo fuera del clúster, revisa la documentación de Bitnami o modifica el tipo de servicio a `NodePort` o `LoadBalancer` en `Kafka_values.yaml`.
   - Si usas `NodePort`, revisa el puerto publicado con `kubectl get svc` y accede desde la IP del nodo.
   - Si usas `LoadBalancer`, espera la IP externa del servicio antes de probar la conexión.

5. **Desinstalar (si es necesario):**
   ```bash
   helm uninstall kafka
   ```

## Personalización
Puedes crear un archivo `values.yaml` para personalizar la cantidad de brokers, recursos, contraseñas, etc. Consulta la documentación oficial:
https://artifacthub.io/packages/helm/bitnami/kafka

## Ruta Strimzi

Si decides usar Strimzi, sigue esta secuencia simple:

1. Instala el operador de Strimzi desde Helm o con el manifiesto oficial.
2. Aplica el recurso `Kafka` del clúster.
3. Verifica los pods:
   ```bash
   kubectl get pods
   kubectl get kafka
   ```
4. Usa el bootstrap service que crea Strimzi para conectarte desde dentro del clúster.
5. Si necesitas acceso externo, define un listener externo en el manifiesto de Kafka.

Enlace oficial de Strimzi:

- https://strimzi.io/docs/operators/latest/full/deploying.html

---
**Recomendación:** Usar el despliegue en K3s para mayor facilidad de administración y escalabilidad.
