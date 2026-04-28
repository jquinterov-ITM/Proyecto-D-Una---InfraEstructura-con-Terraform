# TODO - Proyecto AWS K3S - D-Una

## Progreso
- [x] Pinear imagen de n8n y mover secretos a `04-N8N/n8n-secret.yaml`
- [x] Parametrizar `04-N8N/n8n-deployment.yaml` con `n8n-config.yaml` y `n8n-pvc.yaml`


## Fase 1 - MVP funcional
- Mantener el master público como punto de administración.
- Mantener n8n expuesto por NodePort para pruebas del laboratorio.
- Dejar la IP abierta por ahora para facilitar el acceso de quienes usarán el proyecto como ejemplo.
- Verificar que el acceso a n8n se haga por el puerto 30567.
- Confirmar que n8n conecta correctamente con RDS.
- Confirmar que n8n usa EFS para persistencia.

## Fase 2 - Ruta Kafka A: Bitnami con Helm
- Verificar que el clúster K3s esté funcionando.
- Revisar que `kubectl` apunte al clúster correcto.
- Agregar el repositorio Helm de Bitnami.
- Instalar Kafka con `helm install kafka bitnami/kafka`.
- Revisar el estado de los pods.
- Confirmar si Kafka quedó accesible solo dentro del clúster.
- Ajustar `Kafka_values.yaml` si hace falta más memoria, CPU o réplicas.
- Si Kafka va a usarse de verdad, evaluar persistencia antes de avanzar.
- Si esta ruta funciona, documentar el comando exacto de instalación y verificación.
- Definir cómo se conectará n8n a este Kafka de laboratorio.

## Fase 3 - Ruta Kafka B: Strimzi
- Confirmar que Strimzi se instalará con el método correcto.
- Instalar primero el Cluster Operator de Strimzi.
- Verificar que existan las CRD de Kafka.
- Aplicar el manifiesto de Kafka en `strimzi_deployment.yaml`.
- Confirmar que los pods del operador y del cluster estén en Running.
- Crear topics y usuarios si hace falta.
- Validar cómo se conectará n8n a Kafka.
- Revisar si se expondrá Kafka con NodePort, LoadBalancer o solo interno.
- Confirmar que la ruta use los archivos correctos: operador, Kafka, topics y usuarios.
- Definir si se usará el manifest de ejemplo o una instalación guiada paso a paso.

## Fase 4 - Ordenar acceso y despliegue
- Revisar si conviene mover n8n de NodePort a Ingress.
- Evaluar uso de ALB para publicar n8n de forma más limpia.
- Documentar claramente cuál es el camino de acceso recomendado.
- Actualizar el README para evitar confusión entre ALB, NodePort y acceso al master.

## Fase 5 - Endurecimiento básico
- Restringir SSH y acceso al master a una IP específica o VPN si deja de ser necesario abrirlo.
- Revisar reglas de Security Groups para reducir exposición innecesaria.
- Sustituir valores sensibles hardcodeados por variables o secretos gestionados.

## Fase 5.1 - Seguridad básica aplicada
- Documentar que el master solo debe abrirse para administración puntual.
- Confirmar que el acceso SSH no quede expuesto al mundo cuando pase a uso estable.

## Fase 6 - n8n
- Fijar una versión estable de la imagen en lugar de usar `latest`.
- Pasar secretos a un mecanismo más seguro.
- Parametrizar host, base de datos y credenciales.
- Revisar si se necesita un PVC/StorageClass más claro para persistencia.

## Fase 7 - Ollama
- Definir si Ollama correrá dentro de K3s o como servicio aparte.
- Fijar versión de imagen.
- Revisar recursos de CPU y memoria según el modelo que se usará.
- Decidir si necesita almacenamiento persistente o solo temporal.
- Documentar cómo se consumirá desde n8n u otras apps.

## Fase 8 - Infraestructura
- Corregir si los workers realmente usan subredes distintas.
- Revisar si hace falta más de un NAT Gateway.
- Evaluar si el master debería seguir siendo único o si se agregará redundancia.
- Ordenar los nombres de recursos y tags para que sean consistentes.

## Fase 9 - Documentación
- Actualizar los diagramas para que reflejen el estado real del proyecto.
- Alinear README, docs e implementación.
- Separar claramente lo que ya está implementado de lo que es idea futura.
- Agregar un flujo simple de “cómo acceder” para nuevos usuarios.
- Añadir una sección de Kafka con dos rutas: Bitnami y Strimzi.

## Backlog
- Evaluar monitoreo y logs.
- Evaluar backups automáticos de RDS.
- Revisar rotación de secretos.
- Considerar HTTPS cuando el proyecto pase de laboratorio a demo formal.