/* Browser solver: separate implementation, parity checked against Python fixtures. */
(function(global){
const logit=x=>Math.log(x/(1-x)),sigmoid=x=>1/(1+Math.exp(-Math.max(-35,Math.min(35,x))));
function prob(model,team,slot,r,a,b){const line=team?model.lineupB:model.lineupA;return sigmoid(logit(team?model.q:model.p)+(model.delta||0)*(slot?-1:1)-(model.pressure||0)*Math.max(0,team?a-b:b-a)-(model.fatigue||0)*Math.min(r,10)+(line&&line.length?line[r%line.length]:0));}
function branches(rule,model,state,r){let [a,b,sd,first]=state;if(rule.order==='ABAB')first=0;else if(rule.order==='ABBA')first=r%2;let interim=[[1,a,b,0]],out=[];
 for(let slot=0;slot<2;slot++){let team=slot?1-first:first,nxt=[];
  for(let [mass,x,y,mask] of interim){let p=prob(model,team,slot,r,x,y);for(let goal=0;goal<2;goal++){let xx=x+goal*(team===0),yy=y+goal*(team===1),bits=mask|(goal<<team),win=null,w=mass*(goal?p:1-p);
   if(rule.kind==='sequential'){if(xx>=rule.m)win=0;else if(yy>=rule.n)win=1;}
   else if(rule.kind==='standard'&&r<5){let ca=r+Number(team===0||slot===1),cb=r+Number(team===1||slot===1);if(xx>yy+5-cb)win=0;else if(yy>xx+5-ca)win=1;}
   if(win!==null)out.push([w,null,win,slot+1,false]);else nxt.push([w,xx,yy,bits]);
  }}interim=nxt;
 }
 for(let [mass,x,y,mask] of interim){let win=null,enters=false,nextfirst=rule.order==='ABBA'?(r+1)%2:rule.order==='catchup'?(mask===2?0:mask===1?1:1-first):0,ns;
  if(sd){if(x!==y)win=x>y?0:1;ns=[0,0,true,nextfirst];}
  else if(rule.kind==='standard'){if(r===4){if(x!==y)win=x>y?0:1;else enters=true;}ns=enters?[0,0,true,nextfirst]:[x,y,false,nextfirst];}
  else{if(x>=rule.m&&y>=rule.n)enters=true;else if(x>=rule.m)win=0;else if(y>=rule.n)win=1;ns=enters?[0,0,true,0]:[x,y,false,0];}
  out.push([mass,win===null?ns:null,win,2,enters]);
 }return out;
}
function exact(rule,model){if([model.delta,model.pressure,model.fatigue].some(Boolean)||model.lineupA?.length||model.lineupB?.length)throw Error('Use finite-horizon solver for changing probabilities');let memo=new Map(),p=model.p,q=model.q,d=p+q-2*p*q;
 function f(state,r){if(state[2])return [p*(1-q)/d,1/d,2/d,0];let key=state.join(',')+(rule.kind==='standard'?','+r:''),cached=memo.get(key);if(cached)return cached;let values=[0,1,0,0],loop=0;
  for(let [w,ns,win,k,enters]of branches(rule,model,state,r)){values[2]+=w*k;if(win!==null)values[0]+=w*Number(win===0);else if(rule.kind!=='standard'&&ns.join(',')===state.join(','))loop+=w;else{let z=f(ns,r+1);values[0]+=w*z[0];values[1]+=w*z[1];values[2]+=w*z[2];values[3]+=w*(enters?1:z[3]);}}
  values=values.map(x=>x/(1-loop));memo.set(key,values);return values;
 }let [win,rounds,kicks,sd]=f([0,0,false,0],0);return {win,rounds,kicks,sd,residual:0};
}
function forward(rule,model,horizon=100){let states=new Map([['0,0,false,0',[[0,0,false,0],1]]]),win=0,wb=0,rounds=0,kicks=0,sd=0,tail=0,pmf=[];
 for(let r=0;r<horizon;r++){let next=new Map(),ended=0;rounds+=[...states.values()].reduce((s,x)=>s+x[1],0);
  for(let [state,mass] of states.values())for(let [w,ns,winner,k,enters]of branches(rule,model,state,r)){let v=mass*w;kicks+=v*k;sd+=v*enters;if(winner!==null){win+=v*Number(winner===0);wb+=v*Number(winner===1);ended+=v;}else{let key=ns.join(',');next.set(key,[ns,v+(next.get(key)?.[1]||0)]);}}
  states=next;pmf.push(ended);if(r===9)tail=[...states.values()].reduce((s,x)=>s+x[1],0);
 }let residual=[...states.values()].reduce((s,x)=>s+x[1],0);return {win,wb,rounds,kicks,sd,tail,residual,pmf};
}
function rng(seed){return ()=>{let t=seed+=0x6D2B79F5;t=Math.imul(t^t>>>15,t|1);t^=t+Math.imul(t^t>>>7,t|61);return ((t^t>>>14)>>>0)/4294967296;};}
function mc(rule,model,N=10000,seed=20261014,horizon=100){let random=rng(seed),wins=0,censored=0,rounds=0,kicks=0,sd=0,tail=0;for(let i=0;i<N;i++){let state=[0,0,false,0],r=0,total=0,entered=false,win=null;
 for(;r<horizon;r++){let bs=branches(rule,model,state,r),u=random(),picked=bs[bs.length-1];for(let b of bs){u-=b[0];if(u<=0){picked=b;break;}}total+=picked[3];entered||=picked[4];if(picked[2]!==null){win=picked[2];break;}state=picked[1];}
 let length=Math.min(r+1,horizon);wins+=Number(win===0);censored+=Number(win===null);rounds+=length;kicks+=total;sd+=Number(entered);tail+=Number(length>10);}
 let p=wins/N,z=1.959964,den=1+z*z/N,c=(p+z*z/2/N)/den,h=z*Math.sqrt(p*(1-p)/N+z*z/4/N/N)/den;
 return {win:p,rounds:rounds/N,kicks:kicks/N,sd:sd/N,tail:tail/N,censored,residual:censored/N,ci:[c-h,c+h],N,seed};}
const rules=[{kind:'standard',m:5,n:4,order:'ABAB',name:'Standard ABAB'},{kind:'target',m:5,n:4,order:'ABAB',name:'Target (5,4)'},{kind:'sequential',m:5,n:4,order:'ABAB',name:'Sequential (5,4)'},{kind:'standard',m:5,n:4,order:'ABBA',name:'Standard ABBA'},{kind:'standard',m:5,n:4,order:'catchup',name:'Standard Catch-Up'}];
global.Shootout={exact,forward,mc,branches,rules};if(typeof module!=='undefined')module.exports=global.Shootout;
})(typeof window!=='undefined'?window:globalThis);
