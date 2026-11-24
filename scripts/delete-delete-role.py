#!/usr/bin/env python3
# Solo la administradora local elimina este rol, que no tiene costo por existir.
import os,json,subprocess
name=os.environ['LAB_ID']+'-delete'
r=subprocess.run(['aws','iam','get-role','--role-name',name,'--output','json'],capture_output=True,text=True)
if r.returncode:
 if 'NoSuchEntity' in r.stderr:raise SystemExit(0)
 raise SystemExit(r.stderr)
role=json.loads(r.stdout)['Role']
if not any(t['Key']=='lab-id' and t['Value']==os.environ['LAB_ID'] for t in role.get('Tags',[])):raise SystemExit('Rol DELETE ajeno')
r=subprocess.run(['aws','iam','list-role-policies','--role-name',name,'--output','json'],capture_output=True,text=True,check=True)
for p in json.loads(r.stdout)['PolicyNames']:
 subprocess.run(['aws','iam','delete-role-policy','--role-name',name,'--policy-name',p],check=True)
subprocess.run(['aws','iam','delete-role','--role-name',name],check=True)
