#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need gh; need git; need jq
gh auth status >/dev/null
export REPO="$GH_OWNER/$GH_REPO"
# Primero GitHub. Un fallo de permisos ocurre antes de crear EKS.
if ! gh repo view "$REPO" >/dev/null 2>&1; then gh repo create "$REPO" "--$GH_VISIBILITY" --description 'Prueba AWS EKS e Istio de mocotoyo'; fi
[[ $(gh api "repos/$REPO" --jq .permissions.admin) == true ]] || fail 'Se requieren permisos admin en el repositorio de prueba'
gh api --method PUT "repos/$REPO/environments/lab" --input - <<'JSON'
{"deployment_branch_policy":{"protected_branches":false,"custom_branch_policies":true}}
JSON
if ! gh api "repos/$REPO/environments/lab/deployment-branch-policies" --jq '.branch_policies[].name' | grep -Fxq main; then
 gh api --method POST "repos/$REPO/environments/lab/deployment-branch-policies" -f name=main -f type=branch
fi
# Subject explícito: IDs inmutables, entorno y rama. No depende del formato repo por defecto.
gh api --method PUT "repos/$REPO/actions/oidc/customization/sub" --input - <<'JSON'
{"use_default":false,"include_claim_keys":["repository_owner_id","repository_id","environment","ref"]}
JSON
export GH_OWNER_ID=$(gh api "repos/$REPO" --jq .owner.id)
export GH_REPO_ID=$(gh api "repos/$REPO" --jq .id)
export OIDC_SUBJECT="repository_owner_id:$GH_OWNER_ID:repository_id:$GH_REPO_ID:environment:lab:ref:refs/heads/main"
printf '%s\n' "$OIDC_SUBJECT" > .state/oidc-subject
# No se hace push automáticamente y no se usan credenciales AWS permanentes.
echo "GitHub preparado: https://github.com/$REPO"
