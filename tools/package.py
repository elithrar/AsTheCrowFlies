"""Build reproducible source or local-data development ZIP; never install it."""
from pathlib import Path
import argparse,hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--local-data',action='store_true');args=parser.parse_args()
    version='0.1.0-dev-local' if args.local_data else '0.1.0-dev-source'
    out=ROOT/'dist';out.mkdir(exist_ok=True)
    payload={}
    for p in sorted((ROOT/'AsTheCrowFlies').rglob('*')):
        if p.is_file() and p.name!='LocalTaxi.lua':payload['AsTheCrowFlies/'+p.relative_to(ROOT/'AsTheCrowFlies').as_posix()]=p.read_bytes()
    if args.local_data:
        taxi=(ROOT/'.work/LocalTaxi.lua').read_bytes();provenance=json.loads((ROOT/'docs/data-provenance.json').read_text())
        assert hashlib.sha256(taxi).hexdigest()==provenance['payloadSHA256']
        payload['AsTheCrowFlies/Data/Taxi.lua']=taxi
        payload['AsTheCrowFlies/DATA-PROVENANCE.json']=(ROOT/'docs/data-provenance.json').read_bytes()
    for name in ['README.md','NOTICES.md','plan.md','docs/COVERAGE.md','docs/VALIDATION.md','docs/data-provenance.json','docs/npc-coverage.json','docs/performance.json']:
        payload['AsTheCrowFlies/'+name]=(ROOT/name).read_bytes()
    if (ROOT/'LICENSE').exists():payload['AsTheCrowFlies/LICENSE']=(ROOT/'LICENSE').read_bytes()
    toc=payload['AsTheCrowFlies/AsTheCrowFlies.toc'].decode()
    for line in toc.splitlines():
        if line and not line.startswith('#'):assert 'AsTheCrowFlies/'+line in payload,line
    file=out/f'AsTheCrowFlies-{version}.zip'
    with zipfile.ZipFile(file,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for name,data in sorted(payload.items()):
            info=zipfile.ZipInfo(name,date_time=(2026,10,11,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o644<<16;z.writestr(info,data)
    report=dict(file=file.name,bytes=file.stat().st_size,sha256=hashlib.sha256(file.read_bytes()).hexdigest(),files={n:hashlib.sha256(v).hexdigest() for n,v in payload.items()})
    (out/(version+'-manifest.json')).write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='files'},indent=2))
if __name__=='__main__':main()
