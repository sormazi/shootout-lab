"""Retrieve public replication inputs. Verify hashes before analysis."""
from pathlib import Path
import urllib.request,hashlib,json
ROOT=Path(__file__).resolve().parent
p=json.loads((ROOT/'data/provenance.json').read_text())
for entry in p['source_files']:
 if entry['file']=='osf_node_metadata.json':continue
 target=ROOT/'data'/entry['file']
 if not target.exists():
  request=urllib.request.Request(entry['url'],headers={'User-Agent':'ShootoutResearchLab/1.0'})
  with urllib.request.urlopen(request,timeout=60) as r:target.write_bytes(r.read())
 actual=hashlib.sha256(target.read_bytes()).hexdigest()
 if actual!=entry['sha256']:raise RuntimeError('Hash mismatch: '+entry['file'])
 print(entry['file']+' verified')
