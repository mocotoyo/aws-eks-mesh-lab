#!/usr/bin/env python3
import json,os
from pathlib import Path
p=Path('infra/generated');e=os.environ;a=e['ACCOUNT_ID'];r=e['AWS_REGION'];lab=e['LAB_ID']
tags={'proyecto':'mesh-lab','lab-id':lab,'owner':e['GH_OWNER'],'expires-at':e['EXPIRES_AT']}
# JSON es YAML válido: eksctl puede leerlo como cluster.yaml sin PyYAML adicional.
cluster={'apiVersion':'eksctl.io/v1alpha5','kind':'ClusterConfig','metadata':{'name':e['CLUSTER_NAME'],'region':r,'version':e['K8S_VERSION'],'tags':tags},'accessConfig':{'authenticationMode':'API_AND_CONFIG_MAP'},'vpc':{'nat':{'gateway':'Disable'},'clusterEndpoints':{'publicAccess':True,'privateAccess':True}},'managedNodeGroups':[{'name':'lab','instanceType':'t3.large','amiFamily':'AmazonLinux2023','minSize':1,'maxSize':1,'desiredCapacity':1,'volumeSize':20,'volumeType':'gp3','volumeEncrypted':True,'privateNetworking':False,'tags':tags}]}
trust={'Version':'2012-10-17','Statement':[{'Effect':'Allow','Principal':{'Federated':f'arn:aws:iam::{a}:oidc-provider/token.actions.githubusercontent.com'},'Action':'sts:AssumeRoleWithWebIdentity','Condition':{'StringEquals':{'token.actions.githubusercontent.com:aud':'sts.amazonaws.com','token.actions.githubusercontent.com:sub':e['OIDC_SUBJECT']}}}]}
policy={'Version':'2012-10-17','Statement':[{'Effect':'Allow','Action':'ecr:GetAuthorizationToken','Resource':'*'},{'Effect':'Allow','Action':['ecr:BatchCheckLayerAvailability','ecr:InitiateLayerUpload','ecr:UploadLayerPart','ecr:CompleteLayerUpload','ecr:PutImage','ecr:BatchGetImage','ecr:GetDownloadUrlForLayer','ecr:DescribeImages'],'Resource':f'arn:aws:ecr:{r}:{a}:repository/{e["ECR_REPO"]}'},{'Effect':'Allow','Action':'eks:DescribeCluster','Resource':f'arn:aws:eks:{r}:{a}:cluster/{e["CLUSTER_NAME"]}'}]}
for name,data in [('cluster.yaml',cluster),('trust.json',trust),('permissions.json',policy)]:
 (p/name).write_text(json.dumps(data,indent=2)+'\n')
