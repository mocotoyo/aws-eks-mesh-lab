#!/usr/bin/env bash
source "$(dirname "$0")/scripts/common.sh"
mode=${1:---plan}
case "$mode" in
 --local)
  [[ ${2:-} == --apply ]] || fail 'Usar cleanup.sh --local --apply'
  [[ -f .state/local-created ]] || fail 'No hay lab local registrado'
  kind delete cluster --name "$LAB_ID"
  rm -f .state/local-created .state/kubeconfig-local
  exit 0 ;;
 --aws|--plan) aws_state ;;
 *) fail 'Opciones --local --apply, --aws --apply o --plan' ;;
esac
echo "DELETE: cuenta=$ACCOUNT_ID región=$AWS_REGION clúster=$CLUSTER_NAME ECR=$ECR_REPO rol=$ROLE_NAME"
[[ "$mode" == --aws && ${2:-} == --apply ]] || { echo 'Solo vista previa. Para eliminar: bash cleanup.sh --aws --apply';exit 0; }
exec 9>.state/aws-mutation.lock
flock -n 9 || { echo 'Setup/DELETE sigue en curso. Reintentar al finalizar.' >&2; exit 75; }
# Mejor esfuerzo para bloquear nuevos despliegues. Su fallo no detiene la eliminación AWS.
if command -v gh >/dev/null; then gh variable set LAB_ENABLED --env lab --repo "$GH_OWNER/$GH_REPO" --body false || echo 'No se pudo deshabilitar el pipeline en GitHub' >&2; fi
if [[ -f .state/delete-targets.json ]]; then
 export LAB_DELETE_TARGETS=$(cat .state/delete-targets.json)
 python3 scripts/delete-cloud.py
else
 # Recuperación de setup parcial. eksctl maneja stacks del nombre exclusivo reservado por preflight.
 python3 scripts/partial-delete.py
fi
python3 scripts/delete-delete-role.py
bash scripts/audit.sh
if [[ -f .state/timer-unit ]]; then
 unit=$(cat .state/timer-unit)
 systemctl --user stop "$unit.timer" || echo 'Revisar timer local' >&2
fi
mv .state/aws.env ".state/aws-deleted-$(date -u +%Y%m%dT%H%M%SZ).env"
echo 'DELETE finalizado. Presupuesto de alertas y proveedor OIDC compartido conservados. Revisar facturación posterior.'
