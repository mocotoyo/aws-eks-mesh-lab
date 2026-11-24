#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
kube_state "${1:-local}"
IMAGE=$(kubectl get deployment cuentas-v1 -n mesh-lab -o jsonpath='{.spec.template.spec.containers[0].image}')
for sa in pagos no-autorizado; do
 kubectl create serviceaccount "$sa" -n mesh-lab --dry-run=client -o yaml | kubectl apply -f -
 kubectl run "$sa" -n mesh-lab --image="$IMAGE" --restart=Never --overrides="{\"spec\":{\"serviceAccountName\":\"$sa\"}}" --dry-run=client -o yaml --command -- python -c 'import time;time.sleep(7200)' | kubectl apply -f -
 kubectl wait -n mesh-lab --for=condition=Ready "pod/$sa" --timeout=180s
done
kubectl apply -f k8s/authorization.yaml
# Esperar propagación y reintentar aserciones, sin concluir antes de recibir lo esperado.
check(){
 local sa=$1 method=$2 expected=$3
 for attempt in {1..12}; do
  if kubectl exec -i -n mesh-lab "$sa" -c "$sa" -- python - "$method" http://cuentas.mesh-lab.svc.cluster.local:8080/ "$expected" < scripts/check-http.py; then return 0; fi
  sleep 2
 done
 return 1
}
check pagos GET 200
check pagos POST 403
check no-autorizado GET 403
echo 'Pruebas de autorización aprobadas. Quitar solo esta política: kubectl delete -f k8s/authorization.yaml'
