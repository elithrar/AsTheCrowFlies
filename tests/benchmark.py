"""Offline Lua 5.1 measurements; client geometry is read locally, never exported.

Run --stage baseline before changes, then --stage final on the same machine.
Category records are synthetic workload points near exact-build flight nodes,
not asserted NPC locations. Results include Candidates + Plan, excluding load.
"""
from pathlib import Path
import argparse, hashlib, json, statistics, sys, time

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.work/pydeps'))
from lupa.lua51 import LuaRuntime

parser = argparse.ArgumentParser()
parser.add_argument('--stage', choices=('baseline', 'final'), default='final')
parser.add_argument('--iterations', type=int, default=30)
parser.add_argument('--search-only', action='store_true', help='Measure search without replacing existing route timings')
args = parser.parse_args()
if args.iterations < 5:
    parser.error('use at least 5 measured iterations')
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().ROOT = str(ROOT).replace('\\', '/')
lua.execute('''
N={};for _,f in ipairs({'Model','Settings','Routes','Data/Registry'}) do assert(loadfile(ROOT..'/AsTheCrowFlies/'..f..'.lua'))('ATCF',N) end
assert(loadfile(ROOT..'/.work/LocalTaxi.lua'))('ATCF',N)
data=N.Data.LocalTaxi
for _,e in ipairs(data.edges) do e.start=data.nodes[e.from];e.finish=data.nodes[e.to] end
ids={};for id in pairs(data.nodes) do ids[#ids+1]=id end;table.sort(ids)
origin=data.nodes[2]
function setup(mode,category,order)
    context={known={},faction='Alliance',speed=7,flightPrior=32,routeOrder=order,requireObserved=true}
    for i,id in ipairs(ids) do
        if mode=='known' then context.known[id]={state='known'}
        elseif mode=='discovery' then context.known[id]={state=i%3==0 and 'undiscovered' or 'known'}
        elseif mode=='locked' then context.known[id]={state=id==2 and 'known' or 'undiscovered'} end
    end
    destinations={data.nodes[4]}
    if category>0 then
        destinations={};local same={};for _,id in ipairs(ids) do if data.nodes[id].map==origin.map then same[#same+1]=id end end
        for i=1,category do local p=data.nodes[same[(i-1)%#same+1]]
            destinations[i]={id='workload:'..i,name='Synthetic candidate '..i,map=p.map,x=p.x+(i%11)*13,y=p.y+(i%7)*17}
        end
    end
end
local shortest=N.Routes.Shortest
function N.Routes.Shortest(...) calls=calls+1;return shortest(...) end
function bench()
    calls=0;local selected=N.Routes.Candidates(origin,destinations,data,context,12)
    local results=N.Routes.Plan(origin,selected,data,context)
    return #selected,#results,calls
end
function setupSearch(count)
    searchItems={};searchContext={class='MAGE',faction='Alliance'}
    for i=1,count do
        local kind=i%4;local p={id='synthetic:'..i,name='Nora Example '..i,map=origin.map,x=origin.x+(i%31)*40,y=origin.y+(i%19)*30,zone='Synthetic zone'}
        if kind==0 then p.category='class';p.class='WARRIOR';p.role='Warrior Trainer'
        elseif kind==1 then p.category='profession';p.profession='Blacksmithing';p.role='Blacksmith'
        elseif kind==2 then p.category='quest';p.name='Warrior Trainer Enthusiast '..i
        else p.category='quest' end
        searchItems[i]=p
    end
end
function searchBench(query)
    return #N.Model.Search(searchItems,query,{categories={}},searchContext,40,origin)
end
''')

workloads = [
    ('one_known_distance', 'known', 0, 'distance'),
    ('one_known_time', 'known', 0, 'time'),
    ('one_unknown', 'unknown', 0, 'time'),
    ('one_discovery', 'discovery', 0, 'time'),
    ('one_locked', 'locked', 0, 'time'),
    ('category64_known', 'known', 64, 'time'),
    ('category500_known', 'known', 500, 'time'),
    ('category500_unknown', 'unknown', 500, 'time'),
    ('category500_discovery', 'discovery', 500, 'time'),
    ('category2000_known', 'known', 2000, 'time'),
    ('category2000_discovery', 'discovery', 2000, 'time'),
]
measurements = {}
for name, mode, category, order in ([] if args.search_only else workloads):
    lua.globals().setup(mode, category, order)
    for _ in range(3):
        lua.globals().bench()
    times = []
    for _ in range(args.iterations):
        start = time.perf_counter()
        selected, results, calls = lua.globals().bench()
        times.append((time.perf_counter() - start) * 1000)
    measurements[name] = dict(median_ms=round(statistics.median(times), 3),
                              p95_ms=round(sorted(times)[int(.95*(len(times)-1))], 3),
                              max_ms=round(max(times), 3), selected=selected,
                              results=results, shortest_calls=calls)

path = ROOT / 'docs/performance.json'
report = json.loads(path.read_text()) if path.exists() else {}
if report.get('schema') != 2:
    report = {'schema': 2}
report.update(lua='5.1 (Lupa; offline MONOLITH CPU)',
              graph=dict(nodes=len(list(lua.globals().data.nodes)), edges=len(lua.globals().data.edges),
                         build='1.60.1.70338', sha256=hashlib.sha256((ROOT/'.work/LocalTaxi.lua').read_bytes()).hexdigest()),
              scope='Candidates + Plan; exact local taxi geometry; synthetic category points, not NPC coordinates; no in-game frame-time claim')
if measurements:
    report[args.stage] = dict(iterations=args.iterations, warmups=3, workloads=measurements)
search_measurements = {}
for count in (500, 2000):
    lua.globals().setupSearch(count)
    for name, query in [('role', 'Warrior Trainer'), ('prefix', 'Blacks...'), ('typo', 'Blacksmthing'), ('exact_npc', 'Nora Example 3'), ('unmatched_typo', 'Unfindabble')]:
        for _ in range(3):
            lua.globals().searchBench(query)
        times = []
        for _ in range(args.iterations):
            start = time.perf_counter()
            matches = lua.globals().searchBench(query)
            times.append((time.perf_counter()-start)*1000)
        search_measurements[f'{count}_{name}'] = dict(median_ms=round(statistics.median(times), 3), p95_ms=round(sorted(times)[int(.95*(len(times)-1))], 3), max_ms=round(max(times), 3), results=matches)
report['search'] = dict(iterations=args.iterations, warmups=3, scope='Synthetic service/NPC records, not actual NPC placements; includes relevance scoring, distance sorting, 40-result truncation', workloads=search_measurements)
report['ground_time'] = {'formula': 'bearing yards / valid movement speed * 1.35; other ground quality uses multiplier 1',
                         'limits': 'Uncalibrated allowance, not terrain navigation or guaranteed time; zero yards stays zero; flight timings and physical yards unchanged.'}
report['complexity'] = {'symbols': 'C input candidate records; V graph nodes; E graph edges; D shortlisted destinations <=24 in runtime (limit12); K<=5 searches per usable/locked pass',
                       'search_time': 'O(C*T*W*L*b + C log C); T<=6 query tokens, W<=64 field words, L<=24 bytes, edit band b<=2; query-local cache <=4096 comparisons',
                       'shortest_time': 'O(V^2 + E); at most 5V discovery/flight/terminal states, linear frontier scan',
                       'shortest_space': 'O(V + E)',
                       'shortlist_time': 'O(C log C + V^2 + E + C*V) in time mode; O(C log C) in distance mode',
                       'plan_time': 'O(D*K*(V^2+E) + D*K*V + D*K*log(D*K)); at most two passes, locked pass omitted once 3 usable choices exist',
                       'plan_space': 'O(V+E+D*K*V) mutable metadata; immutable geometry shared',
                       'scope': 'Bounded heuristic alternatives and <=24-candidate shortlist, not exhaustive k-shortest paths or global nearest-time proof.'}
report['comparison_notes'] = 'Baseline captured before the changes on matching workloads. one_locked and category2000 workloads were added afterward; no pre-change baseline is claimed for those.'
report['source_sha256'] = {name: hashlib.sha256((ROOT/'AsTheCrowFlies'/name).read_bytes()).hexdigest() for name in ('Model.lua','Routes.lua','Settings.lua')}
path.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report['search'] if args.search_only else report[args.stage], indent=2))
