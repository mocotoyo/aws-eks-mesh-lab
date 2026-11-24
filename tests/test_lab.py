import importlib.util, unittest, os, json, runpy, subprocess
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('cost',ROOT/'scripts/cost.py');cost=importlib.util.module_from_spec(spec);spec.loader.exec_module(cost)

class CostControls(unittest.TestCase):
 def test_default_below_two_dollars(self):
  r=cost.estimate({});self.assertTrue(r['allowed']);self.assertAlmostEqual(r['estimate'],1.068014,places=4)
 def test_refuses_insufficient_budget(self):self.assertFalse(cost.estimate({'SESSION_LIMIT_USD':'.5'})['allowed'])
 def test_refuses_long_session(self):
  with self.assertRaises(ValueError):cost.estimate({'LAB_HOURS':'24'})
 def test_no_negative_rates(self):
  with self.assertRaises(ValueError):cost.estimate({'EC2_USD_HOUR':'-1'})

class ScopedDelete(unittest.TestCase):
 def base(self):
  return {'ACCOUNT_ID':'123456789012','AWS_REGION':'us-east-1','LAB_ID':'mocotoyo-mesh-demo','CLUSTER_NAME':'mocotoyo-mesh-demo','ECR_REPO':'mocotoyo-mesh-demo/cuentas','ROLE_NAME':'mocotoyo-mesh-demo-github','EXPIRES_AT':'1','stack_arns':['arn:aws:cloudformation:us-east-1:123456789012:stack/eksctl-mocotoyo-mesh-demo-nodegroup-lab/one','arn:aws:cloudformation:us-east-1:123456789012:stack/eksctl-mocotoyo-mesh-demo-cluster/two']}
 def execute(self,t,account='123456789012',confirm='mocotoyo-mesh-demo',wrongtag=False):
  commands=[];deleted=set()
  def fake(cmd,**kwargs):
   if cmd[0]=='python3':commands.append(cmd);return subprocess.CompletedProcess(cmd,0,'','')
   service,action=cmd[1:3]
   if action.startswith('delete'):commands.append(cmd)
   code=0;err='';data={}
   if service=='sts':data={'Account':account}
   elif service=='cloudformation' and action=='describe-stacks':
    arn=cmd[cmd.index('--stack-name')+1]
    data={'Stacks':[{'Tags':[{'Key':'lab-id','Value':'otro' if wrongtag else t['LAB_ID']}],'StackStatus':'DELETE_COMPLETE' if arn in deleted else 'CREATE_COMPLETE'}]}
   elif service=='cloudformation' and action=='wait':deleted.add(cmd[cmd.index('--stack-name')+1])
   elif service=='eks' and action=='describe-cluster':code=1;err='ResourceNotFoundException'
   return subprocess.CompletedProcess(cmd,code,json.dumps(data),err)
  env={'LAB_DELETE_TARGETS':json.dumps(t),'GITHUB_ACTIONS':'true','CONFIRM_LAB':confirm}
  with patch.dict(os.environ,env),patch('subprocess.run',side_effect=fake):
   runpy.run_path(str(ROOT/'scripts/delete-cloud.py'),run_name='__main__')
  return commands
 def test_wrong_account_rejected(self):
  with self.assertRaises(SystemExit):self.execute(self.base(),account='999999999999')
 def test_wrong_confirmation_rejected(self):
  with self.assertRaises(SystemExit):self.execute(self.base(),confirm='otro')
 def test_foreign_stack_rejected(self):
  t=self.base();t['stack_arns'][1]='arn:aws:cloudformation:us-east-1:123456789012:stack/produccion/one'
  with self.assertRaises(SystemExit):self.execute(t)
 def test_wrong_owner_tag_rejected(self):
  with self.assertRaises(SystemExit):self.execute(self.base(),wrongtag=True)
 def test_nodegroup_deleted_before_cluster(self):
  commands=self.execute(self.base())
  deletes=[c for c in commands if c[:3]==['aws','cloudformation','delete-stack']]
  self.assertEqual(len(deletes),2)
  self.assertIn('nodegroup-lab',deletes[0][4]);self.assertIn('-cluster/',deletes[1][4])

if __name__=='__main__':unittest.main()
