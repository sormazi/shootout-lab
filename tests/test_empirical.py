import unittest,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
from empirical import load_shootouts
class EmpiricalTests(unittest.TestCase):
 @unittest.skipUnless((ROOT/'data/data_final.csv').exists(),'Retrieve source data with fetch_sources.py')
 def test_authentic_match_invariants_and_counts(self):
  matches,counts=load_shootouts(ROOT/'data/data_final.csv')
  self.assertEqual(counts,{'D1':60287,'D2':51007,'D3':45402})
  self.assertEqual(len(matches),1759)
  self.assertEqual(sum(x['first_win'] for x in matches),859)
  self.assertEqual(sum(len(x['features']) for x in matches),18903)
if __name__=='__main__':unittest.main()
