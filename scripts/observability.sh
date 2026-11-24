#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
kube_state "${1:-local}"
# Los addons se descargan del mismo release de Istio, no de master.
# Son ejemplos oficiales para evaluación, sin almacenamiento durable.
for addon in prometheus kiali; do
 curl --fail --location --retry 2 "https://raw.githubusercontent.com/istio/istio/$ISTIO_VERSION/samples/addons/$addon.yaml" -o "infra/generated/$addon.yaml"
 kubectl apply -f "infra/generated/$addon.yaml"
done
# Limitar retención en Prometheus. Los datos desaparecen al eliminar el pod/clúster.
kubectl get deployment prometheus -n istio-system -o json | python3 -c '
import json,sys
obj=json.load(sys.stdin); args=obj["spec"]["template"]["spec"]["containers"][0].get("args",[])
args=[a for a in args if not a.startswith("--storage.tsdb.retention.")]
args += ["--storage.tsdb.retention.time=1h","--storage.tsdb.retention.size=256MB"]
print(json.dumps({"spec":{"template":{"spec":{"containers":[{"name":obj["spec"]["template"]["spec"]["containers"][0]["name"],"args":args}]}}}}))
' > infra/generated/prometheus-retention.json
kubectl patch deployment prometheus -n istio-system --type=strategic --patch-file infra/generated/prometheus-retention.json
kubectl set resources deployment/prometheus -n istio-system --requests=cpu=50m,memory=128Mi --limits=cpu=300m,memory=512Mi
kubectl set resources deployment/kiali -n istio-system --requests=cpu=50m,memory=128Mi --limits=cpu=300m,memory=384Mi
kubectl rollout status deployment/prometheus -n istio-system --timeout=180s
kubectl rollout status deployment/kiali -n istio-system --timeout=180s
kubectl get svc prometheus kiali -n istio-system
