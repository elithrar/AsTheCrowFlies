local N={}
for _,name in ipairs({'Model','Settings','Routes','Navigation'}) do assert(loadfile(ROOT..'/AsTheCrowFlies/'..name..'.lua'))('AsTheCrowFlies',N) end
local M,S,R,V=N.Model,N.Settings,N.Routes,N.Navigation
local count=0
local function test(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));count=count+1 end
local function pos(x,y,id) return {x=x,y=y or 0,map=0,uiMapID=1,id=id,name=tostring(id),confidence='observed'} end
local ctx={known={[1]={state='known'},[2]={state='known'},[3]={state='known'},[4]={state='known'}},faction='Alliance',speed=7,flightPrior=32}
test('coordinate identity and cross-map rejection',function()
    assert(M.Distance(pos(0),pos(3,4))==5);local p=pos(0);p.map=1;assert(not M.Distance(p,pos(0)))
    p=pos(0);p.uiMapID=2;assert(not M.SameFloor(p,pos(0)))
    assert(not M.Position({x=0/0,y=1,map=0}))
end)
test('cardinal bearings and rotation',function()
    local e,n=M.Vector(pos(0),pos(100),0);assert(e==0 and n==100)
    e,n=M.Vector(pos(0),pos(0,-100),0);assert(e==100 and n==0)
    e,n=M.Vector(pos(0),pos(100),math.pi/2);assert(math.abs(e-100)<1e-6 and math.abs(n)<1e-6)
    local x,y,clip=M.Minimap(100,100,50,200,200,'ROUND');assert(clip and math.abs(x^2+y^2-90^2)<1e-6)
    x,y=M.Minimap(100,100,50,200,200,'SQUARE');assert(x==90 and y==90)
end)
test('flight polyline clips crossing segments without inventing ground paths',function()
    local x1,y1,x2,y2=M.ClipSegment(-1,.5,2,.5);assert(x1==0 and y1==.5 and x2==1 and y2==.5)
    assert(not M.ClipSegment(-1,-1,-.5,-.5));assert(not M.ClipSegment(0/0,0,1,1))
    x1,y1,x2,y2=M.ClipSegment(.5,-1,.5,2);assert(x1==.5 and y1==0 and x2==.5 and y2==1)
end)
test('search duplicates accents class and factions',function()
    local items={{id='b',name='Élan',category='class',class='MAGE',faction='Alliance'},{id='a',name='Élan',category='class',class='MAGE',faction='Alliance'},{id='c',name='Elan',category='class',class='MAGE',faction='Horde'}}
    local hits=M.Search(items,'elan',{category='class'},{class='MAGE',faction='Alliance'});assert(#hits==2 and hits[1].id=='a','hits='..#hits..' fold='..M.Fold('Élan'))
    assert(#M.Search(items,'',{category='class'},{class='WARRIOR',faction='Alliance'})==0)
end)
test('speed fallbacks reject invalid and taxi samples',function()
    assert(M.Speed(0,7)==7);assert(M.Speed(nil,nil)==7);assert(M.Speed(100,7)==7);assert(M.Speed(50,7,8,true)==8);assert(M.Speed(10,7,10)==10)
end)
test('saved settings sanitize preserve and isolate builds',function()
    local p=S.Load({scale=999,font='Expressway',width=299,locked=true});assert(p.scale==1.6 and p.width==299 and p.locked)
    local _,readOnly=S.Load({version=99});assert(readOnly)
    assert(not next(S.Character({version=1,build='old',known={[2]={state='known'}}},'new').known))
    local c=S.Character({version=1,build='a',known={[2]={state='known'}},offers={x=1},timings={x={20,0/0,-4,30}}},'a');assert(c.known[2] and #c.timings.x==2 and not next(c.offers))
end)
test('timing whole-itinerary bounds and outliers',function()
    local t={};for _,x in ipairs({60,62,58}) do assert(S.Sample(t,'1,2',x)) end
    assert(not S.Sample(t,'1,2',300));assert(S.Timing(t,'1,2')==60)
    for i=1,20 do S.Sample(t,'1,2',60) end;assert(#t['1,2']==9)
end)
local nodes={[1]=pos(10,0,1),[2]=pos(1000,0,2),[3]=pos(40,0,3),[4]=pos(950,0,4)}
local function edge(id,a,b,d) return {id=id,from=a,to=b,distance=d,mode='flight',start=nodes[a],finish=nodes[b]} end
local edges={edge(1,1,2,1900),edge(2,3,4,1000),edge(3,4,3,1400)}
test('directed graph disconnected and cycles',function()
    assert(not R.Shortest(nodes,edges,2,1,ctx,nil,true))
    local path,d=R.Shortest(nodes,edges,3,4,ctx,nil,true);assert(d==1000 and #path==1)
    local cyclic={edge(1,1,1,0),edge(2,1,3,0),edge(3,3,1,0),edge(4,3,4,100)}
    path,d=R.Shortest(nodes,cyclic,1,4,ctx,nil,true);assert(d==100 and #path==2)
end)
test('unknown flight conditional only; undiscovered blocked',function()
    assert(not R.Shortest(nodes,edges,3,4,ctx,nil,false))
    assert(not R.Shortest(nodes,edges,3,4,{known={},faction='Alliance'},nil,true))
    local c={known={[4]={state='undiscovered'}},faction='Alliance'};assert(not R.Shortest(nodes,edges,3,4,c,nil,true))
    local e=edge(3,3,4,50);e.faction='Horde';assert(not R.Shortest(nodes,{e},3,4,ctx,nil,true))
end)
test('farther departure wins and flight alternatives survive walking shortcut',function()
    local plans=R.Plan(pos(0),{pos(1100,0,'goal')},{nodes=nodes,edges=edges},ctx)
    assert(#plans==3 and plans[1].flight==0)
    assert(plans[2].legs[2].from==3 and plans[2].distance==1190 and plans[2].conditional)
    assert(plans[2].eta<plans[1].eta and plans[1].distance<plans[2].distance)
end)
test('whole offered itinerary and static hops share one alternative identity',function()
    local a,b=edge(101,1,3,40),edge(102,3,4,1000)
    local whole=edge('offered:101,102',1,4,1040);whole.timingKey='101,102';whole.offered=true
    assert(R.Summary({a,b},pos(1100,0,'goal'),ctx).signature==R.Summary({whole},pos(1100,0,'goal'),ctx).signature)
end)

test('confirmed offer wins equal-cost static duplicate',function()
    local a=edge(123,1,4,1000);local whole=edge('offered:123',1,4,1000);whole.timingKey='123';whole.offered=true
    local plans=R.Plan(pos(0),{pos(1100,0,'goal')},{nodes=nodes,edges={a,whole}},ctx)
    local flights=0;for _,r in ipairs(plans) do if r.flight>0 then flights=flights+1;assert(not r.conditional) end end
    assert(flights==1)
end)

test('open master suppresses contradicted itineraries until context closes',function()
    local a,b,c=edge(123,1,4,1000),edge(124,1,3,50),edge(125,3,4,1000)
    local offered=edge('offered:124',1,3,50);offered.timingKey='124';offered.offered=true
    local context=M.Copy(ctx);context.taxiFrom=1
    assert(not R.Shortest(nodes,{a},1,4,context,nil,true,true))
    assert(not R.Shortest(nodes,{a,b,c,offered},1,4,context,nil,true,true))
    local path=R.Shortest(nodes,{a,b,c,offered},1,3,context,nil,true,true);assert(path[1].offered)
    context.taxiFrom=nil;assert(R.Shortest(nodes,{a},1,4,context,nil,true,true))
end)

test('estimated time searches longer faster route including both walking legs',function()
    local a,b=edge(11,1,2,1100),edge(12,3,4,1600)
    local c=M.Copy(ctx);c.timings={['11']={100},['12']={30}};c.routeOrder='time'
    local plans=R.Plan(pos(0),{pos(1100,0,'goal')},{nodes=nodes,edges={a,b}},c)
    assert(plans[1].legs[2].id==12 and plans[1].distance==1790)
    assert(math.abs(plans[1].eta-(30+190/7))<1e-6)
    c.routeOrder='distance';local shortest=R.Plan(pos(0),{pos(1100,0,'goal')},{nodes=nodes,edges={a,b}},c)
    assert(shortest[1].flight==0 and shortest[2].legs[2].id==11)
    c.timings={};c.routeOrder='time';local uncalibrated=R.Plan(pos(0),{pos(1100,0,'goal')},{nodes=nodes,edges={a,b}},c)
    assert(uncalibrated[1].prior and uncalibrated[1].eta<uncalibrated[#uncalibrated].eta)
    assert(S.Load({routeOrder='time'}).routeOrder=='time' and S.Load({routeOrder='invalid'}).routeOrder=='distance')
end)

test('time shortlist includes farther NPC reached quickly through discovered flight',function()
    local ns={[1]=pos(0,0,1),[2]=pos(2000,0,2)}
    local data={nodes=ns,edges={{id=71,from=1,to=2,start=ns[1],finish=ns[2],mode='flight',distance=2100}}}
    local candidates={};for i=1,13 do candidates[i]=pos(500+i*10,0,'near'..i) end;candidates[14]=pos(2000,0,'far-trainer')
    local c=M.Copy(ctx);c.routeOrder='time';c.timings={['71']={30}}
    local selected=R.Candidates(pos(0),candidates,data,c,12);local found=false
    for _,p in ipairs(selected) do if p.id=='far-trainer' then found=true end end;assert(found and #selected<=24)
    local plans=R.Plan(pos(0),selected,data,c);assert(plans[1].destination.id=='far-trainer' and plans[1].flight>0 and plans[1].eta==30)
    c.known={};selected=R.Candidates(pos(0),candidates,data,c,12)
    for _,p in ipairs(selected) do assert(p.id~='far-trainer') end
end)

test('time shortlist cannot extend an authoritative offered itinerary',function()
    local ns={[1]=pos(0,0,1),[2]=pos(10000,0,2),[3]=pos(20000,0,3)}
    local data={nodes=ns,edges={{id='offered:71',timingKey='71',from=1,to=2,start=ns[1],finish=ns[2],mode='flight',distance=11000,offered=true},{id=72,from=2,to=3,start=ns[2],finish=ns[3],mode='flight',distance=11000}}}
    local candidates={};for i=1,12 do candidates[#candidates+1]=pos(-1000-i,0,'direct'..i);candidates[#candidates+1]=pos(20000+i,0,'unoffered'..i) end
    candidates[#candidates+1]=pos(10200,0,'good')
    local c=M.Copy(ctx);c.routeOrder='time';c.taxiFrom=1;c.timings={['71']={10},['72']={10}}
    local selected=R.Candidates(pos(0),candidates,data,c,12);local plans=R.Plan(pos(0),selected,data,c)
    assert(plans[1].destination.id=='good')
end)

test('quality and ETA remain separate; immutable input',function()
    local e=edge(8,3,4,1000);local r=R.Summary({e},pos(1100),{timings={['8']={50}},speed=7,flightPrior=20})
    assert(r.eta==50 and r.legs[1].seconds==50 and e.seconds==nil)
    local s=V.New();s.route=r;s.leg=1;s.measure={at=10};local _,eta=V.Remaining(s,pos(0),7,20);assert(eta==40)
end)
local walk={id='w',from='origin',to='goal',start=pos(0),finish=pos(100,0,'goal'),distance=100,mode='walk',quality='bearing'}
local route=R.Summary({walk},walk.finish,ctx)
test('arrival dwell floor and cancellation reset',function()
    local s=V.New();assert(V.Start(s,route,pos(0),0));V.Update(s,pos(100),1,false,false);assert(s.state=='walking');V.Update(s,pos(100),3,false,false);assert(s.state=='arrived')
    V.Stop(s);assert(not s.previous and not s.route);assert(V.Start(s,route,pos(0),4));local p=pos(100);p.uiMapID=2;V.Update(s,p,7,false,false);assert(s.state~='arrived')
end)
test('hypothetical Go never starts at fictional origin',function() local s=V.New();assert(not V.Start(s,route,pos(500),0));assert(s.message) end)
test('pause death teleport wrong flight transitions',function()
    local s=V.New();V.Start(s,route,pos(0),0);V.Update(s,nil,1,false,false);assert(s.state=='paused');V.Update(s,pos(0),2,false,true);assert(s.state=='paused')
    V.Update(s,pos(0),3,false,false);V.Update(s,pos(400),3.5,false,false);assert(s.state=='unavailable')
    V.Start(s,route,pos(0),4);V.Update(s,pos(0),5,true,false);assert(s.state=='unavailable')
end)
test('flight confirmed boarding landing and invalidated timing',function()
    local flight=edge(9,3,4,1000);local r=R.Summary({flight},nodes[4],ctx);local s=V.New();V.Start(s,r,nodes[3],0)
    V.Update(s,nodes[3],1,false,false);assert(s.state=='awaiting_flight')
    V.Update(s,nodes[3],2,true,false,{from=3,to=4});assert(s.state=='flying' and s.measure)
    V.Update(s,nil,3,true,false,{from=3,to=4});assert(not s.measure)
    V.Update(s,nodes[3],4,true,false,{from=3,to=4});assert(s.state=='flying' and not s.measure)
    assert(not V.Update(s,nodes[4],30,false,false));assert(s.state=='walking')
    V.Start(s,r,nodes[3],0);V.Update(s,nodes[3],2,true,false,{from=3,to=4});local sample=V.Update(s,nodes[4],32,false,false);assert(sample.seconds==30)
    V.Start(s,r,nodes[3],0);V.Update(s,nil,2,true,false,{from=3,to=4});assert(not V.Update(s,nodes[4],32,false,false,{from=3,to=4}));assert(s.leg==2)
    V.Start(s,r,nodes[3],0);assert(V.Target(s)==s.route.legs[1].start);V.Update(s,nodes[3],2,true,false,{from=3,to=4});assert(V.Target(s)==s.route.legs[1].finish)
end)
print('PASS model scenarios: '..count)
