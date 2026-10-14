"""Reproducible descriptive analysis of the public Vollmer et al. D2 dataset.

No fitted observational rate is identified as a causal pressure effect.
Python standard library only. Run: python3 empirical.py --bootstrap 2000.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
import math
import random
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = "https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0315017"


def wilson(successes, n, z=1.959963984540054):
    if n == 0:
        return [None, None]
    p = successes / n
    den = 1 + z*z/n
    center = (p + z*z/(2*n))/den
    radius = z*math.sqrt(p*(1-p)/n + z*z/(4*n*n))/den
    return [center-radius, center+radius]


def quantile(values, q):
    values = sorted(values)
    k = (len(values)-1)*q
    i = int(k)
    return values[i]*(1-(k-i)) + values[min(i+1, len(values)-1)]*(k-i)


def load_shootouts(path):
    groups = defaultdict(list)
    counts = defaultdict(int)
    with path.open(newline='', encoding='utf-8-sig') as handle:
        for row in csv.DictReader(handle):
            for d in ('D1','D2','D3'):
                if row[d] == 'TRUE':
                    counts[d] += 1
            if row['D2'] == 'TRUE' and row['TypePhaseName'] == 'Penalty Shoot-Out':
                groups[row['fcompMatchID']].append(row)
    shootouts = []
    for match, rows in sorted(groups.items()):
        rows.sort(key=lambda r:int(r['order']))
        orders = [int(r['order']) for r in rows]
        if orders != list(range(1,len(rows)+1)):
            raise ValueError(f'Noncontiguous/duplicate order in match {match}')
        a, b = rows[0]['PenaltyTakerTeamName'], rows[1]['PenaltyTakerTeamName']
        if a == b or any(r['PenaltyTakerTeamName'] != (a if i%2==0 else b) for i,r in enumerate(rows)):
            raise ValueError(f'Not alternating in match {match}')
        ga = gb = 0
        features = []
        for i,r in enumerate(rows):
            team = i%2
            own,opp = (ga,gb) if team==0 else (gb,ga)
            state = 'behind' if own<opp else 'ahead' if own>opp else 'level'
            goal = int(r['EventTypeName']=='Goal')
            if r['EventTypeName'] not in ('Goal','Missed','Save','Not Scored'):
                raise ValueError(f'Unknown outcome in match {match}')
            features.append((i+1, team, state, goal))
            if team == 0: ga += goal
            else: gb += goal
            ka,kb=(i+2)//2,(i+1)//2
            ended = (ga>gb+max(0,5-kb) or gb>ga+max(0,5-ka)) if i<10 else ((i+1)%2==0 and ga!=gb)
            if ended and i != len(rows)-1:
                raise ValueError(f'Kicks after legal termination in match {match}')
        if ga == gb or not ended:
            raise ValueError(f'Unterminated match {match}')
        last_home,last_away = map(int,rows[-1]['ScoreAfter'].split(':'))
        expected = (ga,gb) if a == rows[0]['homeTeamName'] else (gb,ga)
        if (last_home,last_away) != expected:
            raise ValueError(f'Outcome/score mismatch match {match}')
        shootouts.append({'id':match,'first_win':int(ga>gb),'features':features,
                          'country':rows[0]['country'],'season':rows[0]['SeasonID'],
                          'tournament':rows[0]['TournamentName']})
    return shootouts, dict(counts)


def analyze(path, bootstrap=2000, seed=20261014):
    if bootstrap < 100:
        raise ValueError('At least 100 bootstrap replicates required')
    shoots, counts = load_shootouts(path)
    n = len(shoots)
    wins = sum(s['first_win'] for s in shoots)
    keys = sorted({('position',str(o)) for s in shoots for o,t,state,g in s['features']} |
                  {('score_state',f'{"A" if t==0 else "B"}:{state}') for s in shoots for o,t,state,g in s['features']},
                  key=lambda k:(k[0],int(k[1]) if k[0]=='position' else k[1]))
    key_index = {key:i for i,key in enumerate(keys)}
    vectors=[]
    for s in shoots:
        gs=[0]*len(keys); ns=[0]*len(keys)
        for o,t,state,g in s['features']:
            for key in [('position',str(o)),('score_state',f'{"A" if t==0 else "B"}:{state}')]:
                k=key_index[key]; gs[k]+=g; ns[k]+=1
        vectors.append((s['first_win'],gs,ns))
    total_g=[sum(v[1][k] for v in vectors) for k in range(len(keys))]
    total_n=[sum(v[2][k] for v in vectors) for k in range(len(keys))]
    rng=random.Random(seed)
    win_samples=[]; rate_samples=[[] for _ in keys]
    # Resample complete shootouts, retaining the stopping pattern and within-match dependence.
    for _ in range(bootstrap):
        w=0; gs=[0]*len(keys); ns=[0]*len(keys)
        for _ in range(n):
            wi,gi,ni=vectors[rng.randrange(n)]; w+=wi
            for k in range(len(keys)):
                gs[k]+=gi[k]; ns[k]+=ni[k]
        win_samples.append(w/n)
        for k in range(len(keys)):
            if ns[k]: rate_samples[k].append(gs[k]/ns[k])
    estimates=[]
    for k,(kind,label) in enumerate(keys):
        estimates.append({'kind':kind,'label':label,'goals':total_g[k], 'attempts':total_n[k],
                          'conversion':total_g[k]/total_n[k],
                          'shootout_bootstrap_95':[quantile(rate_samples[k],.025),quantile(rate_samples[k],.975)]})
    big5=[s for s in shoots if s['country'] in ('England','Spain','Germany','Italy','France') and s['tournament'].startswith('cups/')]
    all_goals=sum(g for s in shoots for _,_,_,g in s['features'])
    all_kicks=sum(len(s['features']) for s in shoots)
    return {'source':SOURCE,'dataset_download':'https://osf.io/download/8bxdf/',
            'sha256':hashlib.sha256(path.read_bytes()).hexdigest(), 'data_rows':counts,
            'seed':seed,'bootstrap_replicates':bootstrap,'bootstrap_unit':'entire shootout',
            'shootouts':n,'first_team_wins':wins,'first_team_win_rate':wins/n,
            'first_team_wilson_95':wilson(wins,n),
            'first_team_bootstrap_95':[quantile(win_samples,.025),quantile(win_samples,.975)],
            'big5_cups':{'shootouts':len(big5),'first_team_wins':sum(s['first_win'] for s in big5),
                         'first_team_win_rate':sum(s['first_win'] for s in big5)/len(big5)},
            'conversion':all_goals/all_kicks,'shootout_kicks':all_kicks,
            'sudden_death_fraction':sum(len(s['features'])>10 for s in shoots)/n,
            'estimates':estimates,
            'interpretation':'Descriptive observational rates; not causal pressure calibration. Later positions condition on survival. Match bootstrap assumes independent shootouts and does not address repeated team/player/competition dependence.'}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input',type=Path,default=HERE/'data/data_final.csv')
    parser.add_argument('--output',type=Path,default=HERE/'data/empirical_results.json')
    parser.add_argument('--bootstrap',type=int,default=2000)
    parser.add_argument('--seed',type=int,default=20261014)
    args=parser.parse_args()
    results=analyze(args.input,args.bootstrap,args.seed)
    args.output.write_text(json.dumps(results,indent=2)+'\n')
    print(json.dumps({k:v for k,v in results.items() if k != 'estimates'},indent=2))


if __name__ == '__main__': main()
