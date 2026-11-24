#!/usr/bin/env python3
"""Compara claims antes de asumir rol. Nunca imprime JWT ni token de solicitud."""
import os,json,urllib.request,base64
url=os.environ['ACTIONS_ID_TOKEN_REQUEST_URL']+'&audience=sts.amazonaws.com'
req=urllib.request.Request(url,headers={'Authorization':'Bearer '+os.environ['ACTIONS_ID_TOKEN_REQUEST_TOKEN']})
with urllib.request.urlopen(req,timeout=20) as r: token=json.load(r)['value']
segment=token.split('.')[1]
claims=json.loads(base64.urlsafe_b64decode(segment+'='*(-len(segment)%4)))
for key,expected in [('iss','https://token.actions.githubusercontent.com'),('aud','sts.amazonaws.com'),('sub',os.environ['OIDC_SUBJECT'])]:
 if claims.get(key)!=expected: raise SystemExit('Claim OIDC inesperado: '+key)
print('OIDC: iss, aud y sub coinciden. AWS verificará firma y confianza.')
