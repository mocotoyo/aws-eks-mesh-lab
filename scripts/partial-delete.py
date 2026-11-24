#!/usr/bin/env python3
import json,subprocess,os
cluster=os.environ['CLUSTER_NAME']
r=subprocess.run(['aws','cloudformation','list-stacks','--output','json'],check=True,capture_output=True,text=True)
stacks=json.loads(r.stdout)['StackSummaries']
owned=[s for s in stacks if s['StackName'] in ('eksctl-'+cluster+'-cluster','eksctl-'+cluster+'-nodegroup-lab') and s['StackStatus']!='DELETE_COMPLETE']
if owned:subprocess.run(['eksctl','delete','cluster','--name',cluster,'--region',os.environ['AWS_REGION'],'--wait'],check=True)
subprocess.run(['python3','scripts/delete-aux.py'],check=True)
