"""Shootout research engine. Python >=3.10, standard library only.
Probabilities exact by finite-state self-loop elimination for iid inputs;
nonstationary models use forward probability propagation with explicit residual mass.
"""
from dataclasses import dataclass, asdict
from functools import lru_cache
from collections import defaultdict
from math import comb, exp, log, sqrt
import random

@dataclass(frozen=True)
class Rule:
    kind: str = 'target'  # target, sequential, standard
    m: int = 5
    n: int = 4
    order: str = 'ABAB'  # ABBA, catchup are experimental standard comparators
    def __post_init__(self):
        if self.kind not in ('target','sequential','standard') or self.order not in ('ABAB','ABBA','catchup'):
            raise ValueError('unknown rule')
        if not isinstance(self.m,int) or not isinstance(self.n,int) or min(self.m,self.n)<1:
            raise ValueError('positive integer targets required')
        if self.kind!='standard' and self.order!='ABAB':
            raise ValueError('paper targets attach to fixed roles: only ABAB supported')

@dataclass(frozen=True)
class Model:
    p: float=.75
    q: float=.60
    order_logit: float=0.0 # added for first slot, subtracted for second slot
    pressure: float=0.0 # logit penalty per goal behind immediately before kick
    fatigue: float=0.0 # logit penalty per completed round, capped at round 10
    lineup_a: tuple=() # per-kicker logit offsets, repeat cyclically
    lineup_b: tuple=()
    latent_sd: float=0.0 # per-shootout Gaussian skill shocks; MC only
    def __post_init__(self):
        if not 0<self.p<1 or not 0<self.q<1: raise ValueError('p and q must lie strictly between 0 and 1')
        if self.latent_sd<0: raise ValueError('latent_sd must be nonnegative')
    def prob(self,team,slot,r,a,b,shock=(0,0)):
        base=self.p if team==0 else self.q
        lineup=self.lineup_a if team==0 else self.lineup_b
        deficit=max(0,(b-a) if team==0 else (a-b))
        z=log(base/(1-base)) + self.order_logit*(1 if slot==0 else -1)-self.pressure*deficit-self.fatigue*min(r,10)+shock[team]
        if lineup: z+=lineup[r%len(lineup)]
        return 1/(1+exp(-max(-35,min(35,z))))
    @property
    def iid(self):
        return not any((self.order_logit,self.pressure,self.fatigue,self.lineup_a,self.lineup_b,self.latent_sd))

# State at start of a round = score A, score B, sudden death flag, first team.
# SD scores reset after each tied pair: only score DIFFERENCE affects pressure.
def branches(rule,model,state,r,shock=(0,0)):
    a,b,sd,first=state
    if rule.order=='ABAB': first=0
    elif rule.order=='ABBA': first=r%2
    interim=[(1.,a,b,0)]
    out=[]
    for slot,team in enumerate((first,1-first)):
        nxt=[]
        for mass,x,y,mask in interim:
            p=model.prob(team,slot,r,x,y,shock)
            for goal,w in ((0,1-p),(1,p)):
                xx,yy=x+goal*(team==0),y+goal*(team==1)
                bits=mask|(goal<<team)
                winner=None
                if rule.kind=='sequential':
                    if xx>=rule.m: winner=0
                    elif yy>=rule.n: winner=1
                elif rule.kind=='standard' and r<5:
                    ca=r+int(team==0 or slot==1); cb=r+int(team==1 or slot==1)
                    if xx>yy+5-cb: winner=0
                    elif yy>xx+5-ca: winner=1
                if winner is not None:
                    out.append((mass*w,None,winner,slot+1,False))
                else: nxt.append((mass*w,xx,yy,bits))
        interim=nxt
    for mass,x,y,mask in interim:
        winner=None; enters=False
        nextfirst=0
        if rule.order=='ABBA': nextfirst=(r+1)%2
        elif rule.order=='catchup':
            # Alternate on ties; sole unsuccessful side goes first otherwise.
            nextfirst=(0 if mask==2 else 1 if mask==1 else 1-first)
        if sd:
            if x!=y: winner=0 if x>y else 1
            ns=(0,0,True,nextfirst)
        elif rule.kind=='standard':
            if r==4:
                if x!=y: winner=0 if x>y else 1
                else: enters=True
            ns=(0,0,True,nextfirst) if enters else (x,y,False,nextfirst)
        else:
            if x>=rule.m and y>=rule.n: enters=True
            elif x>=rule.m: winner=0
            elif y>=rule.n: winner=1
            ns=(0,0,True,0) if enters else (x,y,False,0)
        out.append((mass,ns if winner is None else None,winner,2,enters))
    return out

def exact(rule=Rule(),model=Model()):
    if not model.iid: raise ValueError('iid exact solver requires constant independent team probabilities; use forward')
    p,q=model.p,model.q; d=p+q-2*p*q
    sdwin=p*(1-q)/d
    @lru_cache(None)
    def f(state,r):
        if state[2]: return (sdwin,1/d,2/d,0.)
        values=[0.,1.,0.,0.]; loop=0.
        for w,ns,win,k,enters in branches(rule,model,state,r):
            values[2]+=w*k
            if win is not None: values[0]+=w*(win==0)
            elif ns==state and rule.kind!='standard': loop+=w
            else:
                z=f(ns,r+1)
                values[0]+=w*z[0];values[1]+=w*z[1];values[2]+=w*z[2];values[3]+=w*(1 if enters else z[3])
        return tuple(x/(1-loop) for x in values)
    win,rounds,kicks,sd=f((0,0,False,0),0)
    return dict(win_a=win,rounds=rounds,kicks=kicks,sudden_death=sd,bias=win-.5)

def event_sum(m,n,p,q,limit=300,printed=False):
    """Independent negative-binomial hitting-time calculation.
    printed=True reproduces the manuscript's problematic max bound in Prop 2.
    Correct bound is min(r,m-1). Truncated sum, checked against exact DP.
    """
    d=p+q-2*p*q; win=duration=tie=0.
    for r in range(1,limit+1):
        fa=comb(r-1,m-1)*p**m*(1-p)**(r-m) if r>=m else 0
        fb=comb(r-1,n-1)*q**n*(1-q)**(r-n) if r>=n else 0
        cdf=lambda t,z:sum(comb(r,i)*z**i*(1-z)**(r-i) for i in range(min(r,t)+1))
        aw=fa*cdf(n-1,q);bw=fb*cdf(max(r,m-1) if printed else m-1,p);t=fa*fb
        win+=aw+t*p*(1-q)/d
        duration+=r*(aw+bw)+(r+1/d)*t;tie+=t
    return dict(win_a=win,rounds=duration,sudden_death=tie)

def forward(rule,model,horizon=150,tail_at=10):
    if model.latent_sd: raise ValueError('latent mixture requires MC')
    states={(0,0,False,0):1.};wa=wb=ek=er=sd=0.;tail=None;pmf=[]
    for r in range(horizon):
        er+=sum(states.values());new=defaultdict(float);ended=0.
        for st,mass in states.items():
            for w,ns,win,k,enters in branches(rule,model,st,r):
                v=mass*w;ek+=v*k;sd+=v*enters
                if win is None:new[ns]+=v
                else:wa+=v*(win==0);wb+=v*(win==1);ended+=v
        states=new;pmf.append(ended)
        if r+1==tail_at:tail=sum(states.values())
    residual=sum(states.values())
    return dict(win_a=wa,win_a_upper=wa+residual,win_b=wb,residual=residual,
                rounds_restricted=er,kicks_restricted=ek,sudden_death=sd,tail=tail,pmf=pmf)

def wilson(k,n,z=1.959963984540054):
    p=k/n;den=1+z*z/n;c=(p+z*z/(2*n))/den;h=z*sqrt(p*(1-p)/n+z*z/(4*n*n))/den
    return [c-h,c+h]

def monte_carlo(rule,model,N=20000,seed=20261014,horizon=200,tail_at=10):
    if N<1:raise ValueError('N positive')
    rng=random.Random(seed);wins=censored=sdcount=long=0;dur=[];kicks=[]
    for _ in range(N):
        shock=(rng.gauss(0,model.latent_sd),rng.gauss(0,model.latent_sd)) if model.latent_sd else (0,0)
        st=(0,0,False,0);total=0;entered=False
        for r in range(horizon):
            # Independent trajectory sampler uses raw kicks, not probability branch draws.
            a,b,sd,first=st
            first=0 if rule.order=='ABAB' else r%2 if rule.order=='ABBA' else first
            mask=0;win=None
            for slot,team in enumerate((first,1-first)):
                goal=int(rng.random()<model.prob(team,slot,r,a,b,shock));total+=1;mask|=goal<<team
                a+=goal*(team==0);b+=goal*(team==1)
                if rule.kind=='sequential':win=0 if a>=rule.m else 1 if b>=rule.n else None
                elif rule.kind=='standard' and r<5:
                    ca=r+int(team==0 or slot==1);cb=r+int(team==1 or slot==1)
                    win=0 if a>b+5-cb else 1 if b>a+5-ca else None
                if win is not None:break
            nxtfirst=(r+1)%2 if rule.order=='ABBA' else (0 if mask==2 else 1 if mask==1 else 1-first) if rule.order=='catchup' else 0
            if win is None:
                if sd:win=0 if a>b else 1 if b>a else None;st=(0,0,True,nxtfirst)
                elif rule.kind=='standard':
                    if r==4:
                        win=0 if a>b else 1 if b>a else None
                        if win is None: entered=True;st=(0,0,True,nxtfirst)
                    else:st=(a,b,False,nxtfirst)
                else:
                    if a>=rule.m and b>=rule.n:entered=True;st=(0,0,True,0)
                    elif a>=rule.m:win=0
                    elif b>=rule.n:win=1
                    else:st=(a,b,False,0)
            if win is not None:break
        else:censored+=1
        wins+=win==0;sdcount+=entered;long+=r+1>tail_at;dur.append(r+1);kicks.append(total)
    return dict(win_a=wins/N,ci95=wilson(wins,N),win_a_upper=(wins+censored)/N,censored=censored,N=N,seed=seed,
                rounds_restricted=sum(dur)/N,kicks_restricted=sum(kicks)/N,sudden_death=sdcount/N,tail=long/N,
                rounds_se=sqrt((sum(x*x for x in dur)-sum(dur)**2/N)/(N-1)/N) if N>1 else 0)

def bisect(f,lo=.000001,hi=.999999,tol=1e-12):
    if f(lo)*f(hi)>0:raise ValueError('root not bracketed')
    while hi-lo>tol:
        mid=(lo+hi)/2
        if f(lo)*f(mid)<=0:hi=mid
        else:lo=mid
    return (lo+hi)/2

def optimize(scenarios,candidates,max_rounds=8.,method='exact',N=5000,seed=20261014,horizon=150):
    """Finite-set minimax, not a certificate over a continuous uncertainty set.
    MC uses Bonferroni simultaneous Hoeffding bounds, including censoring;
    candidates ranked by conservative upper bound. Revalidate winner independently.
    """
    rows=[];z=sqrt(log(2*len(candidates)*len(scenarios)/.05)/(2*N))
    for rule in candidates:
        results=[exact(rule,s) if method=='exact' else monte_carlo(rule,s,N,seed+i,horizon) for i,s in enumerate(scenarios)]
        worst=max(abs(x['win_a']-.5) for x in results)
        upper=max(min(.5,abs(x['win_a']-.5)+z+x['censored']/N) for x in results) if method=='mc' else worst
        duration=max(x.get('rounds',x.get('rounds_restricted')) for x in results)
        # MC duration Hoeffding bound applies to capped rounds; reject any censoring.
        durupper=duration+horizon*z if method=='mc' else duration
        feasible=durupper<=max_rounds and all(x.get('censored',0)==0 for x in results)
        rows.append(dict(**asdict(rule),worst_bias=worst,bias_upper=upper,worst_rounds=duration,duration_upper=durupper,feasible=feasible))
    rows.sort(key=lambda x:(not x['feasible'],x['bias_upper'],x['worst_rounds']))
    return rows
