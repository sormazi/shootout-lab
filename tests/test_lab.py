import sys,unittest,random
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from lab import *
class ResearchTests(unittest.TestCase):
 def test_small_closed_forms(self):
  for p,q in ((.75,.6),(.4,.8),(.9,.2)):
   x=exact(Rule(m=2,n=1),Model(p,q));d=p+q-2*p*q;e=p+q-p*q
   self.assertAlmostEqual(x['win_a'],p*p*(1-q)**2/(d*e),12)
   self.assertAlmostEqual(x['rounds'],(2*p+q-3*p*q)/(d*e),12)
 def test_tables(self):
  for m,n,q,er in ((5,4,.60,6.06),(4,3,.56,4.71),(3,2,.50,3.33),(2,1,.34,1.85)):
   root=bisect(lambda t:exact(Rule(m=m,n=n),Model(.75,t))['win_a']-.5)
   self.assertLess(abs(root-q),.006) # Manuscript (3,2) reports .50; exact root .494377, outside strict 2-decimal rounding.
   self.assertAlmostEqual(exact(Rule(m=m,n=n))['rounds'],er,2)
 def test_independent_formula(self):
  rng=random.Random(33)
  for _ in range(20):
   p,q=rng.uniform(.2,.9),rng.uniform(.2,.9);m,n=rng.randrange(1,7),rng.randrange(1,7)
   x=exact(Rule(m=m,n=n),Model(p,q));y=event_sum(m,n,p,q)
   for k in y:self.assertAlmostEqual(x[k],y[k],10)
 def test_symmetry(self):
  for p in (.2,.5,.75,.9):
   for rule in (Rule(m=4,n=4),Rule(kind='standard'),Rule(kind='standard',order='ABBA'),Rule(kind='standard',order='catchup')):
    self.assertAlmostEqual(exact(rule,Model(p,p))['win_a'],.5,12)
 def test_probability_conservation(self):
  for rule in (Rule(),Rule(kind='standard'),Rule(kind='sequential'),Rule(kind='standard',order='ABBA'),Rule(kind='standard',order='catchup')):
   x=forward(rule,Model(.75,.65,pressure=.1,order_logit=.08),60)
   self.assertAlmostEqual(x['win_a']+x['win_b']+x['residual'],1,12)
 def test_forward_exact(self):
  for rule in (Rule(),Rule(kind='standard'),Rule(kind='sequential'),Rule(kind='standard',order='ABBA'),Rule(kind='standard',order='catchup')):
   x=exact(rule);y=forward(rule,Model(),100)
   self.assertAlmostEqual(x['win_a'],y['win_a'],11)
   self.assertAlmostEqual(x['rounds'],y['rounds_restricted'],10)
   self.assertAlmostEqual(x['kicks'],y['kicks_restricted'],10)
 def test_early_stopping_and_targets(self):
  model=Model()
  # At 4-2 after round 4, standard already over; target still alive.
  bs=branches(Rule(),model,(4,2,False,0),4)
  self.assertTrue(any(ns is not None for _,ns,_,_,_ in bs))
  bs=branches(Rule(kind='sequential'),model,(4,3,False,0),4)
  self.assertTrue(all(not enter for *_,enter in bs))
  self.assertTrue(any(win==0 and k==1 for _,_,win,k,_ in bs))
 def test_mc(self):
  for rule in (Rule(),Rule(kind='standard'),Rule(kind='sequential')):
   x=exact(rule);y=monte_carlo(rule,Model(),15000,66)
   self.assertLess(abs(x['win_a']-y['win_a']),.018)
   self.assertLess(abs(x['rounds']-y['rounds_restricted']),.07)
 def test_invalid(self):
  for p,q in ((0,.5),(1,.5),(.5,0)):
   with self.assertRaises(ValueError):Model(p,q)
  with self.assertRaises(ValueError):Rule(m=0)
  with self.assertRaises(ValueError):exact(Rule(),Model(pressure=.1))
if __name__=='__main__':unittest.main()
