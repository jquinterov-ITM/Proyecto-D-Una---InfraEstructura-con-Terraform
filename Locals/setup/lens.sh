# K3S config file for Lens
# Descargar el archivo de configuracion
ssh -i "testKey.pem" ubuntu@54.162.171.212 "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s-config.yaml


# K3S SSH Tunnel
#Abrir tunel SSH desde otra terminal
ssh -i "testKey.pem" -L 6443:127.0.0.1:6443 ubuntu@54.162.171.212 -N
