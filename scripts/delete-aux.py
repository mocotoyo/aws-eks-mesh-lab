#!/usr/bin/env python3
import os,subprocess,json
E=os.environ

def read(args,missing):
 r=subprocess.run(['aws',*args,'--output','json'],capture_output=True,text=True)
 if r.returncode:
  if missing in r.stderr:return None
  raise SystemExit(r.stderr)
 return json.loads(r.stdout)

def run(args): subprocess.run(['aws',*args],check=True)
r=read(['ecr','describe-repositories','--repository-names',E['ECR_REPO']],'RepositoryNotFoundException')
if r:
 arn=r['repositories'][0]['repositoryArn'];tags=read(['ecr','list-tags-for-resource','--resource-arn',arn],'RepositoryNotFoundException')['tags']
 if not any(t['Key']=='lab-id' and t['Value']==E['LAB_ID'] for t in tags):raise SystemExit('ECR sin etiqueta de propiedad')
 run(['ecr','delete-repository','--repository-name',E['ECR_REPO'],'--force'])
r=read(['iam','get-role','--role-name',E['ROLE_NAME']],'NoSuchEntity')
if r:
 if not any(t['Key']=='lab-id' and t['Value']==E['LAB_ID'] for t in r['Role'].get('Tags',[])):raise SystemExit('Rol sin etiqueta de propiedad')
 p=read(['iam','list-role-policies','--role-name',E['ROLE_NAME']],'NoSuchEntity')
 for name in p['PolicyNames']:run(['iam','delete-role-policy','--role-name',E['ROLE_NAME'],'--policy-name',name])
 run(['iam','delete-role','--role-name',E['ROLE_NAME']])
