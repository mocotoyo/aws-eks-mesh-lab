#!/usr/bin/env python3
# Se ejecuta dentro del contenedor Python del cliente.
import sys
from urllib.request import Request,urlopen
from urllib.error import HTTPError
method,url,expected=sys.argv[1],sys.argv[2],int(sys.argv[3])
try:
 with urlopen(Request(url,method=method,data=b'{}' if method=='POST' else None),timeout=10) as r:status=r.status
except HTTPError as e:status=e.code
print(method,url,'HTTP',status,'esperado',expected)
if status!=expected:raise SystemExit(1)
