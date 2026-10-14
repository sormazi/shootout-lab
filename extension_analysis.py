"""Descriptive empirical transport and skill-preservation audit. No causal fit."""
from lab import *
from pathlib import Path
import json,csv
ROOT=Path(__file__).resolve().parent
def save(name,rows):
 with (ROOT/'results'/name).open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
def main():
 e=json.loads((ROOT/'data/empirical_results.json').read_text());base=e['conversion'];positions={int(x['label']):x for x in e['estimates'] if x['kind']=='position'}
 models=[('pooled_equal_skill',Model(base,base))]
 for anchor in ('conversion','lower','upper'):
  val=lambda j:positions[j]['conversion'] if anchor=='conversion' else positions[j]['shootout_bootstrap_95'][0 if anchor=='lower' else 1]
  la=tuple(log(val(j)/(1-val(j)))-log(base/(1-base)) for j in (1,3,5,7,9))+(0,)*95
  lb=tuple(log(val(j)/(1-val(j)))-log(base/(1-base)) for j in (2,4,6,8,10))+(0,)*95
  models.append(('position_transport_'+anchor,Model(base,base,lineup_a=la,lineup_b=lb)))
 rows=[]
 for name,model in models:
  for rule in (Rule(),Rule(kind='standard'),Rule(kind='sequential')):
   x=forward(rule,model,100)
   rows.append(dict(scenario=name,kind=rule.kind,win_a=x['win_a'],residual=x['residual'],restricted_rounds=x['rounds_restricted'],tail10=x['tail']))
 save('empirical_transport.csv',rows)
 rows=[]
 for strong,weak in ((.8,.7),(.85,.65),(.75,.75)):
  for rule in (Rule(),Rule(m=4,n=4),Rule(kind='standard'),Rule(kind='sequential')):
   a=exact(rule,Model(strong,weak))['win_a'];b=1-exact(rule,Model(weak,strong))['win_a']
   rows.append(dict(kind=rule.kind,m=rule.m,n=rule.n,p_strong=strong,p_weak=weak,strong_as_a=a,strong_as_b=b,role_gap=a-b,strong_role_average=(a+b)/2))
 save('skill_audit.csv',rows)
if __name__=='__main__':main()
