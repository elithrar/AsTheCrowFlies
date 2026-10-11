"""Reuse MONOLITH's read-only reader, writing only this checkout's .work directory."""
from pathlib import Path
import hashlib, json, os, subprocess, sys
ROOT = Path(__file__).resolve().parents[1]
PRIOR = ROOT.parent / 'task-2'
GAME = Path(r'C:\Program Files (x86)\World of Warcraft')
BUILD = 'f6e309c700cea095978aeb5d85210df4'
NAMES = ['TaxiNodes','TaxiPath','TaxiPathNode','UiMap','UiMapAssignment','AreaTable']
def main():
    lines = (GAME/'.build.info').read_text().splitlines()
    keys = [x.split('!')[0] for x in lines[0].split('|')]
    row = next(dict(zip(keys,l.split('|'))) for l in lines[1:] if 'wow_classic_beta' == l.split('|')[-1])
    assert row['Build Key'] == BUILD and row['Version'] == '1.60.1.70338'
    cfg = (GAME/'Data/config'/BUILD[:2]/BUILD[2:4]/BUILD).read_bytes()
    assert hashlib.md5(cfg).hexdigest() == BUILD and b'ForeverBeta' in cfg
    assert (GAME/'_classic_beta_/.flavor.info').read_text().splitlines()[1] == 'wow_classic_beta'
    listfile = PRIOR/'tools/community-listfile.csv'
    wanted = {f'dbfilesclient/{n.lower()}.db2': n for n in NAMES}
    ids = {}
    for line in listfile.read_text().splitlines():
        fid, name = line.split(';',1)
        if name in wanted: ids[wanted[name]] = int(fid)
    assert len(ids)==len(NAMES)
    out = ROOT/'.work/raw'; out.mkdir(parents=True,exist_ok=True)
    env = os.environ.copy()
    env['PATH'] = str(PRIOR/'tools/llvm-mingw-20261006-ucrt-x86_64/bin')+os.pathsep+env['PATH']
    reader = PRIOR/'tools/casc_extract.exe'
    run = subprocess.run([str(reader),str(GAME),str(out)], input=''.join(f'#{ids[n]}\n' for n in NAMES), text=True,capture_output=True,env=env)
    (ROOT/'.work/extraction.tsv').write_text(run.stdout)
    (ROOT/'.work/reader.log').write_text(run.stderr)
    manifest = dict(build=row['Version'],buildKey=BUILD,product=row['Product'],readerSHA256=hashlib.sha256(reader.read_bytes()).hexdigest(),listfileSHA256=hashlib.sha256(listfile.read_bytes()).hexdigest(),tables={})
    for name,fid in ids.items():
        p=out/f'{fid}.bin'
        manifest['tables'][name]=dict(fileDataID=fid,readable=p.exists(),sha256=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None)
    (ROOT/'.work/extraction.json').write_text(json.dumps(manifest,indent=2))
    print(run.stdout); print(run.stderr[-3000:]); print(json.dumps(manifest,indent=2))
    assert run.returncode==0
if __name__=='__main__': main()
