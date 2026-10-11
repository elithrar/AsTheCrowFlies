local frames,timers,hooks={},{},{};local now=0
local methods={}
function methods:SetPoint(...) local args={...};self.point=args;if #args==5 then assert(type(args[4])=='number' and type(args[5])=='number','SetPoint requires numeric offsets') end end
function methods:ClearAllPoints() self.point=nil end
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:SetWidth(w) self.w=w end
function methods:SetHeight(h) self.h=h end
function methods:SetResizable(value) self.resizable=value end
function methods:SetResizeBounds(a,b,c,d) assert(a>0 and b>0 and c>=a and d>=b,'native resize bounds must be positive and ordered');self.resizeBounds={a,b,c,d} end
function methods:StartSizing(point) self.sizing=point end
function methods:GetWidth() return self.w or 304 end
function methods:GetHeight() return self.h or 28 end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:HookScript(event,fn) local previous=self.scripts[event];self.scripts[event]=function(...) if previous then previous(...) end;fn(...) end end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:Show() local changed=self.shown==false;self.shown=true;if changed and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() local changed=self.shown~=false;self.shown=false;if changed and self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown~=false end
function methods:SetText(v) self.text=v end
function methods:SetTextColor(...) self.textColor={...} end
function methods:GetText() return self.text or '' end
function methods:SetFont(path,size,flags)
    if path=='missing' then return false end
    self.font=path;self.fontSize=size;self.fontFlags=flags or '';return true
end
function methods:GetFont() return self.font or 'native',self.fontSize or 12,self.fontFlags or '' end
function methods:SetFontObject(v)
    self.fontObject=v
    if type(v)=='table' and v.GetFont then self.font,self.fontSize,self.fontFlags=v:GetFont()
    else self.font='native';self.fontSize=12;self.fontFlags='' end
end
function methods:SetScale(v) self.scale=v end
function methods:GetScale() return self.scale or 1 end
function methods:GetEffectiveScale() return self:GetScale()*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(v) self.level=v end
function methods:SetTexCoord(...) self.coords={...} end
function methods:SetEnabled(v) self.enabled=v end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:SetBackdropColor(...) self.backdropColor={...} end
function methods:SetBackdropBorderColor(...) self.borderColor={...} end
function methods:GenerateMenu() self.generated=(self.generated or 0)+1 end
function methods:RegisterCallback(event,callback,owner) self.callbacks=self.callbacks or {};self.callbacks[event]={callback,owner} end
function methods:TriggerEvent(event,...) local entry=self.callbacks and self.callbacks[event];if entry then entry[1](entry[2],...) end end
function methods:CloseMenu() self.menuClosed=true;self.menuOpen=false;self:TriggerEvent('OnMenuClose') end
function methods:IsMenuOpen() return self.menuOpen==true end
function methods:GetUnboundedStringWidth()
    local longest=0;for line in ((self.text or '')..'\n'):gmatch('(.-)\n') do longest=math.max(longest,#line) end
    return longest*(self.fontSize or 12)*.55
end
function methods:GetStringHeight()
    local size=self.fontSize or 12;local lines=0
    for line in ((self.text or '')..'\n'):gmatch('(.-)\n') do
        lines=lines+(self.wordWrap and math.max(1,math.ceil(#line*size*.55/math.max(1,self.w or 100))) or 1)
    end
    local height=lines*size;return self.h and self.h>0 and math.min(height,self.h) or height
end
function methods:SetWordWrap(value) self.wordWrap=value end
function methods:SetNonSpaceWrap(value) self.nonSpaceWrap=value end
function methods:SetJustifyH(value) self.justifyH=value end
function methods:SetJustifyV(value) self.justifyV=value end
function methods:SetMinMaxValues(a,b) self.minimum=a;self.maximum=b end
function methods:SetValue(value) self.value=value;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end end
function methods:SetValueStep(value) self.valueStep=value end
function methods:SetObeyStepOnDrag(value) self.obeyStep=value end
function methods:SetOrientation(value) self.orientation=value end
function methods:SetHitRectInsets(...) self.hitInsets={...} end
function methods:SetScrollChild(child) self.scrollChild=child end
function methods:SetVerticalScroll(value) self.scroll=value;if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self,value) end end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetLeft() return 20 end
function methods:GetTop() return 600 end
function methods:SetTexture(v) self.texture=v;self.atlas=nil;return true end
function methods:SetAtlas(v,useSize,filter,reset,wrapH,wrapV)
    assert(useSize==false and reset==true and wrapH=='CLAMP' and wrapV=='CLAMP')
    self.atlas=v;self.texture='atlas sheet';self.coords={.1,.2,.3,.4}
    -- The native API returns nothing on success.
end
function methods:GetAtlas() return self.atlas end
function methods:SetDesaturated(v) self.desaturated=v end
function methods:SetSnapToPixelGrid(v) self.snap=v end
function methods:SetTexelSnappingBias(v) self.snapBias=v end
function methods:SetPushedTexture(v) self.pushedTexture=v end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetRotation(v) self.rotation=v end
function methods:SetDefaultText(v) self.label=v end
function methods:SetupMenu(fn) self.menu=fn end
function methods:HasFocus() return self.focus==true end
function methods:ClearFocus() self.focus=false end
function methods:SetFocus() self.focus=true end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
local noop={'SetAllPoints','SetShadowColor','SetShadowOffset','SetAutoFocus','SetMaxLetters','SetTextInsets','HighlightText','SetMovable','EnableMouse','SetClampedToScreen','SetFrameStrata','RegisterForDrag','StartMoving','StopMovingOrSizing','EnableMouseWheel','SetOwner','SetDrawLayer'}
for _,name in ipairs(noop) do methods[name]=function() end end
local function object(name)
    local f=setmetatable({scripts={},events={},name=name},{__index=methods});frames[#frames+1]=f;if name then _G[name]=f end;return f
end
function methods:CreateTexture() local texture=object();texture.parent=self;return texture end
function methods:CreateLine() return object() end
function methods:SetStartPoint(...) self.startPoint={...} end
function methods:SetEndPoint(...) self.endPoint={...} end
function methods:SetThickness(v) self.thickness=v end
function methods:SetColorTexture(...) self.color={...} end
function methods:CreateFontString() local text=object();text.parent=self;return text end
function CreateFont(name) return object(name) end
function CreateFrame(kind,name,parent,template)
    local f=object(name);f.parent=parent;f.kind=kind;f.template=template
    if kind=='DropdownButton' or template=='UICheckButtonTemplate' then f.Text=object();f.Text.parent=f end;return f
end
UIParent=object();UIParent:SetSize(1920,1080);Minimap=object();Minimap:SetSize(180,180)
WorldMapFrame=object();local canvas=object();canvas:SetSize(1000,700)
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetMapID() return 1429 end
GameTooltip=object();GameFontNormal={};STANDARD_TEXT_FONT='native';SlashCmdList={}
C_Timer={After=function(delay,fn) timers[#timers+1]=fn end,NewTicker=function(delay,fn) return {Cancel=function() end,callback=fn} end}
function GetTime() return now end
function GetBuildInfo() return '1.60.1','70338' end
function GetZoneText() return 'Test zone' end
function UnitClass() return 'Mage','MAGE' end
function UnitFactionGroup() return 'Alliance' end
local onTaxi,dead=false,false
function UnitOnTaxi() return onTaxi end
function UnitIsDeadOrGhost() return dead end
function GetUnitSpeed() return 0,7 end
function GetPlayerFacing() return 0 end
function GetCVarBool() return false end
function GetMinimapShape() return 'ROUND' end
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
local playerX,playerY=.5,.5
C_Map={GetBestMapForUnit=function() return 1429 end,GetPlayerMapPosition=function() return CreateVector2D(playerX,playerY) end,
    GetWorldPosFromMapPos=function(id,v) local x,y=v:GetXY();return 0,CreateVector2D(y*2000,x*4000) end,
    GetMapPosFromWorldPos=function(continent,v,id) local x,y=v:GetXY();return id or 1429,CreateVector2D(y/4000,x/2000) end,
    GetMapInfo=function(id) return {name='Elwynn',mapID=id} end}
C_Minimap={GetViewRadius=function() return 100 end,IsRotateMinimapIgnored=function() return false end}
C_Texture={GetAtlasInfo=function(name) if name=='gamepad-hud-icon-filter' then return {width=16,height=16} end end}
C_TaxiMap={GetTaxiNodesForMap=function() return {{nodeID=1,faction=2,isUndiscovered=false},{nodeID=2,faction=2,isUndiscovered=true}} end}
function TakeTaxiNode(slot) end
function hooksecurefunc(name,fn) hooks[name]=fn end
local N={};local files={}
for line in io.lines(ROOT..'/AsTheCrowFlies/AsTheCrowFlies.toc') do if line:match('%.lua$') then files[#files+1]=line end end
for _,name in ipairs(files) do assert(loadfile(ROOT..'/AsTheCrowFlies/'..name))('AsTheCrowFlies',N) end
local A,C,U=N.Adapter,N.Core,N.UI;local count=0
local function test(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));count=count+1 end
test('TOC load and ADDON_LOADED restoration lifecycle',function()
    assert(not C.ready);AsTheCrowFliesDB={version=1,font='Arial',scale=.9};AsTheCrowFliesCharacter={version=1,build='old'}
    C.events.scripts.OnEvent(nil,'ADDON_LOADED','AnotherAddon');assert(not C.ready)
    C.events.scripts.OnEvent(nil,'ADDON_LOADED','AsTheCrowFlies');assert(C.ready and C.profile.font=='Arial' and C.profile.scale==.9)
    assert(AsTheCrowFliesDB==C.profile and AsTheCrowFliesCharacter==C.character)
end)
test('native map transform and projection round trip',function()
    local p=A.FromMap(1429,.2,.8);assert(p.x==1600 and p.y==800)
    local x,y=A.Project(p,1429);assert(x==.2 and y==.8)
    assert(not A.FromMap(1429,20,80));assert(not A.FromMap(1429,0/0,1))
end)
test('secret speed denied before arithmetic',function()
    local secret=setmetatable({},{__eq=function() error('secret comparison') end,__lt=function() error('secret comparison') end})
    issecretvalue=function(v) return rawequal(v,secret) end;GetUnitSpeed=function() return secret,7 end
    assert(A.Context().speed==7);issecretvalue=nil
end)
test('per-character discovery separate from unknown nodes',function()
    A.ObserveMap(1429,C.character,{});assert(C.character.known[1].state=='known' and C.character.known[2].state=='undiscovered' and not C.character.known[3])
end)
test('queued search canceled by Stop and superseded search',function()
    local point=A.Position();point.id='saved';point.name='Home';point.category='place';point.confidence='observed';C.destinations={point}
    C:Search('Home');C:Stop();for _,fn in ipairs(timers) do fn() end;timers={};assert(not C.matches)
    C:Search('Home');C:Search('missing');for _,fn in ipairs(timers) do fn() end;timers={};assert(#C.matches==0)
end)
test('whole destination flow input results go fold expand stop',function()
    C:Choose(C.destinations[1]);C:Plan();assert(#C.results==1);local width=U.frame:GetWidth();C:Go();assert(C.nav.route and C.compact and U.frame:GetWidth()==width)
    U.expand.scripts.OnClick();assert(not C.compact and U.frame:GetWidth()==width)
    U.fold.scripts.OnClick();assert(C.compact);C:Tick();C:Stop();assert(not C.nav.route and not C.compact and N.Overlay.destination:IsShown(),'stopped navigation keeps the chosen destination preview')
end)
test('preview origin demands fresh current-location review',function()
    C:Choose(C.destinations[1]);C.origin=N.Model.Copy(C.destinations[1]);C.origin.x=1100;C:Plan();C:Go();assert(not C.nav.route and not C.origin and C.status:find('Recalculated'))
end)
test('category button compares category rather than first autocomplete',function()
    C.destination=nil;C.query='';C.filter={categories={place=true},classes={},professions={}};C.matches={C.destinations[1]};C.results={};U.go.scripts.OnClick();assert(#C.results==1 and not C.destination and not C.matches)
    C.query='missing';C.results={};U.go.scripts.OnClick();assert(#C.results==0 and not C.destination)
end)
test('nearest class trainer defaults to player class and filters faction',function()
    local saved=C.destinations;local p=A.Position();C:Edit();C.destination=nil;C.query='';C.filter={categories={class=true},classes={MAGE=true},professions={}}
    C.destinations={}
    for i,entry in ipairs({{id='far',offset=200,class='MAGE',faction='Alliance'},{id='wrong-class',offset=1,class='WARRIOR',faction='Alliance'},{id='wrong-faction',offset=2,class='MAGE',faction='Horde'},{id='near',offset=100,class='MAGE',faction='Alliance'}}) do
        entry.x=p.x+entry.offset;entry.y=p.y;entry.map=p.map;entry.category='class';entry.name=entry.id;C.destinations[i]=entry
    end
    C:Plan();assert(#C.results==2 and C.results[1].destination.id=='near' and C.results[2].destination.id=='far')
    C.destinations=saved;C.filter={categories={},classes={},professions={}}
end)

test('minimap retains both coordinates and map pan never changes player state',function()
    C:Choose(C.destinations[1]);C.destination=N.Model.Copy(C.destination);C.destination.x=1100;C.destination.y=2100;C:Plan();C:Go();C:Tick()
    local point=N.Overlay.mini.point;assert(point and type(point[4])=='number' and type(point[5])=='number' and point[5]~=0)
    local before=A.Position();WorldMapFrame.GetMapID=function() return 1430 end;C:Tick();assert(A.Position().x==before.x)
    C.nav.state='unavailable';C.nav.message='Recalculate';GetPlayerFacing=function() return nil end;C:Tick();assert(not U.arrow:IsShown() and U.directionNote:GetText()=='Recalculate')
end)
test('origin reset restores current without replacing active navigation',function() local route=C.nav.route;U.current.scripts.OnClick();assert(C.nav.route==route and not C.origin) end)
test('provider absent or wrong flavor safe',function()
    assert(not N.Providers.Connect());LibQuestieDB={flavor={name='Era'},RequireContract=function() return true end};assert(not N.Providers.Connect())
end)
test('strict provider map parser and supported Forever API indexing',function()
    local P=N.Providers
    assert(P.MapRegistry('return { [12] = 1429, -- Elwynn\n [1]=1426 }')[12]==1429)
    assert(not P.MapRegistry('return { [1] = os.execute("no") }'))
    assert(not P.MapRegistry('return { [1]=1 }; error("no")'))
    local records={
        [1]={name='Corrected',subName='Mage Trainer',npcFlags=16,friendlyToFaction='A',spawns={[12]={{50,50}}}},
        [2]={name='Hostile',subName='Mage Trainer',npcFlags=16,spawns={[12]={{50,50}}}},
        [3]={name='No map',subName='Auctioneer',npcFlags=4096,friendlyToFaction='AH',spawns={[999]={{50,50}},[12]={{'missing',50},{50},{0/0,50},false}}},
    }
    LibQuestieDB={flavor={name='Forever'},RequireContract=function(v) return v==3 end,
        Support={Get=function(key) assert(key=='ZoneDB');return {private={areaIdToUiMapId='return { [12]=1429 }',areaIdToUiMapIdOverride='return {}'}} end},
        Npc={GetAllIds=function() return {1,2,3} end,Get=function(id,key) return records[id][key] end,GetRaw=function(id,key) return key=='subName' and 'Warrior Trainer' end}}
    local state=assert(P.Connect());assert(not P.Step(state,1));assert(state.items[1].class=='MAGE');assert(P.Step(state,5));assert(#state.items==2 and state.items[2].available==false and state.counts.unmapped==5)
    assert(#N.Model.Search(state.items,'',{category='class'},{class='MAGE',faction='Alliance'})==1)
end)
test('profession titles and class trainer default',function()
    local p=N.Providers
    for _,title in ipairs({'Master Alchemist','Blacksmithing Trainer','Blacksmith','Master Engineer','Enchanter','Fisherman','Leatherworker','Physician'}) do local category,_,_,profession=p.Classify(title,16);assert(category=='profession' and profession,title) end
    local category,_,class=p.Classify('Mage Trainer',16);assert(category=='class' and class=='MAGE')
    assert(p.Classify('Weapon Master',16)=='trainer')
end)
test('ephemeral taxi slots reconcile full directed itinerary',function()
    local data={nodes={[1]={},[3]={}},edges={{from=1,to=3,id=44,distance=200}}}
    C_TaxiMap.GetAllTaxiNodes=function(id) assert(id==1429);return {{nodeID=1,state=0,slotIndex=7},{nodeID=3,state=1,slotIndex=2}} end
    GetNumRoutes=function(slot) assert(slot==2);return 1 end
    TaxiGetNodeSlot=function(slot,i,source) return source and 7 or 2 end;TaxiNodeCost=function() return 20 end
    local observed=A.Taxi(1429,C.character,data);assert(observed.from==1 and observed.offers[3].key=='44' and observed.offers[3].slot==2)
    TaxiGetNodeSlot=function() return 99 end;assert(not next(A.Taxi(1429,C.character,data).offers))
end)
test('no addon network or movement automation entry points invoked',function() assert(hooks.TakeTaxiNode and not C.chosenFlight) end)
test('open taxi before Go reconciles whole itinerary with unknown fly-through',function()
    C:Edit();C.data={nodes={},edges={}};C.character.known={};C.query='';C.filter={categories={},classes={},professions={}}
    local p=A.Position()
    for i=1,3 do C.data.nodes[i]={id=i,map=0,uiMapID=1429,x=p.x+(i-1)*100,y=p.y,name='Master '..i,category='flight'} end
    for i=1,2 do C.data.edges[i]={id=100+i,from=i,to=i+1,start=C.data.nodes[i],finish=C.data.nodes[i+1],mode='flight',distance=120} end
    C_TaxiMap.GetTaxiNodesForMap=function() return {} end
    C_TaxiMap.GetAllTaxiNodes=function() return {{nodeID=1,state=0,slotIndex=1},{nodeID=2,state=2,slotIndex=2},{nodeID=3,state=1,slotIndex=3}} end
    GetNumRoutes=function() return 2 end;TaxiGetNodeSlot=function(slot,i,source) return source and i or i+1 end
    C:TaxiOpened();assert(C.taxi and not C.character.known[2])
    C:Choose(C.data.nodes[3]);C:Plan();local flightIndex
    for i,r in ipairs(C.results) do if r.flight>0 and not r.conditional then flightIndex=i end end
    assert(flightIndex);C.selected=flightIndex;C:Go();assert(C.nav.state=='awaiting_flight' and C.nav.route.legs[C.nav.leg].to==3)
    C.events.scripts.OnEvent(nil,'TAXIMAP_CLOSED');assert(C.results[flightIndex].conditional and C.nav.route.conditional)
    C:TaxiOpened()
    assert(N.Navigation.Target(C.nav).id==1);hooks.TakeTaxiNode(3);onTaxi=true;now=1;C:Tick();assert(C.nav.state=='flying')
    playerY=playerY+.1;onTaxi=false;now=21;C:Tick();assert(C.character.timings['101,102'][1]==20)
    C:Stop();C.data.nodes[999]={id=999,map=0,x=0,y=0,name='Debug test'};C:Reindex()
    for _,d in ipairs(C.destinations) do assert(d.id~=999) end
end)
test('two Enter presses accept then plan without losing focus',function()
    C:Edit();C.filter={categories={},classes={},professions={}};C.matches={C.destinations[1]};C.highlight=1;C.searchOrigin=false;U.to:SetFocus()
    U.to.scripts.OnEnterPressed();assert(U.to:HasFocus() and C.destination)
    U.to.scripts.OnEnterPressed();assert(not U.to:HasFocus() and #C.results>0)
end)

test('confirmed flight survives repeated late missing-position ticks without timing',function()
    C:Stop();local p=A.Position();p.name='Departure';local destination=N.Model.Copy(p);destination.x=p.x+100;destination.id='landing';destination.name='Landing'
    local edge={id=901,from=1,to=3,start=p,finish=destination,mode='flight',distance=120,offered=true}
    local route=N.Routes.Summary({edge},destination,C:Context());assert(N.Navigation.Start(C.nav,route,p,0))
    C.chosenFlight={from=1,to=3,at=0};onTaxi=true;now=1;C:Tick();assert(C.nav.flightSeen and C.nav.measure)
    C.destination=destination;C:Enter();assert(C.nav.route==route and C.nav.state=='flying' and C.nav.flightSeen)
    local original=A.Position;A.Position=function() return nil end
    now=12;C:Tick();now=13;C:Tick();assert(C.nav.state=='paused' and C.chosenFlight and not C.nav.measure)
    A.Position=function() return p end;now=14;C:Tick();assert(C.nav.state=='flying' and not C.nav.measure)
    A.Position=function() return destination end;onTaxi=false;now=30;C:Tick();assert(C.nav.leg==2 and not C.character.timings['901'])
    A.Position=original;C:Stop()
end)
test('flight overlay uses source segments, caches geometry, hides on stop',function()
    local route={legs={{mode='walk',start={map=0},points={{0,0},{100,100}}},{mode='flight',geometry={{map=0,points={{1000,-1000},{1000,2000},{1000,5000}}}}}}}
    N.Overlay:FlightPaths(route,canvas,1429);assert(N.Overlay.visibleSegments==2)
    local allocated=#frames;N.Overlay:FlightPaths(route,canvas,1429);assert(#frames==allocated)
    local line=N.Overlay.lines[1];assert(line.startPoint[3]==0 and line.endPoint[3]==500)
    N.Overlay:Clear();assert(not N.Overlay.paths:IsShown())
    N.Overlay:FlightPaths(route,canvas,1430);assert(#frames==allocated)
end)
test('nearest destinations are sorted before truncation with unknown distance last',function()
    C:Stop();local old=C.destinations;local p=A.Position();C.destinations={};C.filter={categories={},classes={},professions={}}
    for i=1,45 do C.destinations[i]={id='npc'..i,name='A'..i,map=p.map,x=p.x+1000+i,y=p.y,category='place'} end
    C.destinations[46]={id='closest',name='Z closest',map=p.map,x=p.x+1,y=p.y,category='place'}
    C.destinations[47]={id='cross',name='A cross',map=99,x=0,y=0,category='place'}
    C:Search('');for _,fn in ipairs(timers) do fn() end;timers={}
    assert(#C.matches==40 and C.matches[1].id=='closest' and not U.rows[1].go:IsShown())
    assert(not U.rows[1].detail:GetText():find('eligibility'))
    local items={C.destinations[47],{id='unknown',name='Z unknown',category='place'},{id='b',name='Equal',map=p.map,x=p.x+2,y=p.y},{id='a',name='Equal',map=p.map,x=p.x+2,y=p.y}}
    local sorted=N.Model.Search(items,'',nil,C:Context(),nil,p);assert(sorted[1].id=='a' and sorted[2].id=='b' and sorted[3].id=='cross' and sorted[4].id=='unknown')
    C.destinations=old;C:Stop()
end)

test('per-row Go selects the clicked route and reserves its own text column',function()
    local p=A.Position();local goals={};for i=1,2 do goals[i]=N.Model.Copy(p);goals[i].id='goal'..i;goals[i].name='Goal '..i;goals[i].x=p.x+i*200 end
    C.data={nodes={},edges={}};C.results=N.Routes.Plan(p,goals,C.data,C:Context());C.matches=nil;C.selected=1;C.origin=nil;C:Refresh()
    assert(U.rows[1].go:IsShown() and U.rows[2].go:IsShown() and not U.rows[3].go:IsShown() and not U.go:IsShown())
    assert(U.rows[1].name:GetWidth()+10<=C.profile.width-80)
    U.rows[2].go.scripts.OnClick();assert(C.nav.route.destination.id=='goal2' and C.compact)
    U.expand.scripts.OnClick();U.tuck.scripts.OnClick();assert(C.nav.route.destination.id=='goal2' and #C.results==0)
    C:Stop()
end)

test('route legs collapse multihop flights and omit duplicated totals',function()
    local function flight(a,b,seconds) return {mode='flight',start={name=a},finish={name=b},distance=1000,seconds=seconds} end
    local walk={mode='walk',distance=420}
    local text=N.Model.RouteLegs({legs={walk,flight('A','B',60),flight('B','C',120),walk}},7)
    assert(text=='Walk ~1 min\nFly ~3 min: A to C\nWalk ~1 min' and not text:find('B'))
    local offered=flight('A','C',180);assert(N.Model.RouteLegs({legs={walk,offered,walk}},7)==text)
    assert(N.Model.RouteLegs({legs={walk}},7)=='Walk ~1 min')
end)

test('header controls open useful menu and back preserves navigation',function()
    C:Stop();C:ShowPanel(true);N.Options.frame:Hide()
    assert(U.header:GetWidth()<=C.profile.width-72 and U.settings:GetFrameLevel()>U.header:GetFrameLevel())
    U.settings.scripts.OnClick();assert(U.menu:IsShown());U.tuck.scripts.OnClick();assert(not U.menu:IsShown())
    U.settings.scripts.OnClick();U.menuOptions.scripts.OnClick();assert(N.Options.frame:IsShown() and not U.menu:IsShown())
    U.tuck.scripts.OnClick();assert(not N.Options.frame:IsShown())
    U.settings.scripts.OnClick();U.menuTuck.scripts.OnClick();assert(C.tucked and U.handle:IsShown() and not U.frame:IsShown())
    U.handle.scripts.OnClick();assert(not C.tucked and U.frame:IsShown())
    C.filter={categories={class=true},classes={MAGE=true},professions={}};LOCALIZED_CLASS_NAMES_MALE={MAGE='Mage'};C:Refresh();assert(U:ClassLabel('MAGE')=='Mage' and not U.specialization)
    C.filter={categories={},classes={},professions={}}
end)

test('commands open options idempotently and explicit show hide retain route state',function()
    local commands=SlashCmdList.ASTHECROWFLIES;N.Options.frame:Hide();commands('');assert(N.Options.frame:IsShown())
    commands('opts');commands('options');assert(N.Options.frame:IsShown())
    local state=C.nav;commands('hide');C:Tick();assert(not U.frame:IsShown() and not U.handle:IsShown() and C.nav==state)
    commands('show');assert(U.frame:IsShown() and not C.hidden);commands(' OPTIONS ');assert(N.Options.frame:IsShown())
    N.Options.frame:Hide()
end)

test('fonts reach dropdown rows and late SharedMedia registration',function()
    local available=false;local callbacks={};local lib={IsValid=function() return available end,Fetch=function() return 'expressway.ttf' end,List=function() return {'Expressway'} end,RegisterCallback=function(owner,event,fn) callbacks[event]=fn end}
    LibStub=function() return lib end;C.profile.font='Expressway';U:WatchFonts();available=true;callbacks.LibSharedMedia_Registered(nil,'font')
    assert(U.title.font=='expressway.ttf' and N.Options.order.Text.font=='expressway.ttf' and U.menuFont.font=='expressway.ttf')
    local initializers={};local root={SetScrollMode=function() end,CreateRadio=function() return {AddInitializer=function(_,fn) initializers[#initializers+1]=fn end} end}
    N.Options.order.menu(nil,root);local fontString=setmetatable({SetFontObject=function(self,font) self.actual=font end},{__index=function(_,key) if key=='SetFont' then error('compositor SetFont access') end end})
    initializers[1]({fontString=fontString});assert(fontString.actual==U.menuFont)
    local before=#U.texts;U:RefreshFonts();assert(#U.texts==before);LibStub=nil
end)

test('profile and color interactions preserve character flight knowledge and cancel safely',function()
    local O=N.Options;C.character.known[87]={state='known'};C.character.timings['87']={60};local character=C.character
    O.name:SetText('Travel');O.duplicate.scripts.OnClick();assert(C.profiles.active=='Travel' and AsTheCrowFliesDB==C.profile)
    C.profile.scale=1.1;O:ProfileAction('SwitchProfile','Default');assert(C.character==character and character.known[87] and character.timings['87'][1]==60)
    O.copyName='Travel';O.copy.scripts.OnClick();assert(O.confirm=='copy');O.cancel.scripts.OnClick();assert(not O.confirm)
    O.copy.scripts.OnClick();O.copy.scripts.OnClick();assert(C.profile.scale==1.1 and C.profiles.active=='Default')
    ColorPickerFrame=object();ColorPickerFrame:Hide();function ColorPickerFrame:SetupColorPickerAndShow(info) self.info=info;self:Show() end
    function ColorPickerFrame:GetExtraInfo() return self.info and self.info.extraInfo end
    function ColorPickerFrame:GetColorRGB() return .2,.3,.4 end
    local original=N.Model.Copy(C.profile.colors.accent);O:Color('accent');ColorPickerFrame.info.swatchFunc();assert(C.profile.colors.accent[1]==.2)
    ColorPickerFrame.info.cancelFunc();assert(C.profile.colors.accent[1]==original[1]);ColorPickerFrame:Hide()
    O.reset.scripts.OnClick();assert(O.confirm=='reset');O.reset.scripts.OnClick();assert(C.profile.scale==1 and C.character==character and character.timings['87'][1]==60)
    ColorPickerFrame=nil;C:Stop()
end)
local function discoveryFixture()
    C:Stop();C:ShowPanel(true);C.origin=nil;C.taxi=nil;C.matches=nil;C.query='';C.filter={categories={},classes={},professions={}}
    local old={data=C.data,known=C.character.known,destinations=C.destinations,order=C.profile.routeOrder,map=C_TaxiMap.GetTaxiNodesForMap,all=C_TaxiMap.GetAllTaxiNodes,routes=GetNumRoutes,slot=TaxiGetNodeSlot}
    local p=A.Position();C.data={nodes={},edges={}};C.character.known={[201]={state='known'},[203]={state='undiscovered'}};C.profile.routeOrder='distance'
    for i=1,3 do local node=N.Model.Copy(p);node.id=200+i;node.x=p.x+(i-1)*500;node.name='Discovery master '..i;node.category='flight';C.data.nodes[node.id]=node end
    C.data.edges={{id=703,from=201,to=203,start=C.data.nodes[201],finish=C.data.nodes[203],mode='flight',distance=1100}}
    local goal=N.Model.Copy(C.data.nodes[203]);goal.id='discovery-goal';goal.name='Discovery destination';goal.category='place';C.destinations={goal};C:Choose(goal);C:Plan()
    local function cleanup()
        C:Stop();C.taxi=nil;C.destination=nil;C.data=old.data;C.character.known=old.known;C.destinations=old.destinations;C.profile.routeOrder=old.order
        C_TaxiMap.GetTaxiNodesForMap=old.map;C_TaxiMap.GetAllTaxiNodes=old.all;GetNumRoutes=old.routes;TaxiGetNodeSlot=old.slot;onTaxi=false
    end
    return goal,cleanup
end

test('undiscovered route has dark red overlay and cannot start through any Go path',function()
    local _,cleanup=discoveryFixture();assert(#C.results==2 and not C.results[1].unavailable and C.results[2].unavailable=='undiscovered')
    local row=U.rows[2];assert(row.locked:IsShown() and row.go:IsShown() and row.go.enabled==false)
    assert(row.lockedText:GetText()=='Undiscovered flight points' and row.lockedText.textColor[1]>.8 and row.lockedText.textColor[2]<.4)
    local shaded=false;for _,f in ipairs(frames) do if f.parent==row.locked and f.color and f.color[1]==0 and (f.color[4] or 0)>.5 then shaded=true end end;assert(shaded)
    local savedPicker=ColorPickerFrame;ColorPickerFrame=object();ColorPickerFrame:Show()
    N.Options.colorEdit={profile=C.profile,key='accent',original=N.Model.Copy(C.profile.colors.accent)};N.Options:CloseColor();ColorPickerFrame=savedPicker
    assert(row.lockedText.textColor[1]>.8 and row.lockedText.textColor[2]<.4,'color editor close must preserve red discovery warning')
    assert(U.rows[1].go.enabled and not U.rows[1].locked:IsShown())
    row.go.scripts.OnClick();assert(not C.nav.route and not C.compact)
    row.scripts.OnClick();assert(C.selected==2);C:Go();assert(not C.nav.route and C.status:find('Discover'))
    assert(not N.Navigation.Start(C.nav,C.results[2],A.Position(),now) and not C.nav.route)
    C:Tick();assert(not C.nav.route and not C.compact,'destination preview must never start a blocked route');cleanup()
end)

test('taxi observation unlocks an already displayed undiscovered route',function()
    local _,cleanup=discoveryFixture()
    C_TaxiMap.GetTaxiNodesForMap=function() return {{nodeID=201,faction=2,isUndiscovered=false},{nodeID=203,faction=2,isUndiscovered=false}} end
    C_TaxiMap.GetAllTaxiNodes=function() return nil end
    C.events.scripts.OnEvent(nil,'TAXIMAP_OPENED')
    local conditional;for _,r in ipairs(C.results) do if r.flight>0 then conditional=r;assert(not r.unavailable and r.conditional) end end;assert(conditional)
    C_TaxiMap.GetAllTaxiNodes=function() return {{nodeID=203,state=0,slotIndex=3}} end
    C.events.scripts.OnEvent(nil,'TAXIMAP_OPENED');assert(not C.taxi and U.note:GetText():find('could not be reconciled'))
    for _,r in ipairs(C.results) do assert(not r.unavailable) end
    C_TaxiMap.GetAllTaxiNodes=function() return {{nodeID=201,state=0,slotIndex=1},{nodeID=203,state=1,slotIndex=3}} end
    GetNumRoutes=function() return 1 end;TaxiGetNodeSlot=function(_,_,source) return source and 1 or 3 end
    C.events.scripts.OnEvent(nil,'TAXIMAP_OPENED');assert(C.character.known[203].state=='known')
    local index;for i,r in ipairs(C.results) do if r.flight>0 then index=i;assert(not r.unavailable and not r.conditional) end end;assert(index)
    assert(not U.rows[index].locked:IsShown() and U.rows[index].go.enabled)
    U.rows[index].go.scripts.OnClick();assert(C.nav.route and C.nav.state=='awaiting_flight' and not C.nav.route.unavailable)
    cleanup()
end)

test('offered whole flight remains usable through explicitly undiscovered intermediate',function()
    local goal,cleanup=discoveryFixture();C.data.edges={}
    for i=1,2 do C.data.edges[i]={id=710+i,from=200+i,to=201+i,start=C.data.nodes[200+i],finish=C.data.nodes[201+i],mode='flight',distance=550} end
    C_TaxiMap.GetTaxiNodesForMap=function() return {{nodeID=201,faction=2,isUndiscovered=false},{nodeID=202,faction=2,isUndiscovered=true},{nodeID=203,faction=2,isUndiscovered=false}} end
    C_TaxiMap.GetAllTaxiNodes=function() return {{nodeID=201,state=0,slotIndex=1},{nodeID=202,state=2,slotIndex=2},{nodeID=203,state=1,slotIndex=3}} end
    GetNumRoutes=function() return 2 end;TaxiGetNodeSlot=function(_,i,source) return source and i or i+1 end
    C.events.scripts.OnEvent(nil,'TAXIMAP_OPENED');assert(C.character.known[202].state=='undiscovered')
    C:Choose(goal);C:Plan();local index
    for i,r in ipairs(C.results) do if r.flight>0 and not r.conditional then index=i;assert(not r.unavailable and r.signature=='discovery-goal/711/712') end end;assert(index)
    assert(U.rows[index].go.enabled and not U.rows[index].locked:IsShown())
    U.rows[index].go.scripts.OnClick();assert(C.nav.state=='awaiting_flight' and C.nav.route.legs[C.nav.leg].to==203)
    hooks.TakeTaxiNode(3);onTaxi=true;now=now+1;C:Tick();assert(C.nav.state=='flying' and C.nav.flightSeen)
    cleanup()
end)
local function classicPicker()
    local picker=object();picker:Hide()
    function picker:GetExtraInfo() return self.info and self.info.extraInfo end
    function picker:GetColorRGB() return unpack(self.rgb) end
    function picker:SetupColorPickerAndShow(info)
        self.info=info;self.rgb={info.r,info.g,info.b}
        -- Exact Classic order: callbacks/extraInfo, SetColorRGB (OnColorSelect), Show.
        info.swatchFunc();self:Show()
    end
    return picker
end

test('Classic color picker hide-before-callback cancel and Okay preserve their meaning',function()
    local O=N.Options;local saved=ColorPickerFrame;ColorPickerFrame=classicPicker();local picker=ColorPickerFrame
    local original=N.Model.Copy(C.profile.colors.accent)
    O:Color('accent');assert(O.colorEdit and picker:IsShown(),'initial hidden OnColorSelect must not end ownership')
    picker.rgb={.21,.32,.43};picker.info.swatchFunc();assert(C.profile.colors.accent[1]==.21)
    picker:Hide();picker.info.cancelFunc();assert(C.profile.colors.accent[1]==original[1] and not O.colorEdit)
    O:Color('accent');picker.rgb={.31,.42,.53}
    -- Classic Okay hides, then invokes the final swatch callback.
    picker:Hide();picker.info.swatchFunc();assert(C.profile.colors.accent[1]==.31 and not O.colorEdit)
    O:Color('accent');local current=O.colorEdit
    local pending=timers;timers={};for _,fn in ipairs(pending) do fn() end
    assert(O.colorEdit==current and picker:IsShown(),'older hide cleanup must not cancel a reopened session')
    picker.rgb={.51,.62,.73};picker.info.swatchFunc();O:CloseColor()
    assert(not picker:IsShown() and C.profile.colors.accent[1]==.31 and O.colors.accent.swatch.color[1]==.31)
    C.profile.colors.accent=original;C:ApplyProfile();ColorPickerFrame=saved
end)

test('shared color picker takeover never hides another addon or applies stale callbacks',function()
    local O=N.Options;local saved=ColorPickerFrame;ColorPickerFrame=classicPicker();local picker=ColorPickerFrame
    local original=N.Model.Copy(C.profile.colors.background)
    O:Color('background');picker.rgb={.11,.22,.33};picker.info.swatchFunc();local stale=picker.info
    local other={};picker:SetupColorPickerAndShow({r=.6,g=.7,b=.8,extraInfo=other,swatchFunc=function() end})
    stale.swatchFunc();stale.cancelFunc();O:CloseColor()
    assert(picker:IsShown() and picker:GetExtraInfo()==other and C.profile.colors.background[1]==.11)
    picker:Hide();C.profile.colors.background=original;C:ApplyProfile();ColorPickerFrame=saved
end)

test('bounded trainer results retain width across compact state and reflow profile controls',function()
    C:Stop();local previous={width=C.profile.width,scale=C.profile.scale,filter=C.filter,route=C.nav.route,results=C.results}
    local p=A.Position();local goal=N.Model.Copy(p);goal.id='layout-goal';goal.name='A long localized destination name';goal.x=p.x+500
    local route=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=500,quality='bearing'}},goal,C:Context())
    C.filter={categories={class=true},classes={MAGE=true},professions={}};C.results={route,route,route};C.matches=nil;C.nav.route=route;C.nav.leg=1;C.nav.state='walking';C.profile.scale=1.6
    C.nav.route=nil;C.compact=false;C.status=nil;C:Refresh()
    assert(not U.go:IsShown() and not U.stop:IsShown() and not U.fold:IsShown())
    assert(U.frame:GetHeight()==U.bodyTop+U.bodyScroll:GetHeight()+20,'results without footer controls retain grip padding')
    C.nav.route=route
    UIParent:SetSize(1280,720)
    for _,width in ipairs({280,320}) do
        C.profile.width=width;C.compact=false;C.status='A route status';C:Refresh()
        local physical=U.frame:GetWidth()*U.frame:GetScale()
        assert(U.frame:GetHeight()*U.frame:GetScale()<=720 and U.rows[3].detail:GetHeight()>0)
        assert(U.header:GetWidth()<U.settings.point[2] and U.settings:GetFrameLevel()>U.header:GetFrameLevel())
        assert(U.from:GetWidth()==width-104 and U.body:GetWidth()==width-28 and U.filterButton.point[2]==width-38)
        assert(U.fold:IsShown() and U.fold.point[2]+U.fold:GetWidth()<U.go.point[2])
        assert(U.rows[1].name:GetWidth()+10<=U.rows[1]:GetWidth()-8-U.rows[1].go:GetWidth())
        C.compact=true;C:Refresh();assert(U.frame:GetWidth()*U.frame:GetScale()==physical)
        U.expand.scripts.OnClick();assert(U.frame:GetWidth()*U.frame:GetScale()==physical and U.fold:IsShown())
    end
    UIParent:SetSize(1920,1080);C.profile.width=previous.width;C.profile.scale=previous.scale;C.filter=previous.filter;C:Stop()
end)

test('open options follows display changes and closes pending confirmation and focus',function()
    local O=N.Options;O:Open();O.optionsTab.scripts.OnClick()
    assert(O.optionsTab.activeLine:IsShown() and not O.profilesTab.activeLine:IsShown() and O.appearance:IsShown())
    O.profilesTab.scripts.OnClick()
    assert(not O.optionsTab.activeLine:IsShown() and O.profilesTab.activeLine:IsShown() and O.profilePage:IsShown())
    assert(O.profilesTab.activeLine.color[1]==1 and O.profilesTab.activeLine.color[2]==.82)
    O.name:SetFocus();O.confirm='reset'
    UIParent:SetSize(600,400);O.frame.scripts.OnEvent(O.frame,'DISPLAY_SIZE_CHANGED')
    assert(O.frame:GetWidth()*O.frame:GetScale()<=600 and O.frame:GetHeight()*O.frame:GetScale()<=400)
    O.frame:Hide();assert(not O.confirm and not O.name:HasFocus())
    O:Open();assert(O.frame:IsShown() and not O.confirm and O.reset.text:GetText()=='Reset active profile')
    assert(O.profilesTab.activeLine:IsShown() and not O.optionsTab.activeLine:IsShown())
    UIParent:SetSize(1920,1080);O.frame.scripts.OnEvent(O.frame,'UI_SCALE_CHANGED');assert(O.frame:GetScale()==1);O.frame:Hide()
end)

test('profile switch changes displayed route ordering without replacing active navigation',function()
    C:Stop();local previous={profiles=C.profiles,profile=C.profile,data=C.data,known=C.character.known,filter=C.filter}
    local p=A.Position();local goal=N.Model.Copy(p);goal.x=p.x+1000;goal.id='profile-goal';goal.name='Profile destination'
    C.data={nodes={[1]=p,[2]=goal},edges={{id=801,from=1,to=2,start=p,finish=goal,mode='flight',distance=1400}}}
    C.character.known={[1]={state='known'},[2]={state='known'}};C.filter={categories={},classes={},professions={}};C.destination=goal;C.origin=nil;C.taxi=nil
    local fast=N.Model.Copy(C.profile);fast.routeOrder='time';fast.width=320
    local short=N.Model.Copy(C.profile);short.routeOrder='distance';short.width=280
    C.profiles={version=1,active='Short',profiles={Short=short,Fast=fast}};C.profile=short
    C:Plan();assert(C.results[1].flight==0);C:Go();local active=C.nav.route
    assert(N.Options:ProfileAction('SwitchProfile','Fast'))
    assert(C.results[1].flight>0 and C.nav.route==active and C.profile.width==320)
    C.profiles=previous.profiles;C.profile=previous.profile;C.data=previous.data;C.character.known=previous.known;C.filter=previous.filter;C.destination=nil;C:Stop();C:ApplyProfile()
end)
test('Back returns selected destination or last selected origin to search without losing navigation',function()
    C:Stop();N.Options.frame:Hide();U.menu:Hide();C:ShowPanel(true)
    local previous={destinations=C.destinations,filter=C.filter};local p=A.Position()
    local goal=N.Model.Copy(p);goal.id='back-goal';goal.name='Back destination';goal.category='place';goal.x=p.x+500
    local origin=N.Model.Copy(p);origin.id='back-origin';origin.name='Back origin';origin.category='place';origin.x=p.x+100
    C.destinations={goal,origin};C.filter={categories={},classes={},professions={}};C.query='Back';C.origin=nil;C.destination=nil
    C:Choose(goal);C:Back();local pending=timers;timers={};for _,fn in ipairs(pending) do fn() end
    assert(not C.destination and not C.tucked and C.matches and not C.searchOrigin)
    C:Choose(goal);C:Plan();C:Go();local active=C.nav.route;assert(active)
    C.compact=false;C:Choose(goal);C:Choose(origin,true);C:Back()
    pending=timers;timers={};for _,fn in ipairs(pending) do fn() end
    assert(not C.origin and C.destination==goal and C.searchOrigin and C.nav.route==active and not C.tucked)
    C:Stop();C.destinations=previous.destinations;C.filter=previous.filter;C.destination=nil
end)

test('empty autocomplete distinguishes unavailable and indexing NPC data without repetitive row notices',function()
    C:Stop();local previous={provider=C.provider,filter=C.filter};C.status=nil;C.matches={};C.searchOrigin=false;C.filter={categories={class=true},classes={MAGE=true},professions={}}
    C.provider=nil;C:Refresh();assert(U.note:IsShown() and U.note:GetText():find('requires Forever QuestieDB'))
    C.provider={ids={1,2},cursor=1};C:Refresh();assert(U.note:GetText()=='Indexing NPC destinations...')
    C.provider.cursor=3;C:Refresh();assert(U.note:GetText():find('No matching destinations'))
    C.filter={categories={place=true},classes={},professions={}};C.provider=nil;C:Refresh();assert(not U.note:GetText():find('QuestieDB'))
    local p=A.Position();p.name='Saved result';p.category='place';C.matches={p};C:Refresh();assert(not U.note:IsShown())
    local savedDestinations=C.destinations;C.destinations={};C.destination=nil;C.filter={categories={class=true},classes={MAGE=true},professions={}};C:Plan();assert(C.status:find('requires Forever QuestieDB'))
    C.provider={ids={1},cursor=1};C:Plan();assert(C.status=='Indexing NPC destinations...')
    C.provider.cursor=2;C:Plan();assert(C.status=='No matching destinations.');C.destinations=savedDestinations
    C.provider=previous.provider;C.filter=previous.filter;C:Stop()
end)
local function flushSearch()
    local pending=timers;timers={};for _,fn in ipairs(pending) do fn() end
end
local function filterDescription()
    local function description(label,selected,callback)
        local d={label=label,selected=selected,callback=callback,children={}}
        function d:SetScrollMode(v) self.scroll=v end
        function d:AddInitializer(fn) self.initializer=fn end
        function d:CreateCheckbox(text,isSelected,onSelect)
            local child=description(text,isSelected,onSelect);self.children[#self.children+1]=child;return child
        end
        return d
    end
    local root=description();U.filterButton.menu(U.filterButton,root);return root
end
test('minimal idle expands on typing and clear Escape Stop cancel queued searches',function()
    C:Stop();C.destination=nil;C.origin=nil;C.query='';C.status=nil;C:BindFilters();C:Filter('all');U.to.scripts.OnEscapePressed();C:Refresh()
    assert(U.frame:GetHeight()==129 and not U.body:IsShown() and not U.go:IsShown() and not U.stop:IsShown() and not U.note:IsShown())
    assert(not U.category and not U.specialization and U.filterButton:IsShown())
    U.to:SetFocus();U.to:SetText('mage');U.to.scripts.OnTextChanged(nil,true)
    assert(C.searching and U.frame:GetHeight()>129 and U.body:IsShown())
    U.to.scripts.OnEscapePressed();flushSearch();assert(not C.matches and not C.searching and U.frame:GetHeight()==129 and not U.to:HasFocus())
    U.to:SetFocus();U.to:SetText('bank');U.to.scripts.OnTextChanged(nil,true)
    U.to:SetText('');U.to.scripts.OnTextChanged(nil,true);flushSearch();assert(not C.matches and U.frame:GetHeight()==129 and C.query=='')
    U.to:ClearFocus();C:Refresh();assert(U.to:GetText()=='');C:Plan();assert(#C.results==0 and C.status:find('Choose'))
    U.to:SetText('trainer');U.to.scripts.OnTextChanged(nil,true);C:Stop();flushSearch();assert(not C.matches and not C.searching)
    U.to:ClearFocus();C.query='';C:Refresh()
end)
test('native filter nested checkboxes support OR class defaults reset and repeated changes',function()
    C:BindFilters();C:Filter('all');flushSearch();local menu=filterDescription();assert(menu.scroll==280 and #menu.children==8 and menu.children[1].selected())
    local d=U.filterButton;local icon=d.icons.filter.texture
    assert(d.kind=='DropdownButton' and icon:GetAtlas()=='gamepad-hud-icon-filter' and icon.desaturated)
    assert(icon:GetWidth()==18 and icon:GetHeight()==18 and d:GetWidth()==24 and d:GetHeight()==28 and not d.text:IsShown())
    assert(icon.color[1]==.75 and icon.color[2]==.75 and icon.color[3]==.75 and d.pushedTexture==d.nativePushed)
    d.scripts.OnEnter();assert(d.bg.color[1]==d.hoverColor[1] and GameTooltip:GetText()=='Filter destinations')
    d.menuOpen=true;d:TriggerEvent('OnMenuOpen');d.scripts.OnLeave();assert(d.bg.color[1]==d.hoverColor[1],'open menu retains its background after pointer leaves')
    d:CloseMenu();assert(d.bg.color[1]==d.normalColor[1])
    d.scripts.OnEnter();d.menuOpen=true;d:TriggerEvent('OnMenuOpen');d:CloseMenu();assert(d.bg.color[1]==d.hoverColor[1]);d.scripts.OnLeave()
    local classes=menu.children[3];assert(classes.label=='Class trainers' and classes.scroll==280 and #classes.children==10)
    classes.callback();flushSearch();assert(C.filter.categories.class and C.filter.classes.MAGE and classes.selected())
    menu.children[2].callback();flushSearch();assert(C.filter.categories.auction and C.filter.categories.class)
    classes.children[1].callback();flushSearch();assert(not next(C.filter.classes) and classes.children[1].selected())
    classes.children[2].callback();flushSearch();assert(C.filter.classes.WARRIOR)
    local professions=menu.children[4];professions.children[2].callback();flushSearch();assert(C.filter.professions.Alchemy and C.filter.categories.profession)
    assert(icon.color[1]==1 and icon.color[2]==.82 and icon.color[3]==0)
    assert(d.text.textColor[1]==1 and d.text.textColor[2]==.82 and d.text.textColor[3]==0)
    for _=1,4 do menu.children[2].callback();flushSearch() end;assert(C.filter.categories.auction)
    local fontString=object();classes.initializer({fontString=fontString});assert(fontString.fontObject==U.menuFont)
    U.to:SetFocus();U.filterButton.scripts.OnMouseDown();assert(not U.to:HasFocus())
    U.filterButton.menuOpen=true;C:Back();assert(not U.filterButton:IsMenuOpen())
    menu.children[1].callback();flushSearch();assert(not N.Model.HasFilter(C.filter) and not next(C.filter.classes) and not next(C.filter.professions))
    assert(icon.color[1]==.75 and icon.color[2]==.75 and icon.color[3]==.75)
    assert(d.text.textColor[1]==.75 and d.text.textColor[2]==.75 and d.text.textColor[3]==.75);C:Stop()
end)
test('filter OR reaches route planning and nested class subsets without cancelling navigation',function()
    local saved={destinations=C.destinations,data=C.data};C:Stop();C:BindFilters();C:Filter('all');flushSearch()
    C.data={nodes={},edges={}};C.query='';C.destination=nil;C.origin=nil;C.destinations={}
    local p=A.Position()
    for i,entry in ipairs({{id='mage',name='Mage trainer',category='class',class='MAGE'},{id='warrior',name='Warrior trainer',category='class',class='WARRIOR'},{id='auction',name='Auctioneer',category='auction'}}) do
        entry.map=p.map;entry.uiMapID=p.uiMapID;entry.x=p.x+i*30;entry.y=p.y;entry.faction='Alliance';C.destinations[i]=entry
    end
    C:Filter('categories','class');C:Filter('categories','auction');flushSearch();assert(#C.matches==2)
    U.go.scripts.OnClick();assert(#C.results==2 and not C.destination);C:Go();local active=C.nav.route;assert(active)
    C:Filter('classes','all');flushSearch();assert(#C.matches==3 and C.nav.route==active and not C.compact)
    C:Filter('classes','WARRIOR');flushSearch();assert(#C.matches==2 and C.matches[1].id=='warrior' and C.nav.route==active)
    C:Stop();C:Filter('all');flushSearch();C:Stop();C.destinations=saved.destinations;C.data=saved.data;C.query=''
end)
test('profile switches bind independent filters and replace pending searches while preserving route',function()
    local saved={profiles=C.profiles,profile=C.profile,destinations=C.destinations};C:Stop();C.destination=nil;C.query='';C.origin=nil
    local p=A.Position();local goal=N.Model.Copy(p);goal.x=p.x+100;goal.id='profile-filter';goal.name='Profile place';goal.category='place'
    local trainer=N.Model.Copy(goal);trainer.id='profile-mage';trainer.name='Profile mage';trainer.category='class';trainer.class='MAGE'
    C.destinations={goal,trainer}
    local all=N.Model.Copy(C.profile);all.searchFilters={categories={},classes={},professions={}}
    local class=N.Model.Copy(all);class.searchFilters={categories={class=true},classes={MAGE=true},professions={}}
    C.profiles={version=1,active='All',profiles={All=all,Class=class}};C.profile=all;C:BindFilters()
    C:Choose(goal);C:Plan();C:Go();local active=C.nav.route;C.destination=nil;C:Search('')
    assert(N.Options:ProfileAction('SwitchProfile','Class'));flushSearch()
    assert(C.filter==C.profile.searchFilters and C.filter.categories.class and #C.matches==1 and C.matches[1]==trainer and C.nav.route==active)
    C:Filter('categories','auction');flushSearch();assert(not all.searchFilters.categories.auction)
    assert(N.Options:ProfileAction('SwitchProfile','All'));flushSearch();assert(#C.matches==2 and not N.Model.HasFilter(C.filter) and C.nav.route==active)
    C.profiles=saved.profiles;C.profile=saved.profile;C.destinations=saved.destinations;C:BindFilters();C:Stop();C:ApplyProfile()
end)
test('typed intent planning keeps semantic candidates ahead of closer incidental names',function()
    local saved={destinations=C.destinations,data=C.data};C:Stop();C:BindFilters();C:Filter('all');flushSearch();C.destination=nil;C.origin=nil;C.data={nodes={},edges={}}
    local p=A.Position();local trainer=N.Model.Copy(p);trainer.x=p.x+1000;trainer.id='semantic';trainer.name='Trainer Elara';trainer.category='class';trainer.class='MAGE'
    local incidental=N.Model.Copy(p);incidental.x=p.x+1;incidental.id='incidental';incidental.name='Mage Slayer';incidental.category='quest'
    C.destinations={incidental,trainer};C.query='mage';C:Plan();assert(#C.results==1 and C.results[1].destination==trainer)
    C:Choose(incidental);C:Plan();assert(C.results[1].destination==incidental)
    C.destination=nil;C.query='';C:Plan();assert(#C.results==0 and C.status:find('Choose'))
    C:Stop();C.destinations=saved.destinations;C.data=saved.data;C.query=''
end)
test('edge selection and unlocked dragging tuck on the correct side without changing navigation',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local state=C.nav;local O=N.Options
    local actions={};local root={SetScrollMode=function() end,CreateRadio=function(_,label,selected,choose)
        actions[label]=choose;return {AddInitializer=function() end}
    end}
    O.placement.menu(nil,root);actions['Right screen edge']()
    assert(C.profile.dock=='right' and C.tucked and U.handle:IsShown() and not U.frame:IsShown() and C.nav==state)
    assert(U.handle.point[1]=='RIGHT');U.handle.scripts.OnClick();assert(not C.tucked and U.frame:IsShown())
    C.profile.locked=true;local x,y=C.profile.x,C.profile.y
    U.header.scripts.OnDragStart();U.header.scripts.OnDragStop()
    assert(not C.tucked and C.profile.dock=='right' and C.profile.x==x and C.profile.y==y,'locked drag is inert')
    local oldLeft=U.frame.GetLeft;C.profile.locked=false
    for _,side in ipairs({'left','right','none'}) do
        U.frame.GetLeft=function() return side=='left' and 8 or side=='right' and UIParent:GetWidth()/U.frame:GetScale()-C.profile.width-8 or 200 end
        U.header.scripts.OnDragStart();U.header.scripts.OnDragStop()
        assert(C.profile.dock==side and C.tucked==(side~='none') and C.nav==state)
    end
    U.frame.GetLeft=oldLeft
    for _,key in ipairs({'dock','x','y','locked'}) do C.profile[key]=saved[key] end
    C:ShowPanel(true);C:ApplyProfile()
end)

test('options use XPIsland controls and font sizing preserves fixed dialog typography',function()
    local O=N.Options;local size,scale=C.profile.fontSize,C.profile.scale
    assert(O.close.template=='UIPanelCloseButton' and O.fontSize.template=='InputBoxTemplate' and O.scale.template=='UISliderTemplate')
    assert(O.font.template=='WowStyle1DropdownTemplate' and O.font:GetHeight()==24 and O.optionsTab:GetHeight()==22)
    O.fontSize:SetText('18');O.fontSize.scripts.OnEnterPressed(O.fontSize)
    assert(C.profile.fontSize==18 and U.rows[1].name.fontSize==18 and O.font.Text.fontSize==12 and U.menuSave.text.fontSize==12)
    assert(U.menuSave.text:GetUnboundedStringWidth()<=U.menuSave.text:GetWidth())
    O.scale:SetValue(125);assert(C.profile.scale==1.25 and O.scaleEdit:GetText()=='125')
    O.scaleEdit:SetText('not a number');O.scaleEdit.scripts.OnEnterPressed(O.scaleEdit);assert(C.profile.scale==1.25)
    O.fontSize:SetText('99');O.fontSize.scripts.OnEnterPressed(O.fontSize);assert(C.profile.fontSize==18)
    local sanitized=N.Settings.Load({fontSize=0/0});assert(sanitized.fontSize==13)
    C.profile.fontSize=size;C.profile.scale=scale;C:ApplyProfile()
end)

test('long names and flight descriptions grow and scroll without shrinking the island',function()
    C:Stop();local width,size,scale=C.profile.width,C.profile.fontSize,C.profile.scale
    C.profile.width=280;C.profile.fontSize=18;C.profile.scale=1.6;C:ApplyProfile();UIParent:SetSize(1280,720)
    local p=A.Position();local goal=N.Model.Copy(p);goal.x=p.x+500;goal.id='long';goal.name=string.rep('Long destination ',10)
    local station=N.Model.Copy(p);station.name=string.rep('Long flight station ',8)
    local route=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=500,quality='bearing'},{mode='flight',start=station,finish=goal,distance=500,seconds=60}},goal,C:Context())
    C.results={route,route,route};C.matches=nil;C.destination=goal;C.status=nil;C.compact=false;C:Refresh()
    local row=U.rows[1];assert(U.destinationName:GetText()==goal.name and U.destinationName:GetHeight()>40 and U.destinationName.wordWrap and U.destinationName.nonSpaceWrap)
    assert(row.itinerary:GetHeight()>40 and row.itinerary:GetWidth()>row.name:GetWidth())
    assert(-row.detail.point[3]>=5+row.name:GetHeight() and row:GetHeight()>-row.detail.point[3]+row.detail:GetHeight())
    assert(U.bodyScrollRange>0 and U.frame:GetHeight()*U.frame:GetScale()<=720)
    U.body.scripts.OnMouseWheel(nil,-1);assert(U.bodyScroll:GetVerticalScroll()>0)
    local physical=U.frame:GetWidth()*U.frame:GetScale();C.nav.route=route;C.nav.leg=1;C.nav.state='walking';C.compact=true;C:Refresh()
    assert(U.frame:GetWidth()*U.frame:GetScale()==physical and U.next:GetText()==goal.name and U.next:GetHeight()>40)
    assert(not U.scrollRail:IsShown() and not U.scrollThumb:IsShown(),'overflow cue hides with result viewport')
    C.compact=false;C:Refresh();assert(U.frame:GetWidth()*U.frame:GetScale()==physical)
    UIParent:SetSize(1280,540);C.events.scripts.OnEvent(nil,'DISPLAY_SIZE_CHANGED')
    assert(U.frame:GetHeight()*U.frame:GetScale()<=540 and U.scrollRail:IsShown())
    C.nav.route=nil;goal.category='place';C.matches={goal,goal,goal};C.highlight=1;C:Refresh();C.highlight=3;C:Refresh()
    assert(U.bodyScroll:GetVerticalScroll()>0 and U.bodyScroll:GetVerticalScroll()<=U.rows[3].bodyOffset)
    UIParent:SetSize(1920,1080);C.profile.width=width;C.profile.fontSize=size;C.profile.scale=scale;C:Stop();C:ApplyProfile()
end)

test('empty state message and route action stay centered with hidden route controls',function()
    C:Stop();C.destination=nil;C.status=nil;C.matches={};C.searching=true;C.results={};C:Refresh()
    assert(U.note.justifyH=='CENTER' and U.go.text.justifyH=='CENTER')
    assert(U.go.point[2]+U.go:GetWidth()/2==C.profile.width/2 and not U.stop:IsShown() and not U.fold:IsShown())
    C.matches=nil;C.searching=false;C:Stop()
end)

test('compact route controls pause resume and clear stale arrival dwell',function()
    local facing=GetPlayerFacing;GetPlayerFacing=function() return 0 end
    C:Stop();local p=A.Position();local goal=N.Model.Copy(p);goal.x=p.x+1000;goal.id='compact';goal.name='Kelv Sternhammer'
    local route=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=1000,quality='bearing'}},goal,C:Context())
    C.results={route};C.selected=1;C.origin=nil;C.matches=nil;C.destination=goal;C:Go()
    assert(C.compact and U.frame:GetHeight()<160 and U.pause.iconKind=='pause' and U.stop.iconKind=='close')
    assert(U.stop.normalColor[1]>U.stop.normalColor[2]*3)
    C.nav.dwell=1;C.nav.previous=p;C.nav.previousTime=1;U.pause.scripts.OnClick()
    assert(C.manualPause and U.pause.iconKind=='play' and not C.nav.dwell and not C.nav.previous)
    U.pause.scripts.OnClick();assert(not C.manualPause and U.pause.iconKind=='pause')
    U.stop.scripts.OnClick();assert(not C.nav.route and not U.stop:IsShown());GetPlayerFacing=facing
end)

test('late media registration refits options and custom text color leaves native menus legible',function()
    local O=N.Options;local original=LibStub;local callbacks={};local available=false
    local lib={IsValid=function() return available end,Fetch=function() return 'late-wide.ttf' end,List=function() return {'Expressway'} end,
        RegisterCallback=function(_,event,fn) callbacks[event]=fn end}
    local width=O.font.Text.GetUnboundedStringWidth;O.font.Text.GetUnboundedStringWidth=function() return available and 600 or 60 end
    local color=N.Model.Copy(C.profile.colors.text);C.profile.colors.text={.2,.3,.4};C:ApplyProfile()
    assert(U.menuFont.textColor[1]==.93 and O.font.Text.textColor[1]~=.2)
    LibStub=function() return lib end;U:WatchFonts();available=true;callbacks.LibSharedMedia_Registered(nil,'font')
    assert(O.font.Text:GetScale()<.5 and O.font.Text.font=='late-wide.ttf')
    assert(U.eagle.color[1]==.88 and U.eagle.color[2]==.66 and U.settings.iconKind=='cog')
    O.font.Text.GetUnboundedStringWidth=width;LibStub=original;C.profile.colors.text=color;C:ApplyProfile()
end)
-- Exercise the native failure modes that a successful font probe alone cannot
-- establish: a later control can reject a path or retain its previous face.
local function assertOwnedFamily(path)
    for _,entry in ipairs(U.texts) do
        local actual=entry[1]:GetFont()
        assert(actual==path,'mixed font family: '..tostring(actual)..' instead of '..path)
    end
end
local function withFontLibrary(run)
    local previous,preference,watched=LibStub,C.profile.font,U.fontLibrary
    local callbacks={};local lib={IsValid=function(_,kind,name) return kind=='font' and name=='Expressway' end,
        Fetch=function() return 'review-expressway.ttf' end,List=function() return {'Expressway'} end,
        RegisterCallback=function(_,event,fn) callbacks[event]=fn end}
    LibStub=function() return lib end;C.profile.font='Expressway';C:ApplyProfile()
    run(lib,callbacks)
    LibStub=previous;C.profile.font=preference;U.fontLibrary=watched;C:ApplyProfile()
end

test('one rejected option font downgrades every earlier and later object then recovers',function()
    withFontLibrary(function()
        local target=N.Options.overlays.text;local original=target.SetFont
        for _,silent in ipairs({false,true}) do
            target.SetFont=function(self,path,size,flags)
                if path=='review-expressway.ttf' then return silent end
                return original(self,path,size,flags)
            end
            target.font='previous-face.ttf';C:RefreshAppearance(true)
            assertOwnedFamily(STANDARD_TEXT_FONT)
            assert(C.profile.font=='Expressway','fallback must preserve the saved preference')
            target.SetFont=original;C:RefreshAppearance(true);assertOwnedFamily('review-expressway.ttf')
        end
        target.SetFont=nil
    end)
end)

test('failed selected and default paths converge on inherited native font without aborting options',function()
    withFontLibrary(function()
        local target=N.Options.fontSize;target.SetFont=function() return false end
        target.font='previous-face.ttf';C:RefreshAppearance(true)
        assertOwnedFamily('native')
        for _,entry in ipairs(U.texts) do assert(entry[1].fontObject==GameFontNormal) end
        assert(C.profile.font=='Expressway' and N.Options.fontSize:GetText()==tostring(C.profile.fontSize))
        target.SetFont=nil;C:RefreshAppearance(true);assertOwnedFamily('review-expressway.ttf')
    end)
end)

test('registered but missing font falls back consistently and retries on media change',function()
    withFontLibrary(function(lib,callbacks)
        local path='missing';lib.Fetch=function() return path end;U:WatchFonts()
        assertOwnedFamily(STANDARD_TEXT_FONT);assert(C.profile.font=='Expressway')
        path='repaired-media.ttf';callbacks.LibSharedMedia_SetGlobal(nil,'font')
        assertOwnedFamily('repaired-media.ttf');assert(C.profile.font=='Expressway')
    end)
end)

test('fractional native font heights remain cached across unchanged options and appearance refreshes',function()
    local original=methods.SetFont;local writes=0
    methods.SetFont=function(self,path,size,flags)
        writes=writes+1;local ok=original(self,path,size,flags)
        if ok then self.fontSize=size+.000001 end
        return ok
    end
    withFontLibrary(function()
        assertOwnedFamily('review-expressway.ttf');local before=writes;local generated={}
        for _,d in ipairs(U.dropdowns) do generated[d]=d.generated end
        C:RefreshAppearance(false);N.Options:Refresh();U:RefreshFonts()
        assert(writes==before,'native uiUnit roundoff must not trigger font rewrites or reprobes')
        for _,d in ipairs(U.dropdowns) do assert(d.generated==generated[d],'unchanged options must not rebuild native menus') end
    end)
    methods.SetFont=original;C:RefreshAppearance(true)
end)

test('opening options repairs native dropdown checkbox and edit font resets using readback',function()
    withFontLibrary(function()
        local O=N.Options;O.frame:Hide()
        assert(O.overlays.Text==O.overlays.text,'exercise the native checkbox label')
        local reset={O.font.Text,O.order.Text,O.overlays.Text,O.fontSize,U.menuFont}
        for _,t in ipairs(reset) do t:SetFont('native-widget-reset.ttf',10,'OUTLINE') end
        O:Open();assert(O.frame:IsShown());assertOwnedFamily('review-expressway.ttf')
        assert(O.font.Text.fontSize==12 and O.fontSize.fontSize==12 and O.overlays.Text.fontSize==12)
        O.frame:Hide()
    end)
end)

test('first late SharedMedia library attachment refreshes and refits the complete options dialog',function()
    local O=N.Options;local previous,preference,watched=LibStub,C.profile.font,U.fontLibrary
    local measure=O.font.Text.GetUnboundedStringWidth;local callbacks={}
    O.font.Text.GetUnboundedStringWidth=function(self) return self.font=='late-first.ttf' and 700 or 70 end
    LibStub=nil;U.fontLibrary=nil;C.profile.font='Expressway';C:ApplyProfile()
    assertOwnedFamily(STANDARD_TEXT_FONT);assert(O.font.Text:GetScale()==1)
    local lib={IsValid=function() return true end,Fetch=function() return 'late-first.ttf' end,List=function() return {'Expressway'} end,
        RegisterCallback=function(_,event,fn) callbacks[event]=fn end}
    -- All registrations happened before this addon's ADDON_LOADED event; no
    -- registration callback will rescue a font-only attachment refresh.
    LibStub=function() return lib end;C.events.scripts.OnEvent(nil,'ADDON_LOADED','LateMediaProvider')
    assert(callbacks.LibSharedMedia_Registered and callbacks.LibSharedMedia_SetGlobal)
    assertOwnedFamily('late-first.ttf');assert(O.font.Text:GetScale()<.4)
    O.font.Text.GetUnboundedStringWidth=measure;LibStub=previous;C.profile.font=preference;U.fontLibrary=watched;C:ApplyProfile()
end)

test('native selected dropdown labels follow the new profile before generation',function()
    C:Stop();local O=N.Options;local profile,profiles=C.profile,C.profiles
    local controls={O.font,O.order,O.placement,O.active};local popupFonts={}
    for _,d in ipairs(controls) do
        -- Blizzard keeps generated selection text separately from its fallback.
        -- SetDefaultText alone does not replace a previously selected label.
        d.SetDefaultText=function(self,value)
            self.defaultText=value;self.label=self.selectionText or value;self.Text:SetText(self.label)
        end
        d.GenerateMenu=function(self)
            self.generated=(self.generated or 0)+1;local selections={}
            local root={SetScrollMode=function() end,CreateRadio=function(_,label,selected)
                if selected() then selections[#selections+1]=label end
                return {AddInitializer=function(_,initialize)
                    local text=setmetatable({SetFontObject=function(_,font) popupFonts[#popupFonts+1]=font end},
                        {__index=function(_,key) if key=='SetFont' then error('compositor-owned font cannot be assigned directly') end end})
                    initialize({fontString=text})
                end}
            end}
            self.menu(self,root);self.selectionText=selections[1];self.label=self.selectionText or self.defaultText;self.Text:SetText(self.label)
        end
        d.atcfSelectionValue=nil
    end
    C.profile=N.Model.Copy(profile);C.profile.font='Expressway';C.profile.routeOrder='distance';C.profile.dock='none'
    C.profiles={version=1,active='Before',profiles={Before=C.profile,After=N.Model.Copy(C.profile)}}
    local after=C.profiles.profiles.After;after.font='Arial';after.routeOrder='time';after.dock='right'
    C:BindFilters();C:ApplyProfile();assert(O.font.Text:GetText()=='Expressway' and O.order.Text:GetText()=='Distance')
    assert(O:ProfileAction('SwitchProfile','After'))
    assert(O.font.Text:GetText()=='Arial' and O.order.Text:GetText()=='Estimated time')
    assert(O.placement.Text:GetText()=='Right screen edge' and O.active.Text:GetText()=='After')
    assert(#popupFonts>0);for _,font in ipairs(popupFonts) do assert(font==U.menuFont) end
    for _,d in ipairs(controls) do d.SetDefaultText=nil;d.GenerateMenu=nil;d.selectionText=nil;d.atcfSelectionValue=nil end
    C.profile=profile;C.profiles=profiles;C:BindFilters();C:ApplyProfile()
end)

test('structured compact matches show more rows and scroll all results without changing selection',function()
    C:Stop();C.origin=nil;C.status=nil;C.destination=nil;C.searchOrigin=false;C.profile.fontSize=13;C:ApplyProfile()
    local p=A.Position();C.matches={};C.highlight=1
    for i=1,40 do local goal=N.Model.Copy(p);goal.name='Trainer '..i;goal.role='Warrior Trainer';goal.zone='Ironforge';goal.category='class';goal.x=p.x+1700+i;C.matches[i]=goal end
    C:Refresh();local row=U.rows[1]
    assert(row.name:GetText()=='Trainer 1' and row.name.textColor[1]==1 and row.name.textColor[2]==.82 and row.name.fontFlags=='OUTLINE')
    assert(row.detail:GetText()=='Warrior Trainer • Ironforge' and row.detail.fontSize==12 and row.detail.fontFlags=='OUTLINE')
    assert(row.distance:GetText():match('^Distance: ~1.7k yards %(est%. %d+ minutes%)$'))
    assert(-row.distance.point[3]==-row.detail.point[3]+row.detail:GetHeight()+3 and row:GetHeight()<65)
    assert(U.rows[4].bodyOffset+U.rows[4]:GetHeight()<=U.bodyScroll:GetHeight() and U.rows[40]:IsShown())
    C.highlight=40;C:Refresh();assert(U.bodyScroll:GetVerticalScroll()>0)
    local highlight=C.highlight;U.body.scripts.OnMouseWheel(nil,-1000);assert(C.highlight==highlight)
    assert(U.bodyScroll:GetVerticalScroll()==U.bodyScrollRange)
    U.rows[40].scripts.OnClick();assert(C.destination.name=='Trainer 40');C:Stop();C.destination=nil
end)

test('result distance uses preview origin and flight route ETA retains the planned transport cost',function()
    C:Stop();local saved=C.destinations;local p=A.Position();local near=N.Model.Copy(p);near.x=p.x+1700;near.name='Near preview';near.id='near';near.category='place'
    local far=N.Model.Copy(p);far.x=p.x+10;far.name='Near player';far.id='far';far.category='place'
    C.destinations={near,far};C.origin=N.Model.Copy(near);C.origin.x=near.x-50;C.origin.name='Preview';C:Search('',false);flushSearch()
    assert(C.matches[1]==near and U.rows[1].distance:GetText()=='Distance: ~50 yards (est. <1 minute)')
    C:Search('',true);flushSearch();assert(C.matches[1]==far and U.rows[1].distance:GetText()=='Distance: ~10 yards (est. <1 minute)')
    C.matches=nil;C.origin=nil;local route=N.Routes.Summary({{mode='flight',from=1,to=2,start=p,finish=near,distance=1700,seconds=70}},near,C:Context())
    route.eta=70;C.results={route};C:Refresh();assert(U.rows[1].detail:GetText()=='Est. 1 min • ~1.7k yards' and U.rows[1].itinerary:IsShown())
    assert(U:ListingDistance(nil,nil)=='Distance unavailable' and U:ListingDistance(0,0)=='Distance: ~0 yards (est. <1 minute)')
    C:Stop();C.destinations=saved
end)

test('native resize persists bounded results geometry and ends on release lock or hide',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local p=A.Position();p.name='Resize target';p.role='Trainer';p.zone='Ironforge';C.matches={}
    for i=1,40 do C.matches[i]=p end;C.highlight=1;C.profile.locked=false;C:Refresh()
    assert(U.resizeGrip:IsShown() and U.frame.resizable and U.frame.resizeBounds[1]==280)
    local anchor=U.frame.point;U.resizeGrip.scripts.OnMouseDown(nil,'RightButton');assert(not U.resizing)
    U.resizeGrip.scripts.OnMouseDown(nil,'LeftButton');assert(U.resizing and U.frame.sizing=='BOTTOMRIGHT' and C.profile.dock=='none')
    local height=U.resizeChrome+410;U.frame:SetSize(460,height);U.frame.scripts.OnSizeChanged(U.frame,460,height)
    assert(C.profile.width==460 and C.profile.resultsHeight==410 and U.bodyScroll:GetHeight()==410)
    C:Refresh();assert(U.frame.point==anchor and U.frame:GetWidth()==460 and U.frame:GetHeight()==height,'refresh leaves native sizing geometry alone')
    U.resizeGrip.scripts.OnMouseUp(nil,'LeftButton');assert(not U.resizing and U.frame:GetWidth()==460)
    local loaded=N.Settings.Load(C.profile);assert(loaded.width==460 and loaded.resultsHeight==410)
    U.resizeGrip.scripts.OnMouseDown(nil,'LeftButton');C.profile.locked=true;C:Refresh();assert(not U.resizing and not U.resizeGrip:IsShown())
    U.resizeGrip.scripts.OnMouseDown(nil,'LeftButton');assert(not U.resizing)
    C.profile.locked=false;C:Refresh();U.resizeGrip.scripts.OnMouseDown(nil,'LeftButton');C:ShowPanel(false);assert(not U.resizing)
    for k,v in pairs(saved) do C.profile[k]=v end;C:ShowPanel(true);C:Stop();C:ApplyProfile()
end)

test('header movement survives background refresh and saves release position without snapping back',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local left,top=U.frame.GetLeft,U.frame.GetTop
    C.profile.locked=false;C.profile.dock='none';C:Refresh();U.header.scripts.OnDragStart();assert(U.dragging)
    U.frame:SetPoint('TOPLEFT',UIParent,'TOPLEFT',420,-240);local anchor=U.frame.point
    U.frame.GetLeft=function() return 420 end;U.frame.GetTop=function() return UIParent:GetHeight()/U.frame:GetScale()-240 end
    C:RefreshAppearance(false);C:Refresh();assert(U.dragging and U.frame.point==anchor,'refresh must not restore saved anchors while native move owns them')
    U.header.scripts.OnDragStop();assert(not U.dragging and C.profile.x==420 and C.profile.y==-240 and C.profile.dock=='none' and not C.tucked)
    C:Refresh();assert(U.frame.point[4]==420 and U.frame.point[5]==-240)
    U.frame.GetLeft=left;U.frame.GetTop=top;for k,v in pairs(saved) do C.profile[k]=v end;C:ApplyProfile()
end)

test('navigation typography grows ten percent and compass stays world relative as arrow turns',function()
    C:Stop();local p=A.Position();local goal=N.Model.Copy(p);goal.x=p.x+1000;goal.y=p.y+1000;goal.name='Southwind trainer';goal.id='compass'
    local route=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=N.Model.Distance(p,goal),quality='bearing'}},goal,C:Context())
    C.results={route};C.selected=1;C.origin=nil;C.matches=nil;C.destination=goal;C:Go();C.manualPause=false
    U:Guidance(C,p,{speed=7,facing=0},0);local rotation=U.arrow.rotation
    assert(U.cardinal:GetText()=='NW' and U.cardinal:IsShown() and U.next.textColor[1]==1 and U.next.fontFlags=='OUTLINE')
    assert(math.abs(U.next.fontSize-C.profile.fontSize*1.1)<.0001)
    U:Guidance(C,p,{speed=7,facing=math.pi/2},0);assert(U.cardinal:GetText()=='NW' and U.arrow.rotation~=rotation)
    assert(U.tuck.iconKind=='back');U:SetDock(C,'right',true);assert(U.handle.iconKind=='left');U.handle.scripts.OnClick()
    U.pause.scripts.OnClick();assert(not U.cardinal:IsShown());C:Stop();C.profile.dock='none';C:Refresh()
end)
test('matching bold weight is validated cached and downgraded without losing the regular family',function()
    withFontLibrary(function(lib)
        lib.IsValid=function(_,kind,name) return name=='Expressway' or name=='Expressway Bold' end
        lib.Fetch=function(_,kind,name) return name=='Expressway Bold' and 'expressway-bold.ttf' or 'review-expressway.ttf' end
        C:RefreshAppearance(true)
        assert(U.next.font=='expressway-bold.ttf' and U.next.fontFlags=='' and U.rows[1].detail.font=='expressway-bold.ttf')
        assert(N.Options.font.Text.font=='review-expressway.ttf' and U.remaining.font=='review-expressway.ttf')
        local target=U.rows[3].name;local original=target.SetFont or methods.SetFont
        target.SetFont=function(self,path,size,flags) if path=='expressway-bold.ttf' then return true end;return original(self,path,size,flags) end
        target.font='previous-font';C:RefreshAppearance(true)
        assert(U.next.font=='review-expressway.ttf' and U.next.fontFlags=='OUTLINE' and U.rows[1].detail.font=='review-expressway.ttf')
        assert(N.Options.font.Text.font=='review-expressway.ttf' and C.profile.font=='Expressway')
        target.SetFont=nil;C:RefreshAppearance(true);assert(U.next.font=='expressway-bold.ttf')
    end)
end)

test('editor labels fields action buttons and route action share consistent alignment at supported widths',function()
    C:Stop();local savedWidth=C.profile.width;C.destination=nil;C.status=nil;C.matches={}
    for _,width in ipairs({280,304,460,640}) do
        C.profile.width=width;C:Refresh()
        assert(U.current.point[2]==U.filterButton.point[2] and U.current:GetWidth()==U.filterButton:GetWidth())
        assert(U.current.point[2]+U.current:GetWidth()==width-14 and U.tuck.point[2]==U.current.point[2])
        assert(U.from:GetWidth()==U.to:GetWidth() and U.from.point[2]+U.from:GetWidth()+4==U.current.point[2])
        assert(U.current.point[3]-U.current:GetHeight()/2==U.from.point[3]-U.from:GetHeight()/2)
        assert(U.filterButton.point[3]-U.filterButton:GetHeight()/2==U.to.point[3]-U.to:GetHeight()/2)
        assert(U.fieldLabels[1].point[3]-U.fieldLabels[1]:GetHeight()/2==U.from.point[3]-U.from:GetHeight()/2)
        assert(U.go.point[2]+U.go:GetWidth()/2==width/2 and U.go.text.justifyH=='CENTER')
    end
    C.profile.width=savedWidth;C:Stop();C:Refresh()
end)
test('map and minimap preferences default on migrate explicit opt outs and remain independent',function()
    local S=N.Settings
    local p=S.Load({});assert(p.mapMarkers and p.minimapMarkers)
    p=S.Load({overlays=false});assert(not p.mapMarkers and not p.minimapMarkers)
    p=S.Load({overlays=false,mapMarkers=true});assert(p.mapMarkers and not p.minimapMarkers)
    p=S.Load({mapMarkers=false,minimapMarkers=true});assert(not p.mapMarkers and p.minimapMarkers)
    local savedMap,savedMini=C.profile.mapMarkers,C.profile.minimapMarkers
    N.Options.overlays:SetChecked(false);N.Options.overlays.scripts.OnClick();assert(not C.profile.mapMarkers and C.profile.minimapMarkers)
    N.Options.minimapMarkers:SetChecked(false);N.Options.minimapMarkers.scripts.OnClick();assert(not C.profile.mapMarkers and not C.profile.minimapMarkers)
    C.profile.mapMarkers=savedMap;C.profile.minimapMarkers=savedMini;C:ApplyProfile()
end)

test('selected destination appears before Go on zone and world maps with independent minimap control',function()
    C:Stop();C.destination=nil;C.origin=nil;C.manualPause=false;C.results={}
    local mapID,shown=WorldMapFrame.GetMapID,WorldMapFrame:IsShown();local project=C_Map.GetMapPosFromWorldPos
    local oldMap,oldMini=C.profile.mapMarkers,C.profile.minimapMarkers;C.profile.mapMarkers=true;C.profile.minimapMarkers=true
    local id=1429;WorldMapFrame.GetMapID=function() return id end;WorldMapFrame:Show()
    local p=A.Position();local goal=N.Model.Copy(p);goal.name='Map preview';goal.id='map-preview';goal.x=p.x+20
    C:Choose(goal);local O=N.Overlay;O:Update(C,p,{facing=0,speed=7})
    assert(not C.nav.route and O.destination:IsShown() and O.destination.caption=='Destination: Map preview' and O.mini:IsShown())
    id=947;O:Update(C,p,{facing=0,speed=7});assert(O.destination:IsShown(),'use native projection for the currently viewed map')
    C.profile.minimapMarkers=false;O:Update(C,p,{speed=7});assert(not O.mini:IsShown() and O.destination:IsShown())
    C.profile.minimapMarkers=true;C.profile.mapMarkers=false;O:Update(C,p,{speed=7});assert(O.mini:IsShown() and not O.destination:IsShown())
    C.profile.mapMarkers=true;O:Update(C,nil,{speed=7});assert(O.destination:IsShown() and not O.mini:IsShown(),'map coordinates remain useful while player location is missing')
    O:Update(C,p,{dead=true,speed=7});assert(O.destination:IsShown() and not O.mini:IsShown())
    C_Map.GetMapPosFromWorldPos=function() return 999,CreateVector2D(.5,.5) end
    O:Update(C,p,{speed=7});assert(not O.destination:IsShown(),'never place a fabricated pin on an unsupported map')
    C_Map.GetMapPosFromWorldPos=project;WorldMapFrame.GetMapID=mapID;WorldMapFrame:SetShown(shown)
    C.profile.mapMarkers=oldMap;C.profile.minimapMarkers=oldMini;C.destination=nil;C:Stop()
end)

test('active navigation owns minimap direction while a new destination is previewed on the world map',function()
    C:Stop();C.origin=nil;C.manualPause=false;local p=A.Position();local active=N.Model.Copy(p);active.name='Active';active.id='active-marker';active.x=p.x+30
    local route=N.Routes.Summary({{mode='walk',start=p,finish=active,distance=30,quality='bearing'}},active,C:Context())
    C.results={route};C.destination=active;C.selected=1;C:Go();local O=N.Overlay
    local preview=N.Model.Copy(p);preview.y=p.y+30;preview.name='Preview';C:Choose(preview);O:Update(C,p,{facing=0,speed=7})
    assert(O.destination.caption=='Destination: Preview' and O.icon.rotation==0 and C.nav.route==route)
    C.manualPause=true;O:Update(C,p,{facing=0,speed=7});assert(O.destination:IsShown() and not O.mini:IsShown() and (not O.map or not O.map:IsShown()))
    C.manualPause=false;C.destination=nil;C:Stop()
end)
test('retained marker updates preserve hover visibility and missing canvas clears stale pins',function()
    C:Stop();C.origin=nil;C.manualPause=false;local p=A.Position();local goal=N.Model.Copy(p);goal.name='Stable marker';goal.x=p.x+20;C:Choose(goal)
    local O=N.Overlay;O:Update(C,p,{facing=0,speed=7});assert(O.destination:IsShown() and O.mini:IsShown())
    local hides=0;local tracked={O.destination,O.mini}
    for _,f in ipairs(tracked) do f.Hide=function(self) hides=hides+1;methods.Hide(self) end end
    local allocated=#frames;for _=1,10 do O:Update(C,p,{facing=0,speed=7}) end
    assert(hides==0 and #frames==allocated,'ordinary ticks retain pin visibility and pooled frames')
    local canvasFn=WorldMapFrame.GetCanvas;WorldMapFrame.GetCanvas=function() return nil end
    O:Update(C,p,{facing=0,speed=7});assert(not O.destination:IsShown() and O.mini:IsShown())
    WorldMapFrame.GetCanvas=canvasFn;C.destination=nil;C:Stop();assert(not O.destination:IsShown() and not O.mini:IsShown())
    for _,f in ipairs(tracked) do f.Hide=nil end
end)
test('primary action selects and plans once while origin and category actions stay distinct',function()
    C:Stop();local saved={data=C.data,destinations=C.destinations,filter=C.filter};local p=A.Position()
    local a=N.Model.Copy(p);a.id='action-a';a.name='Action A';a.x=p.x+500;a.category='place'
    local b=N.Model.Copy(a);b.id='action-b';b.name='Action B';b.x=p.x+800
    C.data={nodes={},edges={}};C.destinations={a,b};C.filter={categories={},classes={},professions={}};C.destination=nil;C.origin=nil
    C:Search('Action',false);assert(not U.go.enabled);local generation=C.searchGeneration
    assert(C:PrimaryAction()==nil and C.searchGeneration==generation);flushSearch();C.highlight=2;C:Refresh()
    U.to:SetText('Act');U.to:SetFocus();assert(U.go.text:GetText()=='Find routes' and U.go.enabled);U.go.scripts.OnClick()
    assert(C.destination==b and #C.results==1 and C.results[1].destination==b and not C.nav.route)
    assert(not U.to:HasFocus() and U.to:GetText()==b.name)
    C:Go();local active=C.nav.route;C.compact=false;C:Search('Action A',true);flushSearch()
    U.from:SetText('Act');U.from:SetFocus();assert(U.go.text:GetText()=='Use origin');U.go.scripts.OnClick()
    assert(C.origin==a and C.destination==b and #C.results==0 and C.nav.route==active)
    assert(not U.from:HasFocus() and U.from:GetText()==a.name)
    C:Plan();C:Go();assert(C.origin==nil and C.nav.route==active and C.status:find('Review, then Go',1,true),'preview origin still requires current-location review')
    C:Search('no such origin',true);flushSearch();assert(not U.go.enabled);C:PrimaryAction();assert(C.nav.route==active and not C.origin)
    C:Stop();C.destination=nil;C.filter={categories={place=true},classes={},professions={}}
    C:Search('Action',false);flushSearch();assert(U.go.text:GetText()=='Compare matches');U.go.scripts.OnClick()
    assert(C.destination==nil and #C.results==2 and not C.nav.route)
    C.data=saved.data;C.destinations=saved.destinations;C.filter=saved.filter;C.destination=nil;C.origin=nil;C:Stop()
end)

test('inline and options route order share state without replacing active navigation',function()
    C:Stop();local saved={data=C.data,known=C.character.known,profile=N.Model.Copy(C.profile),filter=C.filter};local p=A.Position()
    local goal=N.Model.Copy(p);goal.id='sort-goal';goal.name='Sort target';goal.x=p.x+1000
    C.data={nodes={[1]=p,[2]=goal},edges={{id=9801,from=1,to=2,start=p,finish=goal,mode='flight',distance=1400}}}
    C.character.known={[1]={state='known'},[2]={state='known'}};C.profile.routeOrder='distance';C.filter={categories={},classes={},professions={}};C.destination=goal;C.origin=nil;C.taxi=nil
    C:Plan();assert(C.results[1].flight==0 and U.routeOrder.value=='distance');C:Go();local active=C.nav.route
    C.compact=false;assert(C:SetRouteOrder('time'));assert(C.results[1].flight>0 and C.nav.route==active)
    assert(U.routeOrder.value=='time' and N.Options.order.value=='time' and U.routeHeading:IsShown())
    local results=C.results;assert(not C:SetRouteOrder('invalid') and C:SetRouteOrder('time') and C.results==results)
    C:SetRouteOrder('distance');assert(C.results[1].flight==0 and C.nav.route==active and U.routeOrder.value=='distance' and N.Options.order.value=='distance')
    C.data=saved.data;C.character.known=saved.known;C.profile=saved.profile;C.filter=saved.filter;C.destination=nil;C:Stop();C:ApplyProfile()
end)

test('route comparison shares only identical destinations and gives legs full width',function()
    C:Stop();local saved=N.Model.Copy(C.profile);C.profile.width=304;C.profile.fontSize=13;C.profile.scale=1;C.profile.resultsHeight=296;C:ApplyProfile()
    local p=A.Position();local goal=N.Model.Copy(p);goal.id='compare-goal';goal.name='Kelv Sternhammer';goal.role='Warrior Trainer';goal.zone='Ironforge';goal.x=p.x+1900
    local start=N.Model.Copy(p);start.name='Thelsamar, Loch Modan';local finish=N.Model.Copy(goal);finish.name='Ironforge, Dun Morogh'
    local direct=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=1900,seconds=360}},goal,C:Context())
    local flight=N.Routes.Summary({{mode='walk',start=p,finish=start,distance=30,seconds=5},{mode='flight',start=start,finish=finish,distance=3700,seconds=120},{mode='walk',start=finish,finish=goal,distance=30,seconds=5}},goal,C:Context())
    C.results={direct,flight,flight};C.matches=nil;C.destination=goal;C.status=nil;C:Refresh()
    assert(U.destinationName:IsShown() and U.destinationName:GetText()==goal.name and U.destinationDetail:GetText()=='Warrior Trainer • Ironforge')
    assert(U.rows[1].name:GetText()=='Walk' and not U.rows[1].itinerary:IsShown() and not U.rows[1].distance:IsShown())
    assert(U.rows[2].name:GetText()=='Walk + fly' and U.rows[2].itinerary:GetText():find('Fly ~2 min: Thelsamar, Loch Modan to Ironforge, Dun Morogh',1,true))
    for _,row in ipairs({U.rows[1],U.rows[2]}) do assert(row.go.point[1]=='TOPRIGHT' and row.go.point[5]==-6) end
    assert(U.rows[2].itinerary:GetWidth()>U.rows[2].name:GetWidth() and -U.rows[2].itinerary.point[3]>=36)
    assert(U.rows[3].bodyOffset+U.rows[3]:GetHeight()<=U.bodyScroll:GetHeight(),'three concise routes fit the default viewport')
    local other=N.Model.Copy(goal);other.id='other-spawn';other.x=goal.x+10
    local distinct=N.Model.Copy(direct);distinct.destination=other;C.results={direct,distinct};C:Refresh()
    assert(not U.destinationName:IsShown() and U.rows[1].name:GetText()==goal.name and U.rows[2].name:GetText()==other.name)
    assert(U.rows[1].detail:GetText()=='Warrior Trainer • Ironforge' and U.rows[1].distance:GetText():find('Walk • Est.',1,true))
    assert(U.current.iconKind=='location' and not U.current.text:IsShown())
    C.profile=saved;C.destination=nil;C:Stop();C:ApplyProfile()
end)

test('wrapped row measurement settles fractional scale before measuring and keeps footer separate',function()
    C:Stop();local saved=N.Model.Copy(C.profile);C.profile.scale=1.25;C.profile.fontSize=13;C.profile.width=304
    local p=A.Position();p.name='Measure target';p.role='Trainer';p.zone='Ironforge';C.matches={};C.highlight=1
    for i=1,40 do C.matches[i]=p end
    C:ApplyProfile();local row=U.rows[1];local scale=row.name:GetEffectiveScale()
    assert(scale==1.25 and row.name:GetHeight()==(math.ceil(13*scale)+2)/scale)
    assert(U.resultsBoundary:IsShown() and -U.go.point[3]>U.bodyTop+U.bodyScroll:GetHeight())
    UIParent:SetSize(1280,540);C.events.scripts.OnEvent(nil,'DISPLAY_SIZE_CHANGED');scale=row.name:GetEffectiveScale()
    assert(scale==U.frame:GetEffectiveScale() and row.name:GetHeight()==(math.ceil(13*scale)+2)/scale)
    assert(U.frame:GetHeight()*scale<=540)
    C.highlight=40;C.profile.width=640;C:Refresh();C.profile.width=280;C.profile.fontSize=18;C:ApplyProfile()
    local selected=U.rows[40];local offset=U.bodyScroll:GetVerticalScroll()
    assert(selected.bodyOffset>=offset and selected.bodyOffset+selected:GetHeight()<=offset+U.bodyScroll:GetHeight()+.001,'reflow reveals the highlighted result')
    U.body.scripts.OnMouseWheel(nil,1);offset=U.bodyScroll:GetVerticalScroll();C:Refresh()
    assert(U.bodyScroll:GetVerticalScroll()==offset,'unchanged layout preserves manual scroll position')
    UIParent:SetSize(1920,1080);C.profile=saved;C:Stop();C:ApplyProfile()
end)
test('width resize rebudgets wrapped headings without pushing content outside the frame',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);C.profile.width=640;C.profile.fontSize=18;C.profile.scale=1;C.profile.locked=false;C:ApplyProfile()
    local p=A.Position();local goal=N.Model.Copy(p);goal.id='resize-wrap';goal.name=string.rep('Long shared destination ',3);goal.x=p.x+500
    local route=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=500,seconds=100}},goal,C:Context())
    C.results={route,route,route};C.destination=goal;C.status=nil;C:Refresh()
    local height=U.frame:GetHeight();local oldChrome=height-U.bodyScroll:GetHeight()
    U.resizeGrip.scripts.OnMouseDown(nil,'LeftButton');U.frame:SetSize(280,height);U.frame.scripts.OnSizeChanged(U.frame,280,height)
    local chrome=U.bodyTop+20
    assert(U.resizeChrome>oldChrome and math.abs(U.resizeChrome-chrome)<.001)
    assert(U.bodyTop+U.bodyScroll:GetHeight()+20<=U.frame:GetHeight()+.001,'rewrapped content stays inside native frame height')
    assert(U.frame.resizeBounds[2]>=chrome+100)
    U.resizeGrip.scripts.OnMouseUp(nil,'LeftButton');C.profile=saved;C.destination=nil;C:Stop();C:ApplyProfile()
end)
test('native icons keep atlas crops aspect ratio and font-independent pooled geometry',function()
    local old=C_Texture
    C_Texture={GetAtlasInfo=function(name) return {width=name=='common-icon-forwardarrow' and 40 or 20,height=20} end}
    local clicks=0;local button=U:Button(U.frame,'test',0,0,26,26,function() clicks=clicks+1 end)
    for _,kind in ipairs({'cog','back','location','filter','left','right'}) do U:Icon(button,kind) end
    assert(button.icons.back.asset=='common-icon-rotateleft' and button.icons.left.asset=='common-icon-backarrow')
    assert(button.icons.cog.texture:GetWidth()==20 and button.icons.location.asset=='Interface\\Minimap\\UI-Minimap-Ping-Center')
    local right=button.icons.right.texture
    assert(right:GetAtlas()=='common-icon-forwardarrow' and right:GetWidth()==18 and right:GetHeight()==9)
    assert(right.coords[1]==.1 and right.coords[4]==.4,'atlas-owned UVs must not be overwritten by full-file coordinates')
    local allocated=#frames;local font=button.text:GetFont()
    for _,scale in ipairs({.5,.9,1,1.25,1.6}) do
        button:SetScale(scale)
        for _,kind in ipairs({'cog','back','location','filter','left','right'}) do
            U:Icon(button,kind);local icon=button.icons[kind]
            assert(icon.texture.desaturated and icon.texture.snap==false and icon.texture.snapBias==0)
            assert(icon:GetWidth()==20 and icon:GetHeight()==20 and icon.point[1]=='CENTER')
            assert(not button.text:IsShown() and button:GetWidth()==26 and button:GetHeight()==26)
        end
    end
    assert(#frames==allocated and button.text:GetFont()==font,'repeated icon/scale changes allocate no frames or fonts')
    assert(button.pushedTexture==button.nativePushed and button.nativePushed.color[4]==.3)
    U.handle.scripts.OnEnter();assert(U.handle.bg.color[1]==U.handle.hoverColor[1] and GameTooltip:GetText()=='Expand navigation')
    U.handle.scripts.OnLeave();assert(U.handle.bg.color[1]==U.handle.normalColor[1])
    button.scripts.OnClick();assert(clicks==1);C_Texture=old
end)

test('native icon fallback resets stale atlas file and direction state',function()
    local old=C_Texture;C_Texture=nil
    local button=U:Button(U.frame,'test',0,0,24,28,function() end)
    U:Icon(button,'left');local icon=button.icons.left;local t=icon.texture
    assert(icon.asset=='Interface\\ChatFrame\\ChatFrameExpandArrow' and t.coords[1]==1 and t.coords[2]==0)
    assert(U:NativeIcon(icon,'right') and t.coords[1]==0 and t.coords[2]==1)
    C_Texture={GetAtlasInfo=function() return {width=20,height=20} end}
    assert(U:NativeIcon(icon,'back') and t:GetAtlas()=='common-icon-rotateleft' and t.coords[1]==.1)
    t.SetAtlas=function() error('unavailable atlas') end
    assert(U:NativeIcon(icon,'left') and not t:GetAtlas() and t.coords[1]==1)
    t.SetAtlas=methods.SetAtlas;C_Texture.GetAtlasInfo=function() return {width=0,height=20} end
    assert(U:NativeIcon(icon,'right') and not t:GetAtlas() and t.coords[1]==0)
    C_Texture.GetAtlasInfo=function() error('unavailable namespace') end
    assert(U:NativeIcon(icon,'left') and t.coords[1]==1)
    C_Texture=old
end)

test('missing native artwork keeps a visible usable action and gear atlas fallback',function()
    local old=C_Texture;local setTexture=methods.SetTexture
    C_Texture={GetAtlasInfo=function() return {width=16,height=16} end}
    methods.SetTexture=function(self,value,...) if value and value:find('Interface\\',1,true) then return false end;return setTexture(self,value,...) end
    local clicks=0;local button=U:Button(U.frame,'test',0,0,26,26,function() clicks=clicks+1 end)
    U:Icon(button,'cog');assert(button.icons.cog.asset=='OptionsIcon-Brown' and not button.text:IsShown())
    U:Icon(button,'location');assert(button.text:IsShown() and button.text:GetText()=='+' and not button.icons.location.texture:IsShown())
    button.scripts.OnClick();assert(clicks==1)
    C_Texture=nil;U:Icon(button,'back');assert(button.text:IsShown() and button.text:GetText()=='<')
    U:Icon(button,'filter');assert(button.text:IsShown() and button.text:GetText()=='F' and not button.icons.filter.texture:IsShown())
    U:Icon(button,'cog');assert(not button.text:IsShown() and button.icons.cog.texture:IsShown())
    methods.SetTexture=setTexture;C_Texture=old
end)
print('PASS runtime scenarios: '..count..'; frames allocated='..#frames)
