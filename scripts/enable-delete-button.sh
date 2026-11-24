#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
aws_state
export OIDC_SUBJECT=$(cat .state/oidc-subject)
python3 scripts/delete-policy.py
DELETE_ROLE_NAME="$LAB_ID-delete"
aws iam create-role --role-name "$DELETE_ROLE_NAME" --max-session-duration 7200 --assume-role-policy-document file://infra/generated/trust.json --tags Key=proyecto,Value=mesh-lab Key=lab-id,Value="$LAB_ID"
aws iam put-role-policy --role-name "$DELETE_ROLE_NAME" --policy-name lab-delete --policy-document file://infra/generated/delete-policy.json
repo="$GH_OWNER/$GH_REPO"
gh variable set DELETE_ROLE_ARN --env lab --body "arn:aws:iam::$ACCOUNT_ID:role/$DELETE_ROLE_NAME" --repo "$repo"
gh variable set LAB_DELETE_TARGETS --env lab --body "$(cat .state/delete-targets.json)" --repo "$repo"
echo "Botón preparado: https://github.com/$repo/actions/workflows/delete-lab.yml"
