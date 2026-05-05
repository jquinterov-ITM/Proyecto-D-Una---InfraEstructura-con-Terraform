# Implementacion de alertas operativas n8n (K8s API + correo)

Este plan implementa monitoreo de pods clave usando el API de Kubernetes y envio de alertas por correo desde n8n.

## Estado aplicado por el agente

1. n8n ya usa la ServiceAccount de monitoreo.
2. n8n ya tiene automount del token habilitado.
3. Ya existe manifiesto RBAC listo para aplicar.

Archivos involucrados:
- 04-N8N/n8n-deployment.yaml
- 04-N8N/n8n-monitor-rbac.yaml

## Precondicion

Antes de este documento, el deployment base de n8n ya debe estar creado y funcionando.

Validaciones minimas antes de seguir:
- `n8n` debe aparecer en `Running`.
- El PVC `efs-pvc-ia` debe estar en `Bound`.
- El driver `aws-efs-csi-driver` debe seguir instalado en `kube-system`.

## Paso 1 - Aplicar manifiestos del monitor en cluster (Intervencion tuya)

Opcion recomendada: hacerlo desde Lens para mantener el mismo flujo visual del resto del proyecto.

Desde Lens:
1. Ir al namespace `default`.
2. Abrir `Create Resource`.
3. Pegar **04-N8N/n8n-monitor-rbac.yaml** y guardar.
4. Revisar `Workloads > Deployments > n8n`.
5. Si hace falta, reiniciar el deployment de `n8n` desde Lens.

Opcion alternativa: ejecutarlo en el master de K3s o en tu terminal con kubectl configurado:

```bash
kubectl apply -f 04-N8N/n8n-monitor-rbac.yaml
kubectl apply -f 04-N8N/n8n-deployment.yaml
kubectl rollout restart deployment n8n -n default
kubectl rollout status deployment n8n -n default
```

Resultado esperado:
- ServiceAccount creada.
- Binding RBAC activo.
- Pod de n8n reiniciado con token montado.

## Paso 2 - Generar token de acceso para n8n (Intervencion tuya)

```bash
kubectl -n default create token n8n-monitor
```

Guarda el valor del token porque se usara en credenciales de n8n.

Importante al copiar token:
- Debe quedar en una sola linea.
- No usar comillas.
- No incluir simbolos extras.
- Si falla el header, genera un token nuevo y vuelvelo a pegar.

## Paso 3 - Crear credencial HTTP en n8n (Intervencion tuya)

En n8n:
1. Abre Credentials.
2. En Authentication del nodo HTTP Request selecciona `Credential Type generico`.
3. En Generic Auth Type selecciona `Header Auth`.
4. Crea credencial nueva (nombre sugerido: `K8s API Bearer Token`).
5. Si el formulario muestra `Name` y `Value`, usar:
  - Name: `Authorization`
  - Value: `Bearer <TOKEN_DEL_PASO_2>`
6. Si el formulario muestra `Header Name` y `Header Value`, usar:
  - Header Name: `Authorization`
  - Header Value: `Bearer <TOKEN_DEL_PASO_2>`

Nota:
- Base URL objetivo del API K8s: https://kubernetes.default.svc

Configuracion obligatoria del nodo HTTP Request - Get Pods:
- Method: `GET` (no usar POST)
- URL: `https://kubernetes.default.svc/api/v1/pods`
- Authentication: credencial del paso 3
- Response: `JSON`
- Ignore SSL Issues: `true`

Si el nodo HTTP presenta error de certificado, habilita Ignore SSL Issues en el nodo.

## Paso 3.1 - Configurar correo SMTP y hacer prueba (Intervencion tuya)

Este paso valida envio de correo antes de activar alertas automaticas.

En n8n:
1. Ve a `Credentials`.
2. Crea credencial SMTP (nombre sugerido: `SMTP Alertas DUNA`).
3. Configura segun tu proveedor.

Ejemplo Gmail (recomendado para prueba):
- Host: `smtp.gmail.com`
- Port: `465`
- Secure: `true`
- User: `tu_correo@gmail.com`
- Password: `contrasena_de_aplicacion`

Prueba minima:
1. Crea workflow temporal con `Manual Trigger` -> `Send Email`.
2. Selecciona credencial `SMTP Alertas DUNA`.
3. Configura:
  - To Email: tu correo destino
  - From Email: tu correo origen
  - Subject: `Prueba SMTP desde n8n`
  - Text: `Si recibes este correo, SMTP funciona correctamente.`
4. Ejecuta el workflow.

Resultado esperado:
- El nodo `Send Email` debe quedar en verde.
- Debe llegar correo de prueba.

## Paso 4 - Crear workflow de monitoreo (Intervencion tuya guiada)

### Opcion rapida (recomendada): importar workflow JSON

Ya existe un workflow exportable para importarlo directamente:

- `04-N8N/n8n-workflow-alertas-operativas.json`

En n8n:
1. Ve a `Workflows`.
2. Selecciona `Import from File`.
3. Carga `n8n-workflow-alertas-operativas.json`.
4. Mapea/selecciona credenciales:
  - HTTP Header Auth: `K8s API Bearer Token`
  - SMTP: `SMTP Alertas DUNA`
5. Ajusta correos en el nodo `Send Email` (`fromEmail`, `toEmail`).
6. Ejecuta una prueba manual del workflow completo.
7. Guarda y activa el workflow.

### Opcion manual: construir nodos uno a uno

Crea un workflow con estos nodos y nombres:

1. Cron
- Cada 2 minutos.

2. HTTP Request - Get Pods
- Method: GET
- URL: https://kubernetes.default.svc/api/v1/pods
- Authentication: credencial del Paso 3
- Response: JSON

3. Function - Build Alerts
- Codigo:

```javascript
const data = items[0].json;
const pods = data.items || [];

const targetMatchers = [/n8n/i, /ollama/i, /my-cluster/i, /strimzi/i];
const criticalReasons = new Set([
  'CrashLoopBackOff',
  'ImagePullBackOff',
  'ErrImagePull',
  'CreateContainerConfigError'
]);

const alerts = [];
const now = Date.now();

for (const pod of pods) {
  const name = pod?.metadata?.name || '';
  const namespace = pod?.metadata?.namespace || 'default';

  if (!targetMatchers.some((rx) => rx.test(name))) continue;

  const phase = pod?.status?.phase || 'Unknown';
  const cs = pod?.status?.containerStatuses || [];
  const waitingReasons = [];
  let restarts = 0;

  for (const c of cs) {
    restarts += c?.restartCount || 0;
    const reason = c?.state?.waiting?.reason;
    if (reason) waitingReasons.push(reason);
  }

  let severity = 'INFO';
  let reason = phase;

  const critical = waitingReasons.find((r) => criticalReasons.has(r));
  if (critical) {
    severity = 'CRITICAL';
    reason = critical;
  } else if (phase === 'Pending') {
    const created = new Date(pod?.metadata?.creationTimestamp || 0).getTime();
    const ageMin = created ? Math.floor((now - created) / 60000) : 0;
    if (ageMin >= 5) {
      severity = 'WARNING';
      reason = `Pending_${ageMin}m`;
    }
  } else if (restarts >= 3) {
    severity = 'WARNING';
    reason = `HighRestarts_${restarts}`;
  }

  if (severity !== 'INFO') {
    const fingerprint = `${namespace}/${name}:${reason}`;
    alerts.push({
      timestamp: new Date().toISOString(),
      namespace,
      pod: name,
      phase,
      restarts,
      reason,
      severity,
      fingerprint
    });
  }
}

return alerts.map((a) => ({ json: a }));
```

4. IF - Has Alerts
- Condicion: Number of items > 0

5. Function - Subject and Body
- Codigo:

```javascript
for (const item of items) {
  const a = item.json;
  a.emailSubject = `[DUNA][${a.severity}] Pod ${a.pod} en ${a.namespace}`;
  a.emailText = [
    `Severidad: ${a.severity}`,
    `Namespace: ${a.namespace}`,
    `Pod: ${a.pod}`,
    `Fase: ${a.phase}`,
    `Motivo: ${a.reason}`,
    `Reinicios: ${a.restarts}`,
    `Fecha: ${a.timestamp}`
  ].join('\n');
}
return items;
```

6. Send Email
- To: tu lista de correo
- Subject: {{ $json.emailSubject }}
- Text: {{ $json.emailText }}

## Paso 5 - Anti-spam (Intervencion tuya opcional, recomendado)

Para evitar correos repetidos cada 2 minutos:
1. Usa static data del workflow para guardar fingerprints enviados.
2. Reenvia solo si no existe fingerprint o si ya vencio TTL (ejemplo 60 min).

## Verificacion final (Intervencion tuya)

1. Fuerza un caso de prueba (por ejemplo imagen invalida en pod de laboratorio).
2. Confirma que llega correo CRITICAL.
3. Corrige el pod y valida que el siguiente ciclo ya no siga enviando ese incidente.

## Errores comunes y solucion rapida

1. Error: `Invalid character in header content ["Authorization"]`
- Causa: token con salto de linea o caracteres ocultos.
- Solucion: generar token nuevo y pegarlo en una sola linea en `Bearer <TOKEN>`.

2. Error: `self signed certificate in certificate chain`
- Causa: certificado interno del API de Kubernetes.
- Solucion: en el nodo HTTP Request activar `Ignore SSL Issues = true`.

3. Error: `401 Unauthorized`
- Causa: token invalido, expirado o mal pegado.
- Solucion: regenerar token y revisar que incluya prefijo `Bearer `.

4. Error: `403 Forbidden`
- Causa: RBAC incompleto o ServiceAccount no aplicada.
- Solucion: reaplicar `04-N8N/n8n-monitor-rbac.yaml` y reiniciar deployment `n8n`.

5. Error SMTP de autenticacion
- Causa: credenciales SMTP incorrectas.
- Solucion: revisar usuario/clave y, en Gmail, usar contrasena de aplicacion.

## Siguiente mejora sugerida

1. Enviar resumen horario (digest) de warnings.
2. Agregar notificacion de recuperacion (RESOLVED).
3. Agregar monitoreo de Jobs/CronJobs y consumo de nodo.
