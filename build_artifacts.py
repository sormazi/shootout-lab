"""Refresh self-contained browser fixtures, downloads, and source manifest."""
from pathlib import Path
import json,csv,html,re,shutil,hashlib
ROOT=Path(__file__).resolve().parent;D=ROOT/'dist';R=ROOT/'results'
def readcsv(name):
 with (R/name).open() as f:return list(csv.DictReader(f))
def render_markdown(text):
 out=[];paragraph=[]
 def inline(s):
  s=html.escape(s)
  s=re.sub(r'\[([^\]]+)\]\((https?://[^\s)]+)\)',r'<a href="\2" target="_blank" rel="noreferrer">\1</a>',s)
  return re.sub(r'`([^`]+)`',r'<code>\1</code>',s)
 def flush():
  if paragraph:out.append('<p>'+inline(' '.join(paragraph))+'</p>');paragraph.clear()
 for line in text.splitlines():
  if line.startswith('# '):flush();out.append('<h2>'+inline(line[2:])+'</h2>')
  elif line.startswith('## '):flush();out.append('<h3>'+inline(line[3:])+'</h3>')
  elif not line.strip():flush()
  else:paragraph.append(line)
 flush();return '\n'.join(out)
fixtures=dict(summary=json.loads((R/'summary.json').read_text()),empirical=json.loads((ROOT/'data/empirical_results.json').read_text()),mcRobust=readcsv('robust_mc.csv'),transport=readcsv('empirical_transport.csv'),noteHTML=render_markdown((ROOT/'research_note.md').read_text()))
(D/'fixtures.js').write_text('window.LAB_DATA='+json.dumps(fixtures,ensure_ascii=False)+';\n')
for name in ['reproduction_figures.png','reproduction_figures.pdf','figure1.svg','figure_curves.csv','robust_mc.csv']:
 if (R/name).exists():shutil.copy2(R/name,D/name)
for name in ['README.md','research_note.md']:shutil.copy2(ROOT/name,D/name)
shutil.copy2(ROOT/'data/empirical_results.json',D/'empirical_results.json')
manifest={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in ROOT.rglob('*') if p.is_file() and '__pycache__' not in str(p) and '.openai' not in str(p) and '.git' not in str(p) and p.suffix!='.zip' and p.name!='file_hashes.json'}
(ROOT/'file_hashes.json').write_text(json.dumps(manifest,indent=2))
print('Browser fixtures and manifest refreshed')
