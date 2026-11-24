#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
assert_account
[[ "$BUDGET_EMAIL" == *@*.* && "$BUDGET_EMAIL" != REEMPLAZAR* ]] || fail 'Editar BUDGET_EMAIL'
export BUDGET_NAME="$LAB_ID-alerta"
python3 - <<'PYB'
import json,os
budget={'BudgetName':os.environ['BUDGET_NAME'],'BudgetType':'COST','TimeUnit':'MONTHLY','BudgetLimit':{'Amount':os.environ['MONTHLY_BUDGET_USD'],'Unit':'USD'},'CostTypes':{'IncludeCredit':False,'IncludeRefund':False}}
notes=[{'Notification':{'NotificationType':'ACTUAL','ComparisonOperator':'GREATER_THAN','Threshold':p,'ThresholdType':'PERCENTAGE'},'Subscribers':[{'SubscriptionType':'EMAIL','Address':os.environ['BUDGET_EMAIL']}]} for p in (25,50,80,100)]
for name,obj in [('budget',budget),('notifications',notes)]:
 with open(f'infra/generated/{name}.json','w') as f:json.dump(obj,f,indent=2)
PYB
# Nombre dedicado. No sustituye ni modifica presupuestos existentes.
if aws budgets describe-budget --account-id "$ACCOUNT_ID" --budget-name "$BUDGET_NAME" > infra/generated/existing-budget.json 2>infra/generated/budget-error.txt; then
 python3 - <<'PYB'
import json,os
b=json.load(open('infra/generated/existing-budget.json'))['Budget']
assert b['BudgetLimit']['Amount']==os.environ['MONTHLY_BUDGET_USD'] or float(b['BudgetLimit']['Amount'])==float(os.environ['MONTHLY_BUDGET_USD']), 'El presupuesto existente tiene otro importe'
assert not b.get('CostFilters'), 'El presupuesto existente no debe tener filtros'
PYB
 echo 'Se conserva el presupuesto existente. Verificar destinatarios en consola.'
 exit 0
fi
grep -Eq 'NotFoundException|not exist' infra/generated/budget-error.txt || { cat infra/generated/budget-error.txt >&2; exit 1; }
aws budgets create-budget --account-id "$ACCOUNT_ID" --budget file://infra/generated/budget.json --notifications-with-subscribers file://infra/generated/notifications.json
printf '%s\n' "$BUDGET_NAME" > .state/budget-name
aws budgets describe-budget --account-id "$ACCOUNT_ID" --budget-name "$BUDGET_NAME" > evidencias/budget.json
echo 'Presupuesto mensual de TODA LA CUENTA. Alertas con retraso. No detiene el gasto.'
