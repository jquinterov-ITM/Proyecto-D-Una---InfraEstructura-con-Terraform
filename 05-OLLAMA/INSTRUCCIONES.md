# Instalación de Ollama

## Opción 1: Desplegar en K3s (recomendado)

1. Copia el archivo `ollama-deployment.yaml` a tu master o donde tengas `kubectl` configurado.
2. Ejecuta:
   ```bash
   kubectl apply -f ollama-deployment.yaml
   ```
3. Verifica el pod:
   ```bash
   kubectl get pods -l app=ollama
   ```
4. Verifica el servicio:
   ```bash
   kubectl get svc ollama
   ```
5. Por defecto es `ClusterIP`, así que se accede dentro del clúster con:
   ```text
   http://ollama:11434
   ```
6. Para probarlo desde tu máquina local, usa port-forward:
   ```bash
   kubectl port-forward svc/ollama 11434:11434
   ```
7. Luego abre:
   ```text
   http://localhost:11434
   ```

Recursos recomendados para empezar:

- CPU request: `1`
- Memoria request: `2Gi`
- CPU limit: `2`
- Memoria limit: `4Gi`

## Opción 2: Instalación manual en un Worker

1. Accede por SSH o SSM al worker donde quieras instalar Ollama.
2. Descarga e instala Ollama siguiendo la guía oficial:
   https://ollama.com/download
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   sudo systemctl start ollama
   sudo systemctl enable ollama
   ```
3. Asegúrate de que el puerto 11434 esté abierto en el Security Group para el tráfico necesario.
4. Puedes probar con:
   ```bash
   curl http://localhost:11434
   ```

## Recomendación rápida

Si todavía estás empezando, usa la opción de K3s con `port-forward` para pruebas y deja la instalación manual solo si necesitas ejecutar Ollama directamente en un worker.

---
**Recomendación:** Usar el despliegue en K3s para mayor flexibilidad y alta disponibilidad.
