#!/usr/bin/env bash
source "$(dirname "$0")/scripts/common.sh"
mode=${1:---plan}
case "$mode" in
 --plan) exec bash scripts/cost.sh --enforce ;;
 --local)
  for x in docker kind kubectl helm python3 curl; do need "$x"; done
  export KUBECONFIG="$ROOT/.state/kubeconfig-local"
  [[ ! -f .state/local-created ]] || fail 'Ya hay un lab local registrado. Ejecutar cleanup.sh --local --apply primero.'
  helm repo add istio https://istio-release.storage.googleapis.com/charts --force-update
  helm repo update
  helm show chart istio/istiod --version "$ISTIO_VERSION" >/dev/null
  kind create cluster --name "$LAB_ID" --kubeconfig "$KUBECONFIG" --wait 180s
  touch .state/local-created
  bash scripts/install-mesh.sh
  docker build -t cuentas:local app
  kind load docker-image cuentas:local --name "$LAB_ID"
  sed 's|IMAGE_PLACEHOLDER|cuentas:local|g' k8s/app.yaml | kubectl apply -f -
  kubectl apply -f k8s/mesh.yaml
  kubectl rollout status deployment/cuentas-v1 -n mesh-lab --timeout=180s
  kubectl rollout status deployment/cuentas-v2 -n mesh-lab --timeout=180s
  if [[ "$ENABLE_KIALI" == true ]]; then bash scripts/observability.sh local; fi
  echo 'Local preparado. Revisar compatibilidad del Kubernetes de kind con Istio. Continuar en README.'
  exit 0 ;;
 --aws) [[ ${2:-} == --apply ]] || fail 'Usar: bash setup.sh --aws --apply' ;;
 *) fail 'Opciones: --plan, --local, --aws --apply' ;;
esac
for x in aws eksctl gh kubectl helm python3 curl jq git flock; do need "$x"; done
[[ -f .env.lab ]] || fail 'Copiar y editar .env.lab.example como .env.lab'
[[ ! -f .state/aws.env ]] || fail 'Ya hay un intento AWS registrado. Revisar o limpiar antes de crear otra vez.'
exec 9>.state/aws-mutation.lock
flock -n 9 || fail 'Otra operación AWS está en curso'
assert_account
python3 scripts/cost.py --enforce
# Comprobaciones de versión y presupuesto antes de cualquier infraestructura facturable.
status=$(aws eks describe-cluster-versions --cluster-versions "$K8S_VERSION" --query 'clusterVersions[0].status' --output text)
[[ "$status" == STANDARD_SUPPORT ]] || fail "Kubernetes $K8S_VERSION no tiene soporte estándar. No crear EKS con tarifa extendida."
helm repo add istio https://istio-release.storage.googleapis.com/charts --force-update
helm repo update
helm show chart istio/istiod --version "$ISTIO_VERSION" >/dev/null
# No reutilizar ni borrar infraestructura preexistente con los nombres de esta prueba.
python3 scripts/preflight.py
bash scripts/github.sh
export OIDC_SUBJECT=$(cat .state/oidc-subject)
export ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
export EXPIRES_AT=$(python3 -c 'import time,os;print(int(time.time()+float(os.environ["LAB_HOURS"])*3600))')
export CREATED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for key in AWS_REGION EXPECTED_ACCOUNT_ID ACCOUNT_ID LAB_ID CLUSTER_NAME ECR_REPO ROLE_NAME ROLE_ARN GH_OWNER GH_REPO OIDC_SUBJECT EXPIRES_AT CREATED_AT LAB_HOURS; do printf 'export %s=%q\n' "$key" "${!key}"; done > .state/aws.env
chmod 600 .state/aws.env
# Si falla cualquier fase, no ocultar los recursos: conservar inventario y señalar limpieza.
trap 'rc=$?; if ((rc!=0)); then echo "Configuración interrumpida. No repetir creación. Ejecutar: bash cleanup.sh --aws --apply" >&2; fi' EXIT
bash scripts/budget.sh
if ! bash scripts/watchdog.sh; then
 [[ "$ALLOW_NO_TIMER" == true ]] || fail 'No se pudo armar el temporizador. No se ha creado EKS. Limpiar el intento y preparar systemd.'
 echo 'EXCEPCIÓN EXPLÍCITA: sin temporizador local. Eliminar manualmente al terminar.' >&2
fi
# Los recursos se etiquetan antes de crear. CFN propaga sus etiquetas cuando el tipo lo permite.
aws ecr create-repository --repository-name "$ECR_REPO" --image-tag-mutability IMMUTABLE --tags Key=proyecto,Value=mesh-lab Key=lab-id,Value="$LAB_ID" Key=owner,Value="$GH_OWNER" Key=expires-at,Value="$EXPIRES_AT"
python3 scripts/render-infra.py
aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://infra/generated/trust.json --tags Key=proyecto,Value=mesh-lab Key=lab-id,Value="$LAB_ID"
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name lab-deploy --policy-document file://infra/generated/permissions.json
provider="arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
if ! aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text | tr '\t' '\n' | grep -Fxq "$provider"; then
 fail 'Crear el proveedor GitHub OIDC compartido antes de continuar. Ver README sección OIDC y recuperación.'
fi
eksctl create cluster -f infra/generated/cluster.yaml
aws eks update-cluster-config --name "$CLUSTER_NAME" --upgrade-policy supportType=STANDARD
export KUBECONFIG="$ROOT/.state/kubeconfig-aws"
aws eks update-kubeconfig --name "$CLUSTER_NAME" --kubeconfig "$KUBECONFIG"
bash scripts/tag-and-limit.sh
bash scripts/install-mesh.sh
aws eks create-access-entry --cluster-name "$CLUSTER_NAME" --principal-arn "$ROLE_ARN" --type STANDARD --kubernetes-groups mesh-lab-deployers
if [[ "$ENABLE_KIALI" == true ]]; then bash scripts/observability.sh aws; fi
repo="$GH_OWNER/$GH_REPO"
for var in AWS_REGION ACCOUNT_ID CLUSTER_NAME ECR_REPO ROLE_ARN OIDC_SUBJECT EXPIRES_AT LAB_ID; do gh variable set "$var" --env lab --body "${!var}" --repo "$repo"; done
gh variable set LAB_ENABLED --env lab --body true --repo "$repo"
# Botón independiente de tu computadora, con permisos para eliminar solo los recursos inventariados.
bash scripts/enable-delete-button.sh
kubectl get nodes
echo 'Infraestructura lista. Hacer commit/push y ejecutar build-scan-deploy en GitHub. No olvidar DELETE al terminar.'
