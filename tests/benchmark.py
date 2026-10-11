from pathlib import Path
import sys,time,json,statistics
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'.work/pydeps'))
from lupa.lua51 import LuaRuntime
l=LuaRuntime(unpack_returned_tuples=True);l.globals().ROOT=str(ROOT).replace('\\','/')
l.execute('''N={};for _,f in ipairs({'Model','Settings','Routes','Data/Registry'}) do assert(loadfile(ROOT..'/AsTheCrowFlies/'..f..'.lua'))('ATCF',N) end
assert(loadfile(ROOT..'/.work/LocalTaxi.lua'))('ATCF',N)
data=N.Data.LocalTaxi;origin=data.nodes[2];destinations={data.nodes[4]};context={known={},faction='Alliance',speed=7,flightPrior=32}
for _,e in ipairs(data.edges) do e.start=data.nodes[e.from];e.finish=data.nodes[e.to] end
for id in pairs(data.nodes) do context.known[id]={state='known'} end
function bench() return N.Routes.Plan(origin,destinations,data,context) end
''')
times=[]
for _ in range(30):
    start=time.perf_counter();l.globals().bench();times.append((time.perf_counter()-start)*1000)
report=dict(lua='5.1',iterations=len(times),median_ms=round(statistics.median(times),3),max_ms=round(max(times),3),scope=f"One destination; local {len(list(l.globals().data.nodes))}-node / {len(l.globals().data.edges)}-edge graph; offline MONOLITH CPU")
(ROOT/'docs/performance.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
