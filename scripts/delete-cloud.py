#!/usr/bin/env python3
"""DELETE desde GitHub o desde la terminal. Solo targets inventariados, nunca por búsqueda global."""
import json,os,subprocess
T=json.loads(os.environ['LAB_DELETE_TARGETS'])
for k in ['AWS_REGION','LAB_ID','ACCOUNT_ID','ROLE_NAME','ECR_REPO']:os.environ[k]=T[k]
os.environ['AWS_DEFAULT_REGION']=T['AWS_REGION']
def run(args):subprocess.run(['aws',*args],check=True)
def read(args,missing=''):
 p=subprocess.run(['aws',*args,'--output','json'],text=True,capture_output=True)
 if p.returncode:
  if missing and missing in p.stderr:return None
  raise SystemExit(p.stderr)
 return json.loads(p.stdout)
a=read(['sts','get-caller-identity'])['Account']
if a!=T['ACCOUNT_ID']:raise SystemExit('Cuenta incorrecta')
if os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('CONFIRM_LAB')!=T['LAB_ID']:
 raise SystemExit('La confirmación no coincide con LAB_ID')
# Validar todos los stacks antes de la primera eliminación.
for arn in T['stack_arns']:
 prefix=f"arn:aws:cloudformation:{T['AWS_REGION']}:{a}:stack/eksctl-{T['CLUSTER_NAME']}-"
 if not arn.startswith(prefix):raise SystemExit('ARN fuera del laboratorio')
 s=read(['cloudformation','describe-stacks','--stack-name',arn],'does not exist')
 if s and not any(t['Key']=='lab-id' and t['Value']==T['LAB_ID'] for t in s['Stacks'][0].get('Tags',[])):raise SystemExit('Stack sin etiqueta de propiedad')
# Eliminar nodegroup antes del clúster. No hay LB/PVC creados por este kit.
for arn in T['stack_arns']:
 s=read(['cloudformation','describe-stacks','--stack-name',arn],'does not exist')
 if not s or s['Stacks'][0]['StackStatus']=='DELETE_COMPLETE':continue
 print('Eliminando stack',arn,flush=True)
 run(['cloudformation','delete-stack','--stack-name',arn])
 run(['cloudformation','wait','stack-delete-complete','--stack-name',arn])
# Si EKS persiste, no afirmar que se detuvo el costo.
c=read(['eks','describe-cluster','--name',T['CLUSTER_NAME']],'ResourceNotFoundException')
if c:raise SystemExit('EKS aún existe. Revisar stacks y continuar eliminación.')
# ECR y rol de despliegue, con verificación de etiquetas.
subprocess.run(['python3','scripts/delete-aux.py'],check=True)
# Se conserva el rol DELETE para poder repetir la limpieza. IAM no tiene cargo por existencia.
print('DELETE completado para infraestructura inventariada. Rol DELETE, budget y proveedor OIDC se conservan.',flush=True)
