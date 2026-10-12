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
test('sixteen point compass uses world north across quadrants and sector boundaries',function()
    local origin=pos(700,-300)
    local function target(degrees)
        local angle=degrees*math.pi/180
        return pos(origin.x+100*math.cos(angle),origin.y-100*math.sin(angle))
    end
    local labels={'N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW'}
    for i,label in ipairs(labels) do
        local center=(i-1)*22.5
        assert(M.Cardinal(origin,target(center))==label)
        assert(M.Cardinal(origin,target(center+11.25-.00001))==label)
        assert(M.Cardinal(origin,target(center+11.25+.00001))==labels[i%16+1])
    end
    local east,north=M.Vector(origin,target(90),math.pi/2)
    assert(math.abs(east)<1e-6 and north<0 and M.Cardinal(origin,target(90))=='E')
end)

test('compass omits coincident unavailable and other-continent positions',function()
    assert(not M.Cardinal(pos(0),pos(0)))
    assert(not M.Cardinal(nil,pos(100)) and not M.Cardinal(pos(0),nil))
    assert(not M.Cardinal(pos(0),pos(0/0)))
    local other=pos(100);other.map=1;assert(not M.Cardinal(pos(0),other))
    local differentFloor=pos(100);differentFloor.uiMapID=2
    assert(M.Cardinal(pos(0),differentFloor)=='N')
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

test('role composition prefixes and typos outrank incidental names',function()
    local items={
        {id='incidental',name='Warrior Trainer Fan',category='quest',x=1,y=0,map=0},
        {id='far',name='Wu Shen',category='class',class='WARRIOR',x=200,y=0,map=0},
        {id='near',name='Lyria Du Lac',category='class',class='WARRIOR',x=100,y=0,map=0},
        {id='mage',name='Maginor',category='class',class='MAGE',x=2,y=0,map=0},
        {id='smith',name='Hank the Hammer',category='profession',profession='Blacksmithing',x=50,y=0,map=0},
        {id='name-smith',name='Blacksmith Advocate',category='quest',x=1,y=0,map=0},
    }
    for _,query in ipairs({'Warrior Trainer','trainer warrior','warrior trianer'}) do
        local found,rank=M.Search(items,query,{},ctx,nil,pos(0));assert(found[1].id=='near' and found[2].id=='far' and rank[found[1]]<rank[items[1]])
    end
    for _,query in ipairs({'Blacks...','Blacksmthing'}) do local found=M.Search(items,query,{},ctx,nil,pos(0));assert(found[1].id=='smith') end
    assert(M.Search(items,'mgae trainer',{},ctx,nil,pos(0))[1].id=='mage')
    local found=M.Search(items,'Warrior Trainer',{category='class'},{class='MAGE'},nil,pos(0));assert(#found==2 and found[1].id=='near')
    assert(not items[1].relevance and not items[2].score)
end)

test('exact NPC names remain useful and equivalent tiers sort by distance then identity',function()
    local items={
        {id='far',name='Aldwin Laughlin',category='quest',map=0,x=100,y=0},
        {id='near',name='Aldwin Laughlin Apprentice',category='quest',map=0,x=1,y=0},
        {id='b',name='Mage Teacher',category='class',class='MAGE',map=0,x=20,y=0},
        {id='a',name='Mage Teacher',category='class',class='MAGE',map=0,x=20,y=0},
        {id='unknown',name='Mage Teacher',category='class',class='MAGE'},
    }
    assert(M.Search(items,'ALDWIN LAUGHLIN',{},ctx,nil,pos(0))[1].id=='far')
    assert(M.Search(items,'Aldwn Laughlin',{},ctx,nil,pos(0))[1].id=='near')
    local found=M.Search(items,'mage trainer',{},ctx,nil,pos(0));assert(found[1].id=='a' and found[2].id=='b' and found[3].id=='unknown')
    assert(#M.Search(items,string.rep('x',129),{},ctx)==0 and #M.Search(items,'one two three four five six seven',{},ctx)==0)
    assert(#M.Search(items,'mage '..string.rep('x',25),{},ctx)==0)
end)

test('multi-select categories union with local class and profession restrictions',function()
    local items={
        {id='mage',name='Mage',category='class',class='MAGE'},
        {id='warrior',name='Warrior',category='class',class='WARRIOR'},
        {id='smith',name='Smith',category='profession',profession='Blacksmithing'},
        {id='cook',name='Cook',category='profession',profession='Cooking'},
        {id='auction',name='Auctioneer',category='auction'},
        {id='quest-warrior',name='Quest warrior',category='class',class='WARRIOR',categories={class=true,quest=true}},
    }
    local filter={categories={class=true,profession=true,auction=true},classes={MAGE=true},professions={Blacksmithing=true}}
    local found=M.Search(items,'',filter,ctx);local ids={};for _,p in ipairs(found) do ids[p.id]=true end
    assert(#found==3 and ids.mage and ids.smith and ids.auction and M.HasFilter(filter))
    filter.categories.quest=true;found=M.Search(items,'',filter,ctx);assert(#found==4)
    filter.categories={class=true};filter.classes={};assert(#M.Search(items,'',filter,{class='MAGE'})==3)
    filter.categories={};filter.classes={MAGE=true};assert(not M.HasFilter(filter) and #M.Search(items,'',filter,ctx)==6)
    assert(M.HasFilter({category='class'}) and not M.HasFilter({category='all'}) and not M.HasFilter(nil))
    assert(#M.Search(items,'',{category='auction',class='MAGE',profession='Cooking'},ctx)==1)
end)
test('speed fallbacks reject invalid and taxi samples',function()
    assert(M.Speed(0,7)==7);assert(M.Speed(nil,nil)==7);assert(M.Speed(100,7)==7);assert(M.Speed(50,7,8,true)==8);assert(M.Speed(10,7,10)==10)
end)

test('ground allowance is bounded to bearings with zero and invalid input handling',function()
    assert(M.GroundSeconds(0,7,'bearing')==0)
    assert(M.GroundSeconds(700,7,'bearing')==135 and M.GroundSeconds(700,7,'verified')==100)
    assert(M.GroundSeconds(700,14,'bearing')==67.5 and math.abs(M.GroundSeconds(700,50,'bearing')-18.9)<1e-9)
    for _,speed in ipairs({0,-1,51,math.huge,0/0}) do assert(M.GroundSeconds(700,speed,'bearing')==135) end
    assert(M.GroundSeconds(700,nil,'bearing')==135)
    assert(not M.GroundSeconds(-1,7,'bearing') and not M.GroundSeconds(0/0,7,'bearing') and not M.GroundSeconds(math.huge,7,'bearing'))
end)
test('saved settings sanitize preserve and isolate builds',function()
    local p=S.Load({scale=999,font='Expressway',width=299,locked=true});assert(p.scale==1.6 and p.width==299 and p.locked)
    local _,readOnly=S.Load({version=99});assert(readOnly)
    assert(not next(S.Character({version=1,build='old',known={[2]={state='known'}}},'new').known))
    local c=S.Character({version=1,build='a',known={[2]={state='known'}},offers={x=1},timings={x={20,0/0,-4,30}}},'a');assert(c.known[2] and #c.timings.x==2 and not next(c.offers))
end)

test('build migration retains quarantined places without carrying taxi knowledge',function()
    local place=pos(100,0,'saved-home');place.name='Saved home';place.category='place'
    local old={version=1,build='old',known={[1]={state='known'}},timings={['1']={60}},places={place}}
    local migrated=S.Character(old,'new')
    assert(not next(migrated.known) and not next(migrated.timings) and #migrated.places==1)
    assert(migrated.places[1].stale and migrated.places[1].available==false and migrated.places[1].observedBuild=='old')
    assert(#M.Search(migrated.places,'home',nil,ctx)==0)
    local reloaded=S.Character(migrated,'new')
    assert(#reloaded.places==1 and reloaded.places[1].stale and reloaded.places[1].available==false and reloaded.places[1].observedBuild=='old')
    assert(not old.places[1].stale and old.known[1] and old.timings['1'][1]==60)
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
test('observed undiscovered alternative unlocks after discovery in either order',function()
    local data={nodes=nodes,edges={edge(91,1,2,100)}}
    for _,order in ipairs({'distance','time'}) do
        local c=M.Copy(ctx);c.requireObserved=true;c.routeOrder=order;c.known[2].state='undiscovered'
        local plans=R.Plan(pos(0),{pos(1100,0,'goal')},data,c)
        assert(#plans==2 and plans[1].flight==0 and plans[2].unavailable=='undiscovered')
        assert(plans[2].flight==100 and plans[2].eta<plans[1].eta)
        c.known[2].state='known';plans=R.Plan(pos(0),{pos(1100,0,'goal')},data,c)
        assert(#plans==2 and plans[1].flight==100 and not plans[1].unavailable and not plans[2].unavailable)
    end
end)

test('unknown flight nodes never become undiscovered previews',function()
    local data={nodes=nodes,edges={edge(92,1,2,100)}}
    for _,requireObserved in ipairs({true,false}) do
        local c=M.Copy(ctx);c.requireObserved=requireObserved;c.known[2]=nil
        local plans=R.Plan(pos(0),{pos(1100,0,'goal')},data,c);assert(#plans==1 and not plans[1].unavailable)
        c.known[2]={state='unknown'};plans=R.Plan(pos(0),{pos(1100,0,'goal')},data,c);assert(#plans==1 and not plans[1].unavailable)
        c.known[2].state='undiscovered';c.known[1]=nil
        plans=R.Plan(pos(0),{pos(1100,0,'goal')},data,c);assert(#plans==1 and not plans[1].unavailable)
    end
end)

test('disabled alternatives cannot crowd three usable routes',function()
    local c=M.Copy(ctx);c.known[2].state='undiscovered'
    local data={nodes=nodes,edges={edge(93,1,2,10),edge(94,3,4,1000),edge(95,1,4,1400)}}
    for _,order in ipairs({'distance','time'}) do
        c.routeOrder=order;local plans=R.Plan(pos(0),{pos(1100,0,'goal')},data,c)
        assert(#plans==3);for _,r in ipairs(plans) do assert(not r.unavailable) end
    end
end)

test('offered whole flight ignores undiscovered flythrough and authoritative gates remain',function()
    local c=M.Copy(ctx);c.requireObserved=true;c.taxiFrom=1;c.known[3].state='undiscovered'
    local a,b=edge(96,1,3,50),edge(97,3,4,100)
    local whole=edge('offered:96,97',1,4,150);whole.timingKey='96,97';whole.offered=true;whole.intermediate={3}
    local plans=R.Plan(pos(0),{pos(1100,0,'goal')},{nodes=nodes,edges={a,b,whole}},c)
    local found=false;for _,r in ipairs(plans) do if r.signature=='goal/96/97' then assert(not r.unavailable and not r.conditional);found=true end end;assert(found)
    c.known[4].state='undiscovered';assert(not R.Summary({whole},pos(1100,0,'goal'),c).unavailable)
    assert(not R.Shortest(nodes,{a,b},1,4,c,nil,true,true,'distance',true))
    local offered=edge('offered:96',1,3,50);offered.offered=true
    assert(not R.Shortest(nodes,{offered,b},1,4,c,nil,true,true,'distance',true))
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
    assert(math.abs(plans[1].eta-(30+190/7*1.35))<1e-6)
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
    local c=M.Copy(ctx);c.routeOrder='time';c.timings={['71']={80}}
    local selected=R.Candidates(pos(0),candidates,data,c,12);local found=false
    for _,p in ipairs(selected) do if p.id=='far-trainer' then found=true end end;assert(found and #selected<=24)
    local plans=R.Plan(pos(0),selected,data,c);assert(plans[1].destination.id=='far-trainer' and plans[1].flight>0 and plans[1].eta==80)
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

test('bearing ETA stays consistent across cost summary display and remaining travel',function()
    local before={mode='walk',distance=350,quality='bearing',start=pos(0),finish=pos(350)}
    local flight={id=801,mode='flight',distance=1000,from=1,to=2,start=pos(350,0,'Departure'),finish=pos(1350,0,'Arrival'),offered=true}
    flight.start.name='Departure';flight.finish.name='Arrival'
    local after={mode='walk',distance=350,quality='bearing',start=flight.finish,finish=pos(1700,0,'goal')}
    local c=M.Copy(ctx);c.timings={['801']={90}}
    local route=N.Routes.Summary({before,flight,after},after.finish,c)
    assert(route.distance==1700 and route.walk==700 and route.flight==1000 and route.eta==225 and route.groundAllowance)
    assert(N.Routes.Seconds(before,c)==67.5 and route.legs[1].seconds==67.5 and route.legs[2].seconds==90)
    assert(M.RouteLegs(route,7)=='Walk ~1 min\nFly ~2 min: Departure to Arrival\nWalk ~1 min')
    local state=V.New();assert(V.Start(state,route,pos(0),0))
    local distance,eta=V.Remaining(state,pos(0),7,0);assert(distance==1700 and eta==route.eta)
    distance,eta=V.Remaining(state,pos(175),7,10);assert(distance==1525 and eta==191.25)
    _,eta=V.Remaining(state,pos(0),14,10);assert(eta==157.5)
    assert(not before.seconds and not flight.seconds)
end)

test('route cards retain planned ground timing while remaining guidance uses live speed',function()
    local origin,goal=pos(0),pos(700,0,'goal')
    local leg={mode='walk',distance=700,quality='bearing',start=origin,finish=goal}
    local route=R.Summary({leg},goal,ctx)
    assert(route.eta==135 and M.RouteMode(route)=='Walk' and M.RouteLegs(route,14)=='Walk ~2 min')
    local state=V.New();assert(V.Start(state,route,origin,0))
    local _,seconds=V.Remaining(state,origin,14,0);assert(seconds==67.5)
    assert(M.RouteLegs({legs={leg}},14)=='Walk ~1 min' and not leg.seconds)
end)

test('flight summaries label every estimate and preserve full endpoint names and stored times',function()
    local departure='Thelsamar, Loch Modan';local arrival='Ironforge, Dun Morogh'
    local legs={
        {mode='walk',distance=700,quality='bearing',seconds=40},
        {mode='flight',distance=10000,seconds=30,start={name=departure},finish={name='Intermediate master'}},
        {mode='flight',distance=10000,seconds=60,start={name='Intermediate master'},finish={name=arrival}},
        {mode='walk',distance=700,quality='bearing',seconds=20},
    }
    local route={legs=legs}
    assert(M.RouteMode(route)=='Walk + fly')
    local text=M.RouteLegs(route,14)
    assert(text=='Walk ~<1 min\nFly ~2 min: '..departure..' to '..arrival..'\nWalk ~<1 min')
    local lines=0
    for line in text:gmatch('[^\n]+') do
        assert(line:match('^Walk ~') or line:match('^Fly ~'));lines=lines+1
    end
    assert(lines==3 and legs[1].seconds==40 and legs[3].seconds==60 and legs[4].seconds==20)
end)

test('route metadata remains isolated while immutable flight geometry is shared',function()
    local e=edge(802,1,2,1100);e.points={{10,0},{1000,0}};e.geometry={{map=0,points=e.points}}
    local route=R.Summary({e},nodes[2],ctx)
    assert(route.legs[1].points==e.points and route.legs[1].geometry==e.geometry)
    route.legs[1].start.name='Changed';route.legs[1].offered=true
    assert(nodes[1].name~='Changed' and not e.offered and not e.seconds and e.points[2][1]==1000)
end)

test('category cost scan excludes invalid cross-map and hostile exits',function()
    local candidates={};for i=1,13 do candidates[i]=pos(500+i,0,'near'..i) end
    local far=pos(2000,0,'far');candidates[#candidates+1]=far
    local ns={[1]=pos(0,0,1),[2]=pos(2000,0,2),[3]=pos(2000,0,3),[4]=pos(2000,0,4)}
    ns[2].faction='Horde';ns[3].map=99;ns[4].x=0/0
    local data={nodes=ns,edges={}}
    for i=2,4 do data.edges[#data.edges+1]={id=810+i,from=1,to=i,distance=10,mode='flight'} end
    local c=M.Copy(ctx);c.routeOrder='time';local selected=R.Candidates(pos(0),candidates,data,c,12)
    for _,p in ipairs(selected) do assert(p.id~='far') end
end)
local walk={id='w',from='origin',to='goal',start=pos(0),finish=pos(100,0,'goal'),distance=100,mode='walk',quality='bearing'}
local route=R.Summary({walk},walk.finish,ctx)
test('arrival dwell floor and cancellation reset',function()
    local s=V.New();assert(V.Start(s,route,pos(0),0));V.Update(s,pos(100),1,false,false);assert(s.state=='walking');V.Update(s,pos(100),3,false,false);assert(s.state=='arrived')
    V.Stop(s);assert(not s.previous and not s.route);assert(V.Start(s,route,pos(0),4));local p=pos(100);p.uiMapID=2;V.Update(s,p,7,false,false);assert(s.state~='arrived')
end)

test('leaving NPC proximity clears nearby state and its obsolete message',function()
    local imported=M.Copy(route);imported.destination.confidence='provider'
    local state=V.New();assert(V.Start(state,imported,pos(0),0))
    V.Update(state,pos(100),1,false,false);V.Update(state,pos(100),3,false,false)
    assert(state.state=='nearby' and state.message:find('Nearby'))
    V.Update(state,pos(130),4,false,false);assert(state.state=='walking' and not state.message and not state.dwell)
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
    V.Update(s,nodes[3],4,true,false,{from=3,to=4});assert(s.state=='flying' and s.message=='In flight' and not s.measure)
    assert(not V.Update(s,nodes[4],30,false,false));assert(s.state=='walking')
    V.Start(s,r,nodes[3],0);V.Update(s,nodes[3],2,true,false,{from=3,to=4});local sample=V.Update(s,nodes[4],32,false,false);assert(sample.seconds==30)
    V.Start(s,r,nodes[3],0);V.Update(s,nil,2,true,false,{from=3,to=4});assert(not V.Update(s,nodes[4],32,false,false,{from=3,to=4}));assert(s.leg==2)
    V.Start(s,r,nodes[3],0);assert(V.Target(s)==s.route.legs[1].start);V.Update(s,nodes[3],2,true,false,{from=3,to=4});assert(V.Target(s)==s.route.legs[1].finish)
end)
test('profile migration sanitizes legacy and isolates appearance',function()
    local legacy={version=1,scale=1.2,font='Expressway',routeOrder='time',colors={accent={.1,.2,.3}},known={[1]=true},timings={a={20}}}
    local store,readOnly=S.Profiles(nil,legacy)
    assert(not readOnly and store.active=='Default' and store.version==1)
    local p=store.profiles.Default;assert(p.scale==1.2 and p.routeOrder=='time' and p.colors.accent[2]==.2)
    assert(not p.known and not p.timings and not store.known)
    p.colors.accent[1]=.8;assert(legacy.colors.accent[1]==.1 and S.defaults.colors.accent[1]~=.8)
    local restored=S.Profiles(store,{scale=.7});assert(restored.profiles.Default.scale==1.2 and restored.profiles.Default.colors.accent[1]==.8)
    assert(not next(p.searchFilters.categories))
    legacy.searchFilters={categories={class=true,quest=false,bad=true},classes={WARRIOR=true,MAGE=1,bad=true},professions={Blacksmithing=true,bad=true}}
    local filtered=S.Profiles(nil,legacy);local q=filtered.profiles.Default.searchFilters
    assert(q.categories.class and not q.categories.quest and not q.categories.bad and q.classes.WARRIOR and not q.classes.MAGE and not q.classes.bad)
    assert(q.professions.Blacksmithing and not q.professions.bad)
    q.classes.WARRIOR=nil;assert(legacy.searchFilters.classes.WARRIOR and not next(S.defaults.searchFilters.classes))
    local duplicate=S.DuplicateProfile(filtered,'Filtered');duplicate.searchFilters.categories.class=nil
    assert(filtered.profiles.Default.searchFilters.categories.class)
end)

test('nested colors and nonfinite settings are sanitized independently',function()
    local input={width=0/0,scale=math.huge,font='',colors={background={-1,2,0/0,4},accent='bad',text={math.huge,.4,.5},extra={1,1,1}}}
    local p=S.Load(input)
    assert(p.width==S.defaults.width and p.scale==S.defaults.scale and p.font=='Expressway')
    assert(p.colors.background[1]==0 and p.colors.background[2]==1 and p.colors.background[3]==S.defaults.colors.background[3])
    assert(not p.colors.background[4] and not p.colors.extra and p.colors.accent[1]==S.defaults.colors.accent[1])
    assert(p.colors.text[1]==S.defaults.colors.text[1] and p.colors.text[2]==.4)
    p.colors.text[2]=.8;assert(input.colors.text[2]==.4)
end)

test('narrow panel default migrates once without changing custom widths',function()
    local defaults=S.Load(nil)
    assert(defaults.width==240 and defaults.layoutVersion==2 and S.minWidth==220 and S.maxWidth==640)
    local legacy={version=1,width=304};local migrated=S.Load(legacy)
    assert(migrated.width==240 and migrated.layoutVersion==2 and legacy.width==304 and legacy.layoutVersion==nil)
    assert(S.Load({width=304,layoutVersion=1}).width==240 and S.Load({width=304,layoutVersion=0/0}).width==240)
    for _,width in ipairs({220,280,299,305,640}) do
        local p=S.Load({width=width});assert(p.width==width and p.layoutVersion==2)
    end
    migrated.width=304;assert(S.Load(migrated).width==304)
    assert(S.Load({width=304,layoutVersion=2}).width==304)
    assert(S.Load({width=-1}).width==S.minWidth and S.Load({width=999}).width==S.maxWidth)
end)

test('dock position and frame layer sanitize malformed saved preferences',function()
    local p=S.Load(nil);assert(p.dockPosition==.5 and p.strata=='HIGH')
    for _,value in ipairs({0,.1,.5,.9,1}) do assert(S.Load({dockPosition=value}).dockPosition==value) end
    assert(S.Load({dockPosition=-.4}).dockPosition==0 and S.Load({dockPosition=1.4}).dockPosition==1)
    for _,value in ipairs({0/0,math.huge,-math.huge,'0.25',false,{}}) do
        assert(S.Load({dockPosition=value}).dockPosition==.5)
    end
    for _,value in ipairs({'LOW','MEDIUM','HIGH'}) do assert(S.Load({strata=value}).strata==value) end
    for _,value in ipairs({'BACKGROUND','DIALOG','TOOLTIP','low','',3,false,{}}) do assert(S.Load({strata=value}).strata=='HIGH') end
end)

test('layout migration and dock preferences remain isolated across profile operations',function()
    local source={version=1,active='Custom',profiles={Default={width=304},Custom={width=420,dock='right',dockPosition=.2,strata='LOW'}}}
    local store=S.Profiles(source)
    assert(store.profiles.Default.width==240 and store.profiles.Custom.width==420)
    assert(source.profiles.Default.width==304 and source.profiles.Default.layoutVersion==nil)
    local duplicate=S.DuplicateProfile(store,'Other')
    assert(duplicate.dock=='right' and duplicate.dockPosition==.2 and duplicate.strata=='LOW')
    duplicate.width=304;duplicate.dockPosition=.8;duplicate.strata='MEDIUM'
    local custom=S.SwitchProfile(store,'Custom');assert(custom.dockPosition==.2 and custom.strata=='LOW' and custom.width==420)
    local copied=S.CopyProfile(store,'Other');assert(copied.width==304 and copied.dockPosition==.8 and copied.strata=='MEDIUM')
    local reloaded=S.Profiles(store);assert(reloaded.profiles.Custom.width==304 and reloaded.profiles.Custom.dockPosition==.8)
    local reset=S.ResetProfile(reloaded);assert(reset.width==240 and reset.layoutVersion==2 and reset.dockPosition==.5 and reset.strata=='HIGH')
    assert(reloaded.profiles.Other.width==304 and reloaded.profiles.Other.dockPosition==.8 and reloaded.profiles.Other.strata=='MEDIUM')
end)

test('profile switch copy duplicate reset preserve names and independent values',function()
    local store=S.Profiles(nil,{scale=1.1});local original=store.profiles.Default
    local night=S.DuplicateProfile(store,' Night ');assert(night and store.active=='Night' and night~=original)
    night.colors.background[1]=.3;night.scale=.8
    assert(S.SwitchProfile(store,'Default').scale==1.1 and original.colors.background[1]~=.3)
    local copied=S.CopyProfile(store,'Night');assert(store.active=='Default' and copied.scale==.8 and copied~=night)
    copied.colors.background[1]=.6;assert(night.colors.background[1]==.3)
    local reset=S.ResetProfile(store);assert(store.active=='Default' and reset.scale==S.defaults.scale and reset.colors.background[1]==S.defaults.colors.background[1])
    reset.colors.background[1]=.7;assert(S.defaults.colors.background[1]~=.7)
    assert(not S.SwitchProfile(store,'missing') and not S.CopyProfile(store,'missing'))
end)

test('profile names and stored profile count remain bounded',function()
    local store=S.Profiles(nil,{})
    for _,name in ipairs({'','  ','bad|name','bad\nname',string.rep('a',49),'Default'}) do assert(not S.DuplicateProfile(store,name)) end
    for i=1,31 do assert(S.DuplicateProfile(store,'Profile'..i)) end
    assert(not S.DuplicateProfile(store,'Overflow'))
    local source={version=1,active='Z active',profiles={Default={scale=1.1},['Z active']={scale=.9,known={x=true}},['bad|name']={}}}
    for i=1,40 do source.profiles['A'..i]={} end
    local loaded=S.Profiles(source,{});local n=0;for _ in pairs(loaded.profiles) do n=n+1 end
    assert(n==32 and loaded.active=='Z active' and loaded.profiles['Z active'].scale==.9 and not loaded.profiles['Z active'].known)
    assert(not loaded.profiles['bad|name'])
end)

test('future settings and profile stores are protected from mutation',function()
    local future={version=2,active='Future',profiles={Future={scale=.8}},unknown='keep'}
    local store,readOnly=S.Profiles(future,{scale=1.1});assert(readOnly and store.readOnly and future.unknown=='keep' and future.active=='Future')
    assert(not S.SwitchProfile(store,'Default') and not S.DuplicateProfile(store,'New') and not S.CopyProfile(store,'Default') and not S.ResetProfile(store))
    local nested={version=1,active='Default',profiles={Default={version=2,unknown='keep'}}}
    local _,nestedReadOnly=S.Profiles(nested,{});assert(nestedReadOnly and nested.profiles.Default.unknown=='keep')
    local _,legacyReadOnly=S.Profiles(nil,{version=2});assert(legacyReadOnly)
    local futureProfile={version=2,width=304,layoutVersion=1,dockPosition=.8,strata='TOOLTIP',colors={accent={0,0,0}}}
    local p,pReadOnly=S.Load(futureProfile);assert(pReadOnly and p.colors.accent[1]==S.defaults.colors.accent[1])
    assert(p.width==240 and p.dockPosition==.5 and p.strata=='HIGH')
    assert(futureProfile.width==304 and futureProfile.layoutVersion==1 and futureProfile.dockPosition==.8 and futureProfile.strata=='TOOLTIP')
    p.colors.accent[1]=0;assert(S.defaults.colors.accent[1]~=0)
end)
test('transmogrifier selection persists through profile reload copy and All reset',function()
    local filters={categories={transmog=true,class=true,invalid=true},classes={MAGE=true},professions={}}
    local profile=S.Load({searchFilters=filters});assert(profile.searchFilters.categories.transmog and not profile.searchFilters.categories.invalid)
    local store=S.Profiles(nil,profile);assert(S.DuplicateProfile(store,'Transmog').searchFilters.categories.transmog)
    S.SwitchProfile(store,'Default').searchFilters=S.Filters({})
    local reloaded=S.Profiles(store);assert(not M.HasFilter(reloaded.profiles.Default.searchFilters))
    assert(S.SwitchProfile(reloaded,'Transmog').searchFilters.categories.transmog)
    local copied=S.CopyProfile(reloaded,'Default');assert(not M.HasFilter(copied.searchFilters))
    assert(filters.categories.transmog and store.profiles.Transmog.searchFilters.categories.transmog)
end)

test('transmog aliases retain semantic priority exact names and faction eligibility',function()
    local service={id='service',name='Fyrenz Vishonar',category='transmog',faction='Alliance',map=0,x=1000,y=0}
    local incidental={id='incidental',name='Transmog Collector',category='quest',map=0,x=1,y=0}
    local horde={id='horde',name="Mon'ye",category='transmog',faction='Horde',map=0,x=2,y=0}
    local unknown={id='unknown',name='Unknown service',category='transmog',available=false,map=0,x=0,y=0}
    local items={incidental,horde,unknown,service};local ctx={faction='Alliance'};local origin={map=0,x=0,y=0}
    for _,query in ipairs({'transmog','transmogrifier','transmogrifiers','transmogrification','TRANSMOG','transmogrifer'}) do
        local matches=M.Search(items,query,{},ctx,nil,origin);assert(matches[1]==service,query)
    end
    assert(M.Search(items,'Fyrenz Vishonar',{},ctx)[1]==service)
    assert(M.Search(items,'vishonar',{},ctx)[1]==service)
    assert(M.Search(items,'Transmog Collector',{},ctx)[1]==incidental)
    assert(M.Search(items,"Mon'ye",{},{faction='Horde'})[1]==horde)
    assert(#M.Search(items,'',{categories={transmog=true},classes={MAGE=true}},ctx)==1)
    assert(#M.Search(items,'',{categories={transmog=true,quest=true},classes={MAGE=true}},ctx)==2)
    assert(#M.Search(items,'',{categories={},classes={MAGE=true},professions={Alchemy=true}},ctx)==2)
end)
print('PASS model scenarios: '..count)
