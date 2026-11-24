#!/usr/bin/env python3
import os,json,subprocess
E=os.environ;lab=E['LAB_ID'];cluster=E['CLUSTER_NAME'];failed=False

def get(args):
 r=subprocess.run(['aws',*args,'--output','json'],capture_output=True,text=True)
 if r.returncode:raise RuntimeError(r.stderr)
 return json.loads(r.stdout)
report={}
report['clusters']=[x for x in get(['eks','list-clusters'])['clusters'] if x==cluster]
stacks=get(['cloudformation','list-stacks'])['StackSummaries']
report['stacks']=[{'name':x['StackName'],'state':x['StackStatus']} for x in stacks if x['StackName'].startswith('eksctl-'+cluster+'-') and x['StackStatus']!='DELETE_COMPLETE']
for kind,key in [('volumes','Volumes'),('addresses','Addresses'),('network-interfaces','NetworkInterfaces')]:
 data=get(['ec2','describe-'+kind,'--filters','Name=tag:lab-id,Values='+lab])
 report[kind]=data[key]
# Inventario original preserva VPC para encontrar recursos no etiquetados.
if os.path.exists('.state/vpc-id'):
 vpc=open('.state/vpc-id').read().strip()
 report['nat']=get(['ec2','describe-nat-gateways','--filter','Name=vpc-id,Values='+vpc])['NatGateways']
 report['nat']=[x for x in report['nat'] if x['State']!='deleted']
 report['loadbalancers']=[x for x in get(['elbv2','describe-load-balancers'])['LoadBalancers'] if x.get('VpcId')==vpc]
report['ecr']=[x['repositoryName'] for x in get(['ecr','describe-repositories'])['repositories'] if x['repositoryName']==E['ECR_REPO']]
report['roles']=[x['RoleName'] for x in get(['iam','list-roles'])['Roles'] if x['RoleName'] in (E['ROLE_NAME'],lab+'-delete')]
with open('evidencias/auditoria-delete.json','w') as f:json.dump(report,f,indent=2)
for key,value in report.items():print(key,len(value))
if any(report.values()):raise SystemExit('Hay residuos. Revisar evidencias/auditoria-delete.json. No se declara cierre limpio.')
print('No se detectaron recursos en las comprobaciones cubiertas. Revisar consola y facturación por uso tardío.')
