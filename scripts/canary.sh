#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
mode=${1:-local}; v1=${2:-90}; v2=${3:-10}
kube_state "$mode"
[[ "$v1" =~ ^[0-9]{1,3}$ && "$v2" =~ ^[0-9]{1,3}$ ]] || fail 'Pesos enteros entre 0 y 100'
((10#$v1<=100 && 10#$v2<=100 && 10#$v1+10#$v2==100)) || fail 'Los pesos deben sumar 100'
python3 - "$v1" "$v2" <<'PYC'
import pathlib,re,sys
p=pathlib.Path('k8s/mesh.yaml'); s=p.read_text(); weights=iter(sys.argv[1:])
assert len(re.findall(r'weight: \d+',s))==2
p.write_text(re.sub(r'weight: \d+',lambda _: 'weight: '+next(weights),s))
PYC
kubectl apply -f k8s/mesh.yaml
printf 'Canary actualizado a %s/%s. Si usarás GitHub, commit de k8s/mesh.yaml.\n' "$v1" "$v2"
