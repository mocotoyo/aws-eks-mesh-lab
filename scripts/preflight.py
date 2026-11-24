#!/usr/bin/env python3
import subprocess,json,os
checks=[['eks','describe-cluster','--name',os.environ['CLUSTER_NAME']],['ecr','describe-repositories','--repository-names',os.environ['ECR_REPO']],['iam','get-role','--role-name',os.environ['ROLE_NAME']],['cloudformation','describe-stacks','--stack-name','eksctl-'+os.environ['CLUSTER_NAME']+'-cluster']]
for args in checks:
 r=subprocess.run(['aws',*args,'--output','json'],text=True,capture_output=True)
 if r.returncode==0:raise SystemExit('Recurso preexistente. Elegir otro LAB_ID: '+' '.join(args))
 if not any(x in r.stderr for x in ['ResourceNotFoundException','RepositoryNotFoundException','NoSuchEntity','does not exist']):raise SystemExit(r.stderr)
# Verificar proveedor OIDC antes de crear rol/EKS.
p='arn:aws:iam::'+os.environ['ACCOUNT_ID']+':oidc-provider/token.actions.githubusercontent.com'
r=subprocess.run(['aws','iam','list-open-id-connect-providers','--output','json'],check=True,text=True,capture_output=True)
if p not in [x['Arn'] for x in json.loads(r.stdout)['OpenIDConnectProviderList']]:
 raise SystemExit('Falta proveedor OIDC GitHub. Crear una vez según README. No se ha creado EKS.')
