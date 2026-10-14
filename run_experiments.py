"""Rebuild all numerical results: python3 run_experiments.py.
Optional figures: use --plots with matplotlib installed.
"""
from lab import *
from pathlib import Path
import json,csv,sys,hashlib,platform,time
ROOT=Path(__file__).resolve().parent;OUT=ROOT/'results';OUT.mkdir(exist_ok=True)
def csvsave(name,rows):
 with (OUT/name).open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def main():
 start=time.time();tables=[]
 for m,n,qr,er in ((5,4,.60,6.06),(4,3,.56,4.71),(3,2,.50,3.33),(2,1,.34,1.85)):
  rule=Rule(m=m,n=n);root=bisect(lambda q:exact(rule,Model(.75,q))['win_a']-.5);x=exact(rule)
  tables.append(dict(m=m,n=n,p=.75,q_balancing=root,paper_q=qr,rounds=x['rounds'],paper_rounds=er,rounds_at_balancing=exact(rule,Model(.75,root))['rounds'],printed_prop2_rounds=event_sum(m,n,.75,.6,printed=True)['rounds']))
 csvsave('reproduction_tables.csv',tables)
 pilot=[]
 for q in (.6,.65,.7,.75):
  x=exact();pilot.append(dict(p=.75,q=q,standard=exact(Rule(kind='standard'),Model(.75,q))['win_a'],target=exact(Rule(),Model(.75,q))['win_a']))
 csvsave('pilot.csv',pilot)
 curve=[]
 for i in range(1,100):
  q=i/100;small=exact(Rule(m=2,n=1),Model(.75,q));x=exact(Rule(),Model(.75,q));y=exact(Rule(kind='sequential'),Model(.75,q));z=exact(Rule(kind='standard'),Model(.75,q))
  curve.append(dict(q=q,small_a=small['win_a'],small_rounds=small['rounds'],target_a=x['win_a'],target_rounds=x['rounds'],sequential_a=y['win_a'],sequential_rounds_started=y['rounds'],sequential_kick_pairs=y['kicks']/2,standard_a=z['win_a']))
 csvsave('figure_curves.csv',curve)
 boundaries=[]
 for p in (.55,.6,.65,.7,.75,.8,.85,.9):
  fn=lambda q:abs(exact(Rule(),Model(p,q))['bias'])-abs(exact(Rule(kind='standard'),Model(p,q))['bias'])
  boundaries.append(dict(p=p,q_crossover=bisect(fn,lo=max(.001,p-.35),hi=p)))
 csvsave('boundaries.csv',boundaries)
 candidates=[Rule(kind='standard')]+[Rule(m=m,n=n) for m in range(1,9) for n in range(1,m+1)]
 scenario_sets={'paper_neighborhood':[Model(p,q) for p in (.72,.75,.78) for q in (.57,.6,.63)],'includes_null':[Model(p,q) for p in (.7,.75,.8) for q in (p-.15,p-.075,p)]}
 robust={}
 for name,scenarios in scenario_sets.items():
  rows=optimize(scenarios,candidates,8);csvsave('robust_'+name+'.csv',rows);robust[name]=rows[0]
 mc=[]
 for i,rule in enumerate((Rule(),Rule(kind='standard'),Rule(kind='sequential'))):
  x=exact(rule);y=monte_carlo(rule,Model(),50000,20261014+i)
  mc.append(dict(kind=rule.kind,exact_win=x['win_a'],mc_win=y['win_a'],ci_low=y['ci95'][0],ci_high=y['ci95'][1],exact_rounds=x['rounds'],mc_rounds=y['rounds_restricted'],rounds_se=y['rounds_se'],censored=y['censored'],N=y['N'],seed=y['seed']))
 csvsave('mc_validation.csv',mc)
 sensitivities=[]
 for delta in (-.10,0,.10,.20):
  for pressure in (0,.1,.3):
   model=Model(.75,.75,order_logit=delta,pressure=pressure)
   for rule in (Rule(),Rule(kind='standard'),Rule(kind='standard',order='ABBA'),Rule(kind='standard',order='catchup')):
    x=forward(rule,model,100)
    sensitivities.append(dict(kind=rule.kind,order=rule.order,order_logit=delta,pressure=pressure,win_a=x['win_a'],win_upper=x['win_a_upper'],restricted_rounds=x['rounds_restricted'],tail10=x['tail'],residual=x['residual']))
 csvsave('behavioral_sensitivity.csv',sensitivities)
 # MC robust ranking for heterogeneity: simultaneous probability bounds, capped duration.
 mc_scenarios=[Model(.75,.75,order_logit=d,pressure=.1,latent_sd=.15) for d in (0,.1,.2)]
 mc_candidates=[Rule(kind='standard'),Rule(kind='standard',order='ABBA'),Rule(kind='standard',order='catchup'),Rule(),Rule(m=4,n=4)]
 mcrows=optimize(mc_scenarios,mc_candidates,max_rounds=8,method='mc',N=6000,horizon=40)
 csvsave('robust_mc.csv',mcrows)
 holdout=monte_carlo(Rule(kind=mcrows[0]['kind'],m=mcrows[0]['m'],n=mcrows[0]['n'],order=mcrows[0]['order']),mc_scenarios[-1],30000,90001,horizon=100)
 summary=dict(crossover75=boundaries[4]['q_crossover'],reproduction=tables,pilot=pilot,robust=robust,mc_holdout=holdout,mc_validation=mc,finite_grid_only=True)
 (OUT/'summary.json').write_text(json.dumps(summary,indent=2))
 manifest=dict(seed=20261014,python=platform.python_version(),runtime_seconds=time.time()-start,uncertainty_sets={k:[asdict(s) for s in v] for k,v in scenario_sets.items()},target_domain='1<=n<=m<=8',max_expected_rounds=8,mc_scenarios=[asdict(s) for s in mc_scenarios],mc_candidates=[asdict(s) for s in mc_candidates],mc_N=6000,mc_horizon=40,forward_horizon=100,grid_claim='finite scenario minimax; no continuous-domain certificate',sha256={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in ROOT.glob('*.py')})
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2));print(json.dumps(summary,indent=2))
 if '--plots' in sys.argv:
  import matplotlib;matplotlib.use('Agg');import matplotlib.pyplot as plt
  plt.rcParams.update({'font.size':11,'axes.spines.top':False,'axes.spines.right':False})
  fig,axs=plt.subplots(2,3,figsize=(15,8));q=[x['q'] for x in curve]
  panels=[('Figure 2: (2,1) win probability','small_a'),('Figure 3: (2,1) expected rounds','small_rounds'),('Figure 4: (5,4) win probability','target_a'),('Figure 5: target vs sequential','target_a'),('Figure 6: duration comparison','target_rounds')]
  for ax,(title,key) in zip(axs.flat,panels):
   ax.plot(q,[x[key] for x in curve],label='A / round-completed');ax.set(title=title,xlabel='B scoring probability q')
   if key.endswith('_a') and 'Figure 5' not in title:ax.plot(q,[1-x[key] for x in curve],label='B')
   if 'Figure 5' in title:ax.plot(q,[x['sequential_a'] for x in curve],label='sequential')
   if 'Figure 6' in title:
    ax.plot(q,[x['sequential_rounds_started'] for x in curve],label='sequential rounds started')
    ax.plot(q,[x['sequential_kick_pairs'] for x in curve],label='sequential kicks / 2',linestyle=':')
   ax.legend(fontsize=8);ax.grid(alpha=.2)
  ax=axs.flat[-1];ax.plot([x['p'] for x in boundaries],[x['q_crossover'] for x in boundaries]);ax.set(title='Candidate extension: crossover boundary',xlabel='p',ylabel='q');ax.grid(alpha=.2)
  fig.tight_layout();fig.savefig(OUT/'reproduction_figures.png',dpi=160);fig.savefig(OUT/'reproduction_figures.pdf');plt.close(fig)
if __name__=='__main__':main()
