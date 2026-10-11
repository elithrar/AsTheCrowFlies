local frames,timers,hooks={},{},{};local now=0
local methods={}
function methods:SetPoint(...) local args={...};self.point=args;if #args==5 then assert(type(args[4])=='number' and type(args[5])=='number','SetPoint requires numeric offsets') end end
function methods:ClearAllPoints() self.point=nil end
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:SetWidth(w) self.w=w end
function methods:SetHeight(h) self.h=h end
function methods:GetWidth() return self.w or 304 end
function methods:GetHeight() return self.h or 28 end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:HookScript(event,fn) self.scripts[event]=fn end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:SetShown(v) self.shown=v end
function methods:IsShown() return self.shown~=false end
function methods:SetText(v) self.text=v end
function methods:GetText() return self.text or '' end
function methods:SetFont(path,size) self.font=path;self.fontSize=size;return path~='missing' end
function methods:GetFont() return self.font or 'native',self.fontSize or 12,'' end
function methods:SetFontObject() self.font='native' end
function methods:SetScale(v) self.scale=v end
function methods:GetScale() return self.scale or 1 end
function methods:GetEffectiveScale() return self:GetScale() end
function methods:GetFrameLevel() return 1 end
function methods:GetLeft() return 20 end
function methods:GetTop() return 600 end
function methods:SetTexture(v) self.texture=v;return true end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetRotation(v) self.rotation=v end
function methods:SetDefaultText(v) self.label=v end
function methods:SetupMenu(fn) self.menu=fn end
function methods:HasFocus() return self.focus==true end
function methods:ClearFocus() self.focus=false end
function methods:SetFocus() self.focus=true end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
local noop={'SetAllPoints','SetJustifyH','SetJustifyV','SetTextColor','SetShadowColor','SetShadowOffset','SetWordWrap','SetAutoFocus','SetMaxLetters','SetTextInsets','HighlightText','SetMovable','EnableMouse','SetClampedToScreen','SetFrameStrata','SetFrameLevel','RegisterForDrag','StartMoving','StopMovingOrSizing','EnableMouseWheel','SetOwner','SetDrawLayer'}
for _,name in ipairs(noop) do methods[name]=function() end end
local function object(name)
    local f=setmetatable({scripts={},events={},name=name},{__index=methods});frames[#frames+1]=f;if name then _G[name]=f end;return f
end
function methods:CreateTexture() return object() end
function methods:CreateFontString() return object() end
function CreateFrame(kind,name,parent,template)
    local f=object(name);f.parent=parent;f.kind=kind
    if kind=='DropdownButton' then f.Text=object() end;return f
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
    U.fold.scripts.OnClick();assert(C.compact);C:Tick();C:Stop();assert(not C.nav.route and not C.compact and not N.Overlay.mini:IsShown())
end)
test('preview origin demands fresh current-location review',function()
    C:Choose(C.destinations[1]);C.origin=N.Model.Copy(C.destinations[1]);C.origin.x=1100;C:Plan();C:Go();assert(not C.nav.route and not C.origin and C.status:find('Recalculated'))
end)
test('category button compares category rather than first autocomplete',function()
    C.destination=nil;C.query='';C.filter={category='place'};C.matches={C.destinations[1]};C.results={};U.go.scripts.OnClick();assert(#C.results==1 and not C.destination and not C.matches)
    C.query='missing';C.results={};U.go.scripts.OnClick();assert(#C.results==0 and not C.destination)
end)
test('minimap retains both coordinates and map pan never changes player state',function()
    C:Choose(C.destinations[1]);C.destination=N.Model.Copy(C.destination);C.destination.x=1100;C.destination.y=2100;C:Plan();C:Go();C:Tick()
    local point=N.Overlay.mini.point;assert(point and type(point[4])=='number' and type(point[5])=='number' and point[5]~=0)
    local before=A.Position();WorldMapFrame.GetMapID=function() return 1430 end;C:Tick();assert(A.Position().x==before.x)
    C.nav.state='unavailable';C.nav.message='Recalculate';GetPlayerFacing=function() return nil end;C:Tick();assert(not U.arrow:IsShown() and U.directionNote:GetText()=='Recalculate')
end)
test('origin reset cancels guidance and restores current',function() U.current.scripts.OnClick();assert(not C.nav.route and not C.origin) end)
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
        [3]={name='No map',subName='Auctioneer',npcFlags=4096,friendlyToFaction='AH',spawns={[999]={{50,50}}}},
    }
    LibQuestieDB={flavor={name='Forever'},RequireContract=function(v) return v==3 end,
        Support={Get=function(key) assert(key=='ZoneDB');return {private={areaIdToUiMapId='return { [12]=1429 }',areaIdToUiMapIdOverride='return {}'}} end},
        Npc={GetAllIds=function() return {1,2,3} end,Get=function(id,key) return records[id][key] end,GetRaw=function(id,key) return key=='subName' and 'Warrior Trainer' end}}
    local state=assert(P.Connect());assert(not P.Step(state,1));assert(state.items[1].class=='MAGE');assert(P.Step(state,5));assert(#state.items==2 and state.items[2].available==false and state.counts.unmapped==1)
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
    C:Edit();C.data={nodes={},edges={}};C.character.known={};C.query='';C.filter={category='all'}
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
    assert(N.Navigation.Target(C.nav).id==1);hooks.TakeTaxiNode(3);onTaxi=true;now=1;C:Tick();assert(C.nav.state=='flying')
    playerY=playerY+.1;onTaxi=false;now=21;C:Tick();assert(C.character.timings['101,102'][1]==20)
    C:Stop();C.data.nodes[999]={id=999,map=0,x=0,y=0,name='Debug test'};C:Reindex()
    for _,d in ipairs(C.destinations) do assert(d.id~=999) end
end)
test('two Enter presses accept then plan without losing focus',function()
    C:Edit();C.filter={category='all'};C.matches={C.destinations[1]};C.highlight=1;C.searchOrigin=false;U.to:SetFocus()
    U.to.scripts.OnEnterPressed();assert(U.to:HasFocus() and C.destination)
    U.to.scripts.OnEnterPressed();assert(not U.to:HasFocus() and #C.results>0)
end)
print('PASS runtime scenarios: '..count..'; frames allocated='..#frames)
