#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
export AWS_PAGER="" AWS_CLI_AUTO_PROMPT=off
if [[ -f .env.lab ]]; then set -a; source .env.lab; set +a
else set -a; source .env.lab.example; set +a; fi
: "${LAB_ID:=mocotoyo-mesh-demo}"
[[ "$LAB_ID" =~ ^[a-z][a-z0-9-]{3,35}$ ]] || { echo 'LAB_ID inválido' >&2; exit 1; }
export CLUSTER_NAME="$LAB_ID" ECR_REPO="$LAB_ID/cuentas" ROLE_NAME="$LAB_ID-github"
export AWS_DEFAULT_REGION="$AWS_REGION"
mkdir -p .state infra/generated evidencias
chmod 700 .state
need(){ command -v "$1" >/dev/null || { echo "Falta herramienta: $1" >&2; exit 1; }; }
fail(){ echo "ERROR: $*" >&2; exit 1; }
assert_account(){
 local actual
 actual=$(aws sts get-caller-identity --query Account --output text)
 [[ "$actual" == "$EXPECTED_ACCOUNT_ID" ]] || fail "Cuenta incorrecta. Esperada $EXPECTED_ACCOUNT_ID, actual $actual"
 export ACCOUNT_ID="$actual"
}
aws_state(){
 [[ -f .state/aws.env ]] || fail 'No hay estado AWS. Consultar docs/RECUPERACION.md'
 set -a; source .state/aws.env; set +a
 export AWS_DEFAULT_REGION="$AWS_REGION" KUBECONFIG="$ROOT/.state/kubeconfig-aws"
 assert_account
}
kube_state(){
 local mode=${1:-local}
 [[ "$mode" == local || "$mode" == aws ]] || fail 'Modo: local o aws'
 export KUBECONFIG="$ROOT/.state/kubeconfig-$mode"
 [[ -f "$KUBECONFIG" ]] || fail "No existe kubeconfig $mode"
 if [[ "$mode" == aws ]]; then aws_state; fi
}
