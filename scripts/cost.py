#!/usr/bin/env python3
"""Estimación preventiva. No consulta ni modifica AWS."""
import os, json, argparse
from decimal import Decimal as D

def estimate(env):
    val=lambda k,d:D(str(env.get(k,d)))
    hours=val('LAB_HOURS',3); cleanup=val('CLEANUP_HOURS',.5)
    if not D('0.5') <= hours <= D('4'): raise ValueError('LAB_HOURS debe estar entre 0.5 y 4')
    rates=[val('EKS_USD_HOUR',.1), val('EC2_USD_HOUR',.0835), val('IPV4_USD_HOUR',.005), val('GP3_USD_GB_MONTH',.08)*20/720, val('ECR_USD_GB_MONTH',.1)*1/720]
    if any(r<0 for r in rates) or cleanup<0: raise ValueError('Tarifas o tiempo negativos')
    hourly=sum(rates)
    reserve=val('EXTRA_RESERVE_USD',.4)
    limit=val('SESSION_LIMIT_USD',2)
    if reserve<0 or limit<=0: raise ValueError('Reserva no negativa y límite mayor a cero requeridos')
    total=hourly*(hours+cleanup)+reserve
    return {'hourly':float(hourly),'hours':float(hours),'cleanup_hours':float(cleanup),'estimate':float(total),'limit':float(limit),'allowed':total<=limit,'forgotten_24h':float(hourly*24),'forgotten_720h':float(hourly*720)}

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--json',action='store_true');ap.add_argument('--enforce',action='store_true');a=ap.parse_args()
    r=estimate(os.environ)
    if a.json: print(json.dumps(r,indent=2))
    else:
        print('PLAN PREVENTIVO: 1 t3.large, EKS estándar, 20 GiB gp3, 1 IPv4, hasta 1 GB ECR')
        print(f"Referencia por hora: USD {r['hourly']:.3f}")
        print(f"Ventana: {r['hours']} h + {r['cleanup_hours']} h de eliminación")
        print(f"Estimación con reserva: USD {r['estimate']:.2f} | umbral preventivo: USD {r['limit']:.2f}")
        print(f"Olvido 24 h: USD {r['forgotten_24h']:.2f} | 720 h: USD {r['forgotten_720h']:.2f}")
        print('No es una cotización, factura ni límite duro. Tarifas, impuestos y usos adicionales pueden variar.')
    if a.enforce and not r['allowed']: raise SystemExit('Bloqueado: la estimación supera SESSION_LIMIT_USD')
