#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
kube_state "${1:-local}"
folder="evidencias/$(date -u +%Y%m%dT%H%M%SZ)";mkdir -p "$folder"
kubectl get pods -A -o wide > "$folder/pods.txt"
kubectl get vs,dr,peerauthentication,authorizationpolicy -n mesh-lab -o yaml > "$folder/mesh.yaml"
kubectl get svc -A -o wide > "$folder/services.txt"
if command -v istioctl >/dev/null; then istioctl proxy-status > "$folder/proxy-status.txt"; else echo 'Instalar istioctl de la misma versión para capturar proxy-status' > "$folder/proxy-status-pendiente.txt"; fi
python3 scripts/traffic.py --count 200 > "$folder/canary.json"
echo "Evidencias reales en $folder. Revisar metadatos antes de publicarlas."
