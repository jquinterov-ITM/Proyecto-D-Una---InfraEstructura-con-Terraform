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
   - Por defecto, el servicio es interno. Para exponerlo fuera del clúster, revisa la documentación de Bitnami o modifica el tipo de servicio a `NodePort` o `LoadBalancer`.

5. **Desinstalar (si es necesario):**
   ```bash
   helm uninstall kafka
   ```

## Personalización
Puedes crear un archivo `values.yaml` para personalizar la cantidad de brokers, recursos, contraseñas, etc. Consulta la documentación oficial:
https://artifacthub.io/packages/helm/bitnami/kafka

---
**Recomendación:** Usar el despliegue en K3s para mayor facilidad de administración y escalabilidad.
