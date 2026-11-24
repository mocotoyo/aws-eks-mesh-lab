#!/usr/bin/env python3
import argparse,time,json
from collections import Counter
from urllib.request import urlopen
p=argparse.ArgumentParser();p.add_argument('--count',type=int,default=200);p.add_argument('--delay',type=float,default=.2);p.add_argument('--url',default='http://127.0.0.1:8080/');a=p.parse_args()
c=Counter();errors=0
for i in range(a.count):
 try:
  with urlopen(a.url,timeout=5) as r:c[json.load(r)['version']]+=1
 except Exception as e:errors+=1;print(type(e).__name__,flush=True)
 time.sleep(a.delay)
print(json.dumps({'requests':a.count,'versions':dict(c),'errors':errors},indent=2))
if errors:raise SystemExit(1)
