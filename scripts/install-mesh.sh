#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
[[ -n ${KUBECONFIG:-} && -f "$KUBECONFIG" ]] || fail 'Invocar desde setup con kubeconfig dedicado'
server_minor=$(kubectl version -o json | python3 -c 'import json,sys,re;print(re.sub(r"[^0-9]","",json.load(sys.stdin)["serverVersion"]["minor"]))')
if [[ "$ISTIO_VERSION" == 1.32.* ]]; then ((server_minor>=33 && server_minor<=37)) || fail 'Istio 1.32 requiere Kubernetes soportado por su matriz. Revisar antes de instalar.'; fi
helm repo add istio https://istio-release.storage.googleapis.com/charts --force-update
helm repo update
helm show chart istio/istiod --version "$ISTIO_VERSION" >/dev/null
helm upgrade --install istio-base istio/base -n istio-system --create-namespace --version "$ISTIO_VERSION" --set defaultRevision=default --wait --timeout 5m
helm upgrade --install istiod istio/istiod -n istio-system --version "$ISTIO_VERSION" --set pilot.resources.requests.cpu=100m --set pilot.resources.requests.memory=256Mi --wait --timeout 5m
kubectl apply -f k8s/admin/namespaces.yaml
helm upgrade --install istio-ingressgateway istio/gateway -n istio-ingress --version "$ISTIO_VERSION" --set service.type=ClusterIP --set labels.istio=ingressgateway --set serviceAccount.name=mesh-gateway --set serviceAccount.create=true --set resources.requests.cpu=50m --set resources.requests.memory=96Mi --wait --timeout 5m
kubectl apply -f k8s/admin/rbac.yaml
kubectl get pods -n istio-system
