# K3S config file for Lens
# Descargar el archivo de configuracion
ssh -i "Key Pair Duna.pem" ubuntu@100.52.182.228 "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s-config.yaml


# K3S SSH Tunnel
#Abrir tunel SSH desde otra terminal
ssh -i "Key Pair Duna.pem" -L 6443:127.0.0.1:6443 ubuntu@100.52.182.228 -N

#conectarme al master
ssh -i "Key Pair Duna.pem" ubuntu@100.52.182.228

# dentro del master
#Ver espacio en todos los discos:
df -h

#Ver espacio usado en el directorio donde containerd extrae imágenes (muestra carpetas grandes):
sudo du -sh /var/lib/rancher/k3s/agent/* 2>/dev/null | sort -h | tail -n 20

#Ver tamaños de snapshots/overlayfs (donde falló la extracción):
sudo du -sh /var/lib/rancher/k3s/agent/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/* 2>/dev/null | sort -h | tail -n 20

#Ver espacio libre del sistema raíz:
sudo df -h /