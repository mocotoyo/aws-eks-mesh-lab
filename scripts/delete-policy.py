#!/usr/bin/env python3
"""Inventario exacto para un rol de eliminación dedicado. Ejecutar como administradora."""
import os,json,subprocess
from pathlib import Path
E=os.environ;a=E['ACCOUNT_ID'];r=E['AWS_REGION'];lab=E['LAB_ID'];cluster=E['CLUSTER_NAME']
def get(*args):return json.loads(subprocess.check_output(['aws',*args,'--output','json'],text=True))
stacks=[];roles=[];ec2=[];profiles=[]
for name in [f'eksctl-{cluster}-nodegroup-lab',f'eksctl-{cluster}-cluster']:
 s=get('cloudformation','describe-stacks','--stack-name',name)['Stacks'][0]
 if not any(t['Key']=='lab-id' and t['Value']==lab for t in s.get('Tags',[])):raise SystemExit('Stack sin lab-id esperado')
 stacks.append(s['StackId'])
 for resource in get('cloudformation','list-stack-resources','--stack-name',s['StackId'])['StackResourceSummaries']:
  typ=resource['ResourceType'];pid=resource.get('PhysicalResourceId','')
  if typ=='AWS::IAM::Role':roles.append(f'arn:aws:iam::{a}:role/{pid}')
  if typ=='AWS::IAM::InstanceProfile':profiles.append(f'arn:aws:iam::{a}:instance-profile/{pid}')
  types={'AWS::EC2::VPC':'vpc','AWS::EC2::Subnet':'subnet','AWS::EC2::SecurityGroup':'security-group','AWS::EC2::RouteTable':'route-table','AWS::EC2::InternetGateway':'internet-gateway','AWS::EC2::LaunchTemplate':'launch-template'}
  if typ in types:ec2.append(f'arn:aws:ec2:{r}:{a}:{types[typ]}/{pid}')
roles += [f'arn:aws:iam::{a}:role/{E["ROLE_NAME"]}',f'arn:aws:iam::{a}:role/{lab}-delete']
statements=[
 {'Effect':'Allow','Action':['cloudformation:DescribeStacks','cloudformation:DescribeStackEvents','cloudformation:DescribeStackResources','cloudformation:ListStackResources','cloudformation:DeleteStack'],'Resource':stacks},
 {'Effect':'Allow','Action':['eks:DescribeCluster','eks:DeleteCluster','eks:ListNodegroups','eks:DescribeNodegroup','eks:DeleteNodegroup','eks:ListTagsForResource','eks:ListAddons','eks:DescribeAddon','eks:DeleteAddon'],'Resource':[f'arn:aws:eks:{r}:{a}:cluster/{cluster}',f'arn:aws:eks:{r}:{a}:nodegroup/{cluster}/*/*',f'arn:aws:eks:{r}:{a}:addon/{cluster}/*/*']},
 {'Effect':'Allow','Action':['ec2:Describe*'],'Resource':'*','Condition':{'StringEquals':{'aws:RequestedRegion':r}}},
 {'Effect':'Allow','Action':['ec2:DeleteVpc','ec2:DeleteSubnet','ec2:DeleteSecurityGroup','ec2:DeleteRouteTable','ec2:DeleteRoute','ec2:DisassociateRouteTable','ec2:DetachInternetGateway','ec2:DeleteInternetGateway','ec2:RevokeSecurityGroupIngress','ec2:RevokeSecurityGroupEgress','ec2:DeleteLaunchTemplate','ec2:DeleteTags'],'Resource':sorted(set(ec2))},
 {'Effect':'Allow','Action':['iam:GetRole','iam:ListRolePolicies','iam:ListAttachedRolePolicies','iam:ListInstanceProfilesForRole','iam:DeleteRolePolicy','iam:DetachRolePolicy','iam:DeleteRole'],'Resource':roles},
 {'Effect':'Allow','Action':['ecr:DescribeRepositories','ecr:ListTagsForResource','ecr:DeleteRepository'],'Resource':f'arn:aws:ecr:{r}:{a}:repository/{E["ECR_REPO"]}'}]
if profiles:statements.append({'Effect':'Allow','Action':['iam:GetInstanceProfile','iam:RemoveRoleFromInstanceProfile','iam:DeleteInstanceProfile'],'Resource':roles+profiles})
Path('infra/generated/delete-policy.json').write_text(json.dumps({'Version':'2012-10-17','Statement':statements},indent=2))
targets={k:E[k] for k in ['ACCOUNT_ID','AWS_REGION','LAB_ID','CLUSTER_NAME','ECR_REPO','ROLE_NAME','EXPIRES_AT']}
targets['stack_arns']=stacks;targets['delete_role']=lab+'-delete'
Path('.state/delete-targets.json').write_text(json.dumps(targets))
