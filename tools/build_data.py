"""Deterministic local client graph. Raw/derived Blizzard payload stays outside Git."""
from pathlib import Path
import json, math, collections, hashlib
ROOT=Path(__file__).resolve().parents[1]
def lua(v):
    if v is None:return 'nil'
    if v is True:return 'true'
    if v is False:return 'false'
    if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
    if isinstance(v,(int,float)):
        assert math.isfinite(v);return format(v,'.10g')
    if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
    return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in sorted(v.items(),key=lambda p:str(p[0])))+'}'
def build(tables):
    for name,layout in [('TaxiNodes','E7B597F0'),('TaxiPath','A303DE51'),('TaxiPathNode','FE362E70')]:
        t=tables[name]
        if t['layoutHash']!=layout or len(t['rows'])!=t['sourceRowCount']:raise ValueError('Unsupported/incomplete table: '+name)
    ns={};excluded=[];groups=collections.defaultdict(list)
    for n in tables['TaxiNodes']['rows']:
        if n['ID'] in ns:raise ValueError('Duplicate taxi node')
        if n['ContinentID'] not in (0,1):continue
        assert all(math.isfinite(x) for x in n['Pos'])
        ns[n['ID']]=dict(id=n['ID'],name=n['Name_lang'],map=n['ContinentID'],x=n['Pos'][0],y=n['Pos'][1],z=n['Pos'][2],condition=n['ConditionID'],visibility=n['VisibilityConditionID'],flags=n['Flags'],category='flight',confidence='client-candidate')
    for p in tables['TaxiPathNode']['rows']:groups[p['PathID']].append(p)
    edges=[];ids=set()
    for e in tables['TaxiPath']['rows']:
        if e['ID'] in ids:raise ValueError('Duplicate taxi path')
        ids.add(e['ID']);a,b=ns.get(e['FromTaxiNode']),ns.get(e['ToTaxiNode']);points=sorted(groups[e['ID']],key=lambda p:p['NodeIndex'])
        reason=None
        if not a or not b:reason='unsupported/missing endpoint'
        elif a['map']!=b['map']:reason='cross-continent transition'
        elif a['id']==b['id']:reason='scripted/self-loop path'
        elif a['condition'] or b['condition'] or a['visibility'] or b['visibility']:reason='unresolved condition'
        elif len(points)<2 or [p['NodeIndex'] for p in points]!=list(range(len(points))):reason='incomplete spline'
        elif any(p['ContinentID']!=a['map'] for p in points):reason='spline continent transition'
        elif any(p['Flags'] or p['Delay'] or p['ArrivalEventID'] or p['DepartureEventID'] for p in points):reason='unresolved spline event/flag/delay'
        if reason:excluded.append(dict(id=e['ID'],reason=reason));continue
        xyz=[p['Loc'] for p in points]
        assert all(math.isfinite(c) for p in xyz for c in p)
        gaps=[math.dist([a[k] for k in ('x','y','z')],xyz[0]),math.dist(xyz[-1],[b[k] for k in ('x','y','z')])]
        # An endpoint more than 150 yards away cannot establish passenger connectivity.
        if max(gaps)>150:
            excluded.append(dict(id=e['ID'],reason='spline endpoint mismatch'));continue
        splineDistance=sum(math.dist(p,q) for p,q in zip(xyz,xyz[1:]))
        distance=splineDistance+sum(gaps)
        edges.append(dict(id=e['ID'],**{'from':a['id'],'to':b['id']},distance=distance,splineDistance=splineDistance,endpointGap=sum(gaps),cost=e['Cost'],mode='flight',quality='candidate',points=[[p[0],p[1]] for p in xyz]))
    maps=sorted({r['UiMapID'] for r in tables.get('UiMapAssignment',{}).get('rows',[]) if r['MapID'] in (0,1)})
    return dict(build='1.60.1.70338',nodes=ns,edges=edges,taxiMaps=maps),excluded
def main():
    tables={n:json.loads((ROOT/'.work/tables'/f'{n}.json').read_text()) for n in ['TaxiNodes','TaxiPath','TaxiPathNode','UiMap','UiMapAssignment']}
    data,excluded=build(tables)
    payload=('local _,N=...\nN.Data.LocalTaxi='+lua(data)+'\n').encode()
    target=ROOT/'.work/LocalTaxi.lua';target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(payload)
    report=json.loads((ROOT/'.work/extraction.json').read_text())
    report.update(dict(decoded={k:{x:v[x] for x in ['sourceRowCount','layoutHash','schemaSha256','schemaCommit']} for k,v in tables.items()},candidateNodes=len(data['nodes']),candidateEdges=len(data['edges']),excluded=excluded,payloadSHA256=hashlib.sha256(payload).hexdigest(),hotfixes='Not applied: candidate-only graph; runtime offered-itinerary validation required',rights='Local development payload only; no redistribution license inferred',groundCorridors=0))
    (ROOT/'docs/data-provenance.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:report[k] for k in ['candidateNodes','candidateEdges','groundCorridors','payloadSHA256']}));print(collections.Counter(x['reason'] for x in excluded))
if __name__=='__main__':main()
