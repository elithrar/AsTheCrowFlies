-- CallbackHandler accepts method names and multiple owners for each event.
local function registerMedia(callbacks, owner, event, callback)
    local previous = callbacks[event]
    callbacks[event] = function(...)
        if previous then previous(...) end
        if type(callback)=="string" then owner[callback](owner, ...) else callback(...) end
    end
end
local callbackErrors={}
function geterrorhandler() return function(message) callbackErrors[#callbackErrors+1]=message end end
local frames,timers,hooks={},{},{};local now=0;local cursorX,cursorY=400,500
local methods={}
function methods:GetParent() return self.parent end
function methods:SetPoint(...) local args={...};self.point=args;self.points=self.points or {};self.points[args[1]]=args;if #args==5 then assert(type(args[4])=='number' and type(args[5])=='number','SetPoint requires numeric offsets') end end
function methods:ClearAllPoints() self.point=nil;self.points={} end
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:SetWidth(w) self.w=w end
function methods:SetHeight(h) self.h=h end
function methods:SetResizable(value) self.resizable=value end
function methods:SetResizeBounds(a,b,c,d) assert(a>0 and b>0 and c>=a and d>=b,'native resize bounds must be positive and ordered');self.resizeBounds={a,b,c,d} end
function methods:StartSizing(point) self.sizing=point end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false;self.sizing=nil;self.stopped=(self.stopped or 0)+1 end
function methods:GetWidth() return self.w or 304 end
function methods:GetHeight()
    if self.h then return self.h end
    if self.kind=='ScrollFrame' and self.points and self.points.TOPLEFT and self.points.BOTTOMRIGHT then
        return self.parent:GetHeight()+self.points.TOPLEFT[3]-self.points.BOTTOMRIGHT[3]
    end
    return 28
end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:HookScript(event,fn) local previous=self.scripts[event];self.scripts[event]=function(...) if previous then previous(...) end;fn(...) end end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:UnregisterEvent(event) self.events[event]=nil end
function methods:UnregisterAllEvents() self.events={} end
function methods:Show() self.showCount=(self.showCount or 0)+1;local changed=self.shown==false;self.shown=true;if changed and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() local changed=self.shown~=false;self.shown=false;if changed and self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown~=false end
function methods:SetText(v,r,g,b,a,wrap)
    self.text=v
    if self.kind=='GameTooltip' and self.TextLeft1 then
        local line=self.TextLeft1;line:SetText(v);line:SetTextColor(r,g,b,a);line:SetWordWrap(wrap)
        -- Native tooltip sizing happens when content is populated; capture the
        -- owned line's font at that point rather than after Show or SetFont.
        local path,size,flags=line:GetFont()
        self.measuredText={path=path,size=size,flags=flags,width=line:GetUnboundedStringWidth(),color={r,g,b,a},wrap=wrap}
    end
end
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
function methods:GetFrameLevel() return self.level or (self.parent and self.parent:GetFrameLevel()+1) or 1 end
function methods:SetFrameLevel(v) self.level=v end
function methods:SetFrameStrata(v) assert(v=='LOW' or v=='MEDIUM' or v=='HIGH' or v=='DIALOG' or v=='TOOLTIP');self.strata=v end
function methods:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or 'MEDIUM' end
function methods:SetTexCoord(...) self.coords={...} end
function methods:IsEnabled() return self.enabled~=false end
function methods:SetEnabled(v)
    local changed=self:IsEnabled()~=v;self.enabled=v
    local script=self.scripts[v and 'OnEnable' or 'OnDisable'];if changed and script then script(self) end
end
function methods:SetAlpha(v) self.alpha=v end
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
function methods:GetValue() return self.value end
function methods:SetValueStep(value) self.valueStep=value end
function methods:SetObeyStepOnDrag(value) self.obeyStep=value end
function methods:SetOrientation(value) self.orientation=value end
function methods:SetHitRectInsets(...) self.hitInsets={...} end
function methods:SetScrollChild(child) self.scrollChild=child end
function methods:SetVerticalScroll(value) self.scroll=value;if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self,value) end end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetLeft() return 20 end
function methods:GetTop() return 600 end
function methods:GetBottom() return self:GetTop()-self:GetHeight() end
function methods:SetTexture(v) self.texture=v;self.atlas=nil;return true end
function methods:SetAtlas(v,useSize,filter,reset,wrapH,wrapV)
    if v:match('^common%-search%-border%-') then
        assert(v=='common-search-border-left' or v=='common-search-border-middle' or v=='common-search-border-right')
    else assert(useSize==false and reset==true and wrapH=='CLAMP' and wrapV=='CLAMP') end
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
function methods:SetDefaultText(v) self.label=v;if self.Text then self.Text:SetText(v) end end
function methods:SetupMenu(fn) self.menu=fn end
function methods:HasFocus() return self.focus==true end
function methods:ClearFocus() self.focus=false end
function methods:SetFocus() self.focus=true end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:SetOwner(owner,anchor) self.tooltipOwner=owner;self.tooltipAnchor=anchor end
function methods:GetOwner() return self.tooltipOwner end
function methods:SetThumbTexture(path) self.thumb=self:CreateTexture();self.thumb:SetTexture(path) end
function methods:GetThumbTexture() return self.thumb end
function methods:SetClampedToScreen(value) self.clamped=value end
local noop={'SetAllPoints','SetShadowColor','SetShadowOffset','SetAutoFocus','SetMaxLetters','SetTextInsets','HighlightText','SetMovable','EnableMouse','RegisterForDrag','EnableMouseWheel','SetDrawLayer'}
for _,name in ipairs(noop) do methods[name]=function() end end
function GetCursorPosition() return cursorX,cursorY end
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
    if template=='BackdropTemplate' then
        -- Backdrop.xml inherits OnBackdropSizeChanged; replacing it leaves the
        -- native border's texture coordinates at the previous frame size.
        f:SetScript('OnSizeChanged',function() f.nativeBackdropSizes=(f.nativeBackdropSizes or 0)+1 end)
    end
    if kind=='DropdownButton' or template=='UICheckButtonTemplate' then f.Text=object();f.Text.parent=f end
    if template=='InputBoxTemplate' then
        for _,key in ipairs({'Left','Middle','Right'}) do f[key]=f:CreateTexture() end
    elseif template=='WowStyle1DropdownTemplate' then
        f.Background=f:CreateTexture();f.Text:SetPoint('TOPLEFT',f,'TOPLEFT',9,-7)
    end
    if template=='SharedTooltipTemplate' then
        f.TextLeft1=object();f.TextLeft1.parent=f;f.TextLeft1:SetFont('native',14,'');f:SetFrameStrata('TOOLTIP');f:Hide()
    end
    return f
end
UIParent=object();UIParent:SetSize(1920,1080);Minimap=object();Minimap:SetSize(180,180)
WorldMapFrame=object();local canvas=object();canvas:SetSize(1000,700)
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetMapID() return 1429 end
GameTooltip=object();GameFontNormal={GetFont=function()return "native",12,"" end};STANDARD_TEXT_FONT='native';SlashCmdList={}
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
Enum={PlayerInteractionType={Item=1,TradePartner=2,Gossip=3,QuestGiver=4,Merchant=5,TaxiNode=6,Trainer=7,Banker=8,Auctioneer=21,StableMaster=22,WorldMap=27}}
C_TaxiMap={GetTaxiNodesForMap=function() return {{nodeID=1,faction=2,isUndiscovered=false},{nodeID=2,faction=2,isUndiscovered=true}} end}
function TakeTaxiNode(slot) end
function hooksecurefunc(target,name,fn)
    if type(target)=='string' then hooks[target]=name;return end
    if target==_G then hooks[name]=fn end
    local original=target[name];target[name]=function(...) local result=original(...);fn(...);return result end
end
local function registered(name)
    for _,frame in ipairs(frames) do if frame.events[name] then return true end end
    return false
end
local function dispatchEvent(name,...)
    for _,frame in ipairs(frames) do
        if frame.events[name] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame,name,...) end
    end
    assert(#callbackErrors==0,callbackErrors[1])
end
local N={};local files={}
for line in io.lines(ROOT..'/AsTheCrowFlies/AsTheCrowFlies.toc') do if line:match('%.lua$') then files[#files+1]=line end end
for _,name in ipairs(files) do assert(loadfile(ROOT..'/AsTheCrowFlies/'..name))('AsTheCrowFlies',N) end
local A,C,U=N.Adapter,N.Core,N.UI;local count=0
local function setPreference(c,path,value)
    local ok,err=c:SetPreferences({[path]=value});assert(ok,err and err.message)
end
local function restorePreferences(c,profile)
    local values={}
    for key,value in pairs(profile) do
        if key=='colors' then for role,color in pairs(value) do values['colors.'..role]=color end
        elseif key~='version' and key~='layoutVersion' and key~='searchFilters' and key~='filters' then values[key]=value end
    end
    for key,value in pairs(N.Settings.FilterPatch(profile.searchFilters)) do values[key]=value end
    assert(c:SetPreferences(values))
end
local function option(owner,page,index)
    assert(owner:Open(page));return assert(owner.panel._pool[page..':1:'..index])
end
local function test(name,fn) local ok,err=pcall(fn);assert(ok,name..': '..tostring(err).." callback: "..tostring(callbackErrors[1]));assert(#callbackErrors==0,callbackErrors[1]);count=count+1 end
test('TOC load and ADDON_LOADED restoration lifecycle',function()
    assert(not C.ready);AsTheCrowFliesDB={version=1,font='Arial',scale=.9};AsTheCrowFliesCharacter={version=1,build='old'}
    dispatchEvent('ADDON_LOADED','AnotherAddon');assert(not C.ready)
    dispatchEvent('ADDON_LOADED','AsTheCrowFlies');assert(C.ready and C.profile.font=='Arial' and C.profile.scale==.9)
    assert(AsTheCrowFliesDB~=C.profile and AsTheCrowFliesDB.font==C.profile.font and AsTheCrowFliesCharacter==C.character)
end)
-- A failed compound geometry edit must not publish half a placement or alias a saved table.
test('settings patches commit once and returned snapshots cannot mutate saved preferences',function()
    local original=N.Model.Copy(C.profile);local notifications=0
    local handle=N.App:OnSettingsChanged(function()notifications=notifications+1 end)
    local ok,err=N.App:SetMany({width=300,scale=0})
    assert(not ok and err.code=='invalid' and C.profile.width==original.width and notifications==0)
    assert(N.App:SetMany({width=300,scale=1.1}));assert(notifications==1 and AsTheCrowFliesDB.width==300 and C.profile.scale==1.1)
    local color=N.App:Get('colors.text');color[1]=0
    assert(AsTheCrowFliesDB.colors.text[1]~=0 and C.profile.colors.text[1]~=0)
    handle:Cancel();restorePreferences(C,original)
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
    dispatchEvent('TAXIMAP_CLOSED');assert(C.results[flightIndex].conditional and C.nav.route.conditional)
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
    C:Stop();C:ShowPanel(true);N.Options.panel:Close()
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
    local commands=SlashCmdList.ASTHECROWFLIES_SND_ATCF;N.Options.frame:Hide();commands('');assert(N.Options.frame:IsShown())
    commands('opts');commands('options');assert(N.Options.frame:IsShown())
    local state=C.nav;commands('hide');C:Tick();assert(not U.frame:IsShown() and not U.handle:IsShown() and C.nav==state)
    commands('show');assert(U.frame:IsShown() and not C.hidden);commands(' OPTIONS ');assert(N.Options.frame:IsShown())
    N.Options.frame:Hide()
end)

test('fonts reach dropdown rows and late SharedMedia registration',function()
    local callbacks={};local lib={Fetch=function(_,_,name) if name=='Expressway' then return 'expressway.ttf' end end,List=function() return {'Expressway'} end,RegisterCallback=function(owner,event,fn) registerMedia(callbacks,owner,event,fn) end}
    LibStub=function() return lib end;setPreference(C,'font','Expressway');dispatchEvent('ADDON_LOADED','Media')
    callbacks.LibSharedMedia_Registered(nil,'font')
    local font=option(N.Options,'appearance',2)
    assert(U.title.font=='expressway.ttf' and font.Text.font=='expressway.ttf' and U.menuFont.font=='expressway.ttf',tostring(U.title.font)..'/'..tostring(font.Text.font)..'/'..tostring(U.menuFont.font)..'/'..N.App:Get('font'))
    local initializers={};local root={SetScrollMode=function() end,AddMenuReleasedCallback=function()end,CreateRadio=function() return {AddInitializer=function(_,fn) initializers[#initializers+1]=fn end} end}
    U.routeOrder.menu(nil,root);local fontString=setmetatable({SetFontObject=function(self,font) self.actual=font end},{__index=function(_,key) if key=='SetFont' then error('compositor SetFont access') end end})
    initializers[1]({fontString=fontString});assert(fontString.actual==U.menuFont)
    local before=#U.texts;U:RefreshFonts();assert(#U.texts==before);LibStub=nil;N.App.fonts:Refresh()
end)

test('SND profile commands preserve character flight knowledge',function()
    C.character.known[87]={state='known'};C.character.timings['87']={60};local character=C.character
    assert(N.App.profiles:Duplicate('Travel'));assert(N.App.profiles:Active()=='Travel' and AsTheCrowFliesDB~=C.profile)
    setPreference(C,'scale',1.1);assert(N.App.profiles:Switch('Default'))
    assert(C.character==character and character.known[87] and character.timings['87'][1]==60)
    assert(N.App.profiles:CopyFrom('Travel'));assert(C.profile.scale==1.1 and N.App.profiles:Active()=='Default')
    assert(N.App.profiles:Reset());assert(C.profile.scale==1 and C.character==character and character.timings['87'][1]==60)
    C:Stop()
end)
local function discoveryFixture()
    C:Stop();C:ShowPanel(true);C.origin=nil;C.taxi=nil;C.matches=nil;C.query='';C.filter={categories={},classes={},professions={}}
    local old={data=C.data,known=C.character.known,destinations=C.destinations,order=C.profile.routeOrder,map=C_TaxiMap.GetTaxiNodesForMap,all=C_TaxiMap.GetAllTaxiNodes,routes=GetNumRoutes,slot=TaxiGetNodeSlot}
    local p=A.Position();C.data={nodes={},edges={}};C.character.known={[201]={state='known'},[203]={state='undiscovered'}};setPreference(C,'routeOrder','distance')
    for i=1,3 do local node=N.Model.Copy(p);node.id=200+i;node.x=p.x+(i-1)*500;node.name='Discovery master '..i;node.category='flight';C.data.nodes[node.id]=node end
    C.data.edges={{id=703,from=201,to=203,start=C.data.nodes[201],finish=C.data.nodes[203],mode='flight',distance=1100}}
    local goal=N.Model.Copy(C.data.nodes[203]);goal.id='discovery-goal';goal.name='Discovery destination';goal.category='place';C.destinations={goal};C:Choose(goal);C:Plan()
    local function cleanup()
        C:Stop();C.taxi=nil;C.destination=nil;C.data=old.data;C.character.known=old.known;C.destinations=old.destinations;setPreference(C,'routeOrder',old.order)
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
    N.Options.panel:Close();ColorPickerFrame=savedPicker
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
    dispatchEvent('TAXIMAP_OPENED')
    local conditional;for _,r in ipairs(C.results) do if r.flight>0 then conditional=r;assert(not r.unavailable and r.conditional) end end;assert(conditional)
    C_TaxiMap.GetAllTaxiNodes=function() return {{nodeID=203,state=0,slotIndex=3}} end
    dispatchEvent('TAXIMAP_OPENED');assert(not C.taxi and U.note:GetText():find('could not be reconciled'))
    for _,r in ipairs(C.results) do assert(not r.unavailable) end
    C_TaxiMap.GetAllTaxiNodes=function() return {{nodeID=201,state=0,slotIndex=1},{nodeID=203,state=1,slotIndex=3}} end
    GetNumRoutes=function() return 1 end;TaxiGetNodeSlot=function(_,_,source) return source and 1 or 3 end
    dispatchEvent('TAXIMAP_OPENED');assert(C.character.known[203].state=='known')
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
    dispatchEvent('TAXIMAP_OPENED');assert(C.character.known[202].state=='undiscovered')
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
    local original=N.Model.Copy(C.profile.colors.text);local button=option(O,'appearance',6)
    button.scripts.OnClick();assert(picker:IsShown())
    picker.rgb={.21,.32,.43};picker.info.swatchFunc()
    assert(C.profile.colors.text[1]==original[1] and U.previewColors.text[1]==.21,'preview must not persist')
    picker:Hide();picker.info.cancelFunc();assert(C.profile.colors.text[1]==original[1])
    button.scripts.OnClick();picker.rgb={.31,.42,.53};picker:Hide();picker.info.swatchFunc()
    assert(C.profile.colors.text[1]==.31 and AsTheCrowFliesDB.colors.text[1]==.31)
    button.scripts.OnClick();picker.rgb={.51,.62,.73};picker.info.swatchFunc();O.panel:Close()
    assert(not picker:IsShown() and C.profile.colors.text[1]==.31 and U.frame.backdropColor[1]==U.theme.colors.surface[1])
    setPreference(C,'colors.text',original);ColorPickerFrame=saved
end)

test('shared color picker takeover never hides another addon or applies stale callbacks',function()
    local O=N.Options;local saved=ColorPickerFrame;ColorPickerFrame=classicPicker();local picker=ColorPickerFrame
    local original=N.Model.Copy(C.profile.colors.background);local button=option(O,'appearance',5)
    button.scripts.OnClick();picker.rgb={.11,.22,.33};picker.info.swatchFunc();local stale=picker.info
    local other={};picker:SetupColorPickerAndShow({r=.6,g=.7,b=.8,extraInfo=other,swatchFunc=function()end})
    stale.swatchFunc();stale.cancelFunc();O.panel:Close()
    assert(picker:IsShown() and picker:GetExtraInfo()==other and C.profile.colors.background[1]==original[1])
    picker:Hide();ColorPickerFrame=saved
end)

test('bounded trainer results retain width across compact state and reflow profile controls',function()
    C:Stop();local previous={width=C.profile.width,scale=C.profile.scale,filter=C.filter,route=C.nav.route,results=C.results}
    local p=A.Position();local goal=N.Model.Copy(p);goal.id='layout-goal';goal.name='A long localized destination name';goal.x=p.x+500
    local route=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=500,quality='bearing'}},goal,C:Context())
    C.filter={categories={class=true},classes={MAGE=true},professions={}};C.results={route,route,route};C.matches=nil;C.nav.route=route;C.nav.leg=1;C.nav.state='walking';setPreference(C,'scale',1.6)
    C.nav.route=nil;C.compact=false;C.status=nil;C:Refresh()
    assert(not U.go:IsShown() and not U.stop:IsShown() and not U.fold:IsShown())
    assert(U.frame:GetHeight()>=U.bodyTop+U.bodyScroll:GetHeight()+22,'results without footer controls retain grip padding')
    C.nav.route=route
    UIParent:SetSize(1280,720)
    for _,width in ipairs({280,320}) do
        setPreference(C,'width',width);C.compact=false;C.status='A route status';C:Refresh()
        local physical=U.frame:GetWidth()*U.frame:GetScale()
        assert(U.frame:GetHeight()*U.frame:GetScale()<=720 and U.rows[3].detail:GetHeight()>0)
        assert(U.header:GetWidth()<U.settings.point[2] and U.settings:GetFrameLevel()>U.header:GetFrameLevel())
        assert(U.from.point[2]+U.from:GetWidth()==width-42 and U.body:GetWidth()==width-28 and U.filterButton.point[2]==width-38)
        assert(U.fold:IsShown() and U.fold.point[2]+U.fold:GetWidth()<U.go.point[2])
        assert(U.rows[1].name:GetWidth()+10<=U.rows[1]:GetWidth()-8-U.rows[1].go:GetWidth())
        C.compact=true;C:Refresh();assert(U.frame:GetWidth()*U.frame:GetScale()==physical)
        U.expand.scripts.OnClick();assert(U.frame:GetWidth()*U.frame:GetScale()==physical and U.fold:IsShown())
    end
    UIParent:SetSize(1920,1080);setPreference(C,'width',previous.width);setPreference(C,'scale',previous.scale);C.filter=previous.filter;C:Stop()
end)

test('open options follows display changes and closes pending confirmation and focus',function()
    local O=N.Options;assert(O:Open('profiles'));local panel=O.panel
    panel._pool['profile-name']:SetFocus();panel._pool['profile-reset'].scripts.OnClick()
    assert(panel._confirm and panel._confirm.kind=='reset')
    UIParent:SetSize(600,400);dispatchEvent('DISPLAY_SIZE_CHANGED')
    assert(panel.frame:GetWidth()*panel.frame:GetScale()<=600 and panel.frame:GetHeight()*panel.frame:GetScale()<=400)
    panel:Close();assert(not panel._confirm and not panel._pool['profile-name']:HasFocus())
    assert(O:Open('profiles'));assert(not panel._confirm)
    UIParent:SetSize(1920,1080);dispatchEvent('UI_SCALE_CHANGED');assert(panel.frame:GetScale()==1);panel:Close()
end)

test('profile switch changes displayed route ordering without replacing active navigation',function()
    C:Stop();local previous={active=N.App.profiles:Active(),profile=C.profile,data=C.data,known=C.character.known,filter=C.filter}
    local p=A.Position();local goal=N.Model.Copy(p);goal.x=p.x+1000;goal.id='profile-goal';goal.name='Profile destination'
    C.data={nodes={[1]=p,[2]=goal},edges={{id=801,from=1,to=2,start=p,finish=goal,mode='flight',distance=1400}}}
    C.character.known={[1]={state='known'},[2]={state='known'}};C.destination=goal;C.origin=nil;C.taxi=nil
    assert(N.App.profiles:Duplicate('Fast'));assert(C:SetPreferences({routeOrder='time',width=320}))
    assert(N.App.profiles:Duplicate('Short'));assert(C:SetPreferences({routeOrder='distance',width=280}))
    C:Plan();assert(C.results[1].flight==0);C:Go();local active=C.nav.route
    assert(N.App.profiles:Switch('Fast'));assert(C.results[1].flight>0 and C.nav.route==active and C.profile.width==320)
    C.destination=nil;C:Stop();C.data=previous.data;C.character.known=previous.known
    assert(N.App.profiles:Switch(previous.active));restorePreferences(C,previous.profile)
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
    assert(U.frame:GetHeight()==139 and not U.body:IsShown() and not U.go:IsShown() and not U.stop:IsShown() and not U.note:IsShown())
    assert(not U.category and not U.specialization and U.filterButton:IsShown())
    U.to:SetFocus();U.to:SetText('mage');U.to.scripts.OnTextChanged(nil,true)
    assert(C.searching and U.frame:GetHeight()>139 and U.body:IsShown())
    U.to.scripts.OnEscapePressed();flushSearch();assert(not C.matches and not C.searching and U.frame:GetHeight()==139 and not U.to:HasFocus())
    U.to:SetFocus();U.to:SetText('bank');U.to.scripts.OnTextChanged(nil,true)
    U.to:SetText('');U.to.scripts.OnTextChanged(nil,true);flushSearch();assert(not C.matches and U.frame:GetHeight()==139 and C.query=='')
    U.to:ClearFocus();C:Refresh();assert(U.to:GetText()=='');C:Plan();assert(#C.results==0 and C.status:find('Choose'))
    U.to:SetText('trainer');U.to.scripts.OnTextChanged(nil,true);C:Stop();flushSearch();assert(not C.matches and not C.searching)
    U.to:ClearFocus();C.query='';C:Refresh()
end)
test('native filter nested checkboxes support OR class defaults reset and repeated changes',function()
    C:BindFilters();C:Filter('all');flushSearch();local menu=filterDescription();assert(menu.scroll==280 and #menu.children==9 and menu.children[1].selected())
    local d=U.filterButton;local icon=d.icons.filter.texture
    assert(d.kind=='DropdownButton' and icon:GetAtlas()=='gamepad-hud-icon-filter' and icon.desaturated)
    assert(icon:GetWidth()==18 and icon:GetHeight()==18 and d:GetWidth()==24 and d:GetHeight()==28 and not d.text:IsShown())
    assert(icon.color[1]==.75 and icon.color[2]==.75 and icon.color[3]==.75 and d.pushedTexture==d.nativePushed)
    d.scripts.OnEnter(d);assert(d.borderColor[1]==U.theme.colors.accent[1] and GameTooltip:GetText()=='Filter destinations')
    d.menuOpen=true;d:TriggerEvent('OnMenuOpen');d.scripts.OnLeave(d);assert(d.borderColor[1]==U.theme.colors.accent[1],'open menu retains its hover edge after pointer leaves')
    d:CloseMenu();assert(d.borderColor[1]==U.theme.colors.border[1])
    d.scripts.OnEnter(d);d.menuOpen=true;d:TriggerEvent('OnMenuOpen');d:CloseMenu();assert(d.borderColor[1]==U.theme.colors.accent[1]);d.scripts.OnLeave(d)
    local classes=menu.children[3];assert(classes.label=='Class trainers' and classes.scroll==280 and #classes.children==10)
    classes.callback();flushSearch();assert(C.filter.categories.class and C.filter.classes.MAGE and classes.selected())
    menu.children[2].callback();flushSearch();assert(C.filter.categories.auction and C.filter.categories.class)
    classes.children[1].callback();flushSearch();assert(not next(C.filter.classes) and classes.children[1].selected())
    classes.children[2].callback();flushSearch();assert(C.filter.classes.WARRIOR)
    local professions=menu.children[4];professions.children[2].callback();flushSearch();assert(C.filter.professions.Alchemy and C.filter.categories.profession)
    local transmog=menu.children[6];assert(transmog.label=='Transmogrifiers' and #transmog.children==0)
    transmog.callback();flushSearch();assert(C.filter.categories.transmog and transmog.selected() and C.profile.searchFilters.categories.transmog)
    assert(icon.color[1]==1 and icon.color[2]==.82 and icon.color[3]==0)
    assert(d.text.textColor[1]==1 and d.text.textColor[2]==.82 and d.text.textColor[3]==0)
    for _=1,4 do menu.children[2].callback();flushSearch() end;assert(C.filter.categories.auction)
    local fontString=object();classes.initializer({fontString=fontString});assert(fontString.fontObject==U.menuFont)
    U.to:SetFocus();U.filterButton.scripts.OnMouseDown();assert(not U.to:HasFocus())
    U.filterButton.menuOpen=true;C:Back();assert(not U.filterButton:IsMenuOpen())
    menu.children[1].callback();flushSearch();assert(not N.Model.HasFilter(C.filter) and not next(C.filter.classes) and not next(C.filter.professions))
    assert(not transmog.selected() and not C.profile.searchFilters.categories.transmog)
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
    local saved={active=N.App.profiles:Active(),profile=C.profile,destinations=C.destinations};C:Stop();C.destination=nil;C.query='';C.origin=nil
    local p=A.Position();local goal=N.Model.Copy(p);goal.x=p.x+100;goal.id='profile-filter';goal.name='Profile place';goal.category='place'
    local trainer=N.Model.Copy(goal);trainer.id='profile-mage';trainer.name='Profile mage';trainer.category='class';trainer.class='MAGE'
    C.destinations={goal,trainer};assert(N.App.profiles:Duplicate('All'));C:Filter('all')
    assert(N.App.profiles:Duplicate('Class'));C:Filter('categories','class');assert(N.App.profiles:Switch('All'))
    C:Choose(goal);C:Plan();C:Go();local active=C.nav.route;C.destination=nil;C:Search('')
    assert(N.App.profiles:Switch('Class'));flushSearch()
    assert(C.filter~=C.profile.searchFilters and C.filter.categories.class and #C.matches==1 and C.matches[1]==trainer and C.nav.route==active)
    C:Filter('categories','auction');flushSearch()
    assert(N.App.profiles:Switch('All'));flushSearch();assert(#C.matches==2 and not N.Model.HasFilter(C.filter) and C.nav.route==active)
    C:Stop();C.destinations=saved.destinations;assert(N.App.profiles:Switch(saved.active));restorePreferences(C,saved.profile)
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
    local actions={};local root={SetScrollMode=function() end,AddMenuReleasedCallback=function()end,CreateRadio=function(_,label,selected,choose)
        actions[label]=function()choose(({['Right screen edge']='right',['Left screen edge']='left',['Free (dragged)']='none'})[label])end;return {AddInitializer=function() end}
    end}
    option(O,'position',2).menu(nil,root);actions['Right screen edge']()
    assert(C.profile.dock=='right' and C.tucked and U.handle:IsShown() and not U.frame:IsShown() and C.nav==state)
    assert(U.handle.point[1]=='TOPRIGHT');U.handle.scripts.OnMouseDown(U.handle,'LeftButton');U.handle.scripts.OnClick();assert(not C.tucked and U.frame:IsShown())
    setPreference(C,'locked',true);local x,y=C.profile.x,C.profile.y
    U.header.scripts.OnDragStart();U.header.scripts.OnDragStop()
    assert(not C.tucked and C.profile.dock=='right' and C.profile.x==x and C.profile.y==y,'locked drag is inert')
    local oldLeft=U.frame.GetLeft;setPreference(C,'locked',false)
    for _,side in ipairs({'left','right','none'}) do
        if C.tucked then U.handle.scripts.OnMouseDown(U.handle,'LeftButton');U.handle.scripts.OnClick() end
        U.frame.GetLeft=function() return side=='left' and 8 or side=='right' and UIParent:GetWidth()/U.frame:GetScale()-C.profile.width-8 or 200 end
        U.header.scripts.OnDragStart();U.header.scripts.OnDragStop()
        assert(C.profile.dock==side and C.tucked==(side~='none') and C.nav==state)
    end
    U.frame.GetLeft=oldLeft
    restorePreferences(C,saved)
    C:ShowPanel(true);C:RefreshAppearance()
end)

test('SND controls change island typography without changing fixed chrome sizes',function()
    local O=N.Options;local size,scale=C.profile.fontSize,C.profile.scale
    local font=option(O,'appearance',2);local slider=option(O,'appearance',3)
    slider:SetValue(18)
    assert(C.profile.fontSize==18 and U.rows[1].name.fontSize==18 and font.Text.fontSize==13 and U.menuSave.text.fontSize==12)
    assert(U.menuSave.text:GetUnboundedStringWidth()<=U.menuSave.text:GetWidth())
    option(O,'appearance',4):SetValue(1.25);assert(C.profile.scale==1.25)
    assert(not N.App:Set('fontSize',99));assert(C.profile.fontSize==18)
    local sanitized=N.Settings.Load({fontSize=0/0});assert(sanitized.fontSize==13)
    assert(C:SetPreferences({fontSize=size,scale=scale}))
end)

test('long names and flight descriptions grow and scroll without shrinking the island',function()
    C:Stop();local width,size,scale=C.profile.width,C.profile.fontSize,C.profile.scale
    setPreference(C,'width',280);setPreference(C,'fontSize',18);setPreference(C,'scale',1.6);C:RefreshAppearance();UIParent:SetSize(1280,720)
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
    UIParent:SetSize(1280,540);dispatchEvent('DISPLAY_SIZE_CHANGED')
    assert(U.frame:GetHeight()*U.frame:GetScale()<=540 and U.scrollRail:IsShown())
    C.nav.route=nil;goal.category='place';C.matches={goal,goal,goal};C.highlight=1;C:Refresh();C.highlight=3;C:Refresh()
    assert(U.bodyScroll:GetVerticalScroll()>0 and U.bodyScroll:GetVerticalScroll()<=U.rows[3].bodyOffset)
    UIParent:SetSize(1920,1080);setPreference(C,'width',width);setPreference(C,'fontSize',size);setPreference(C,'scale',scale);C:Stop();C:RefreshAppearance()
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
    assert(C.compact and U.frame:GetHeight()<190 and U.pause.iconKind=='pause' and U.stop.iconKind=='close')
    C.nav.dwell=1;C.nav.previous=p;C.nav.previousTime=1;U.pause.scripts.OnClick()
    assert(C.manualPause and U.pause.iconKind=='play' and not C.nav.dwell and not C.nav.previous)
    U.pause.scripts.OnClick();assert(not C.manualPause and U.pause.iconKind=='pause')
    U.stop.scripts.OnClick();assert(not C.nav.route and not U.stop:IsShown());GetPlayerFacing=facing
end)

test('late media registration refits options and custom text color leaves native menus legible',function()
    local original=LibStub;local callbacks={}
    local lib={Fetch=function(_,_,name) if name=='Expressway' then return 'late-wide.ttf' end end,List=function()return {'Expressway'}end,RegisterCallback=function(owner,event,fn)registerMedia(callbacks,owner,event,fn)end}
    local color=N.Model.Copy(C.profile.colors.text);setPreference(C,'colors.text',{.2,.3,.4})
    local font=option(N.Options,'appearance',2);assert(U.menuFont.textColor[1]~=.2 and font.Text.textColor[1]~=.2)
    LibStub=function()return lib end;dispatchEvent('ADDON_LOADED','Media');callbacks.LibSharedMedia_Registered(nil,'font')
    assert(font.Text.font=='late-wide.ttf' and font.Text:GetScale()==1 and U.title.font=='late-wide.ttf')
    assert(U.eagle.color[1]==.88 and U.eagle.color[2]==.66)
    LibStub=original;N.App.fonts:Refresh();setPreference(C,'colors.text',color)
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
    local previous,preference=LibStub,C.profile.font
    local callbacks={};local lib={IsValid=function(_,kind,name) return kind=='font' and name=='Expressway' end,
        Fetch=function(_,_,name) if name=='Expressway' then return 'review-expressway.ttf' end end,List=function() return {'Expressway'} end,
        RegisterCallback=function(owner,event,fn) registerMedia(callbacks,owner,event,fn) end}
    LibStub=function() return lib end;setPreference(C,'font','Expressway');dispatchEvent('ADDON_LOADED','Media');N.App.fonts:Refresh()
    run(lib,callbacks)
    LibStub=previous;N.App.fonts:Refresh();setPreference(C,'font',preference)
end

test('one rejected consumer font downgrades every earlier and later object then recovers',function()
    withFontLibrary(function(_,callbacks)
        local target=U.rows[1].detail;local original=target.SetFont
        for _,silent in ipairs({false,true}) do
            target.SetFont=function(self,path,size,flags)
                if path=='review-expressway.ttf' then return silent end
                return original(self,path,size,flags)
            end
            target.font='previous-face.ttf';N.App.fonts:Refresh()
            assertOwnedFamily(STANDARD_TEXT_FONT)
            assert(C.profile.font=='Expressway','fallback must preserve the saved preference')
            target.SetFont=original;callbacks.LibSharedMedia_Registered(nil,'font');assertOwnedFamily('review-expressway.ttf')
        end
        target.SetFont=nil
    end)
end)

test('failed selected and default paths converge on inherited native font without aborting options',function()
    withFontLibrary(function(_,callbacks)
        local target=U.from;target.SetFont=function() return false end
        target.font='previous-face.ttf';N.App.fonts:Refresh()
        assertOwnedFamily('native')
        for _,entry in ipairs(U.texts) do assert(entry[1].fontObject==GameFontNormal) end
        assert(C.profile.font=='Expressway' and U.frame)
        target.SetFont=nil;callbacks.LibSharedMedia_Registered(nil,'font');assertOwnedFamily('review-expressway.ttf')
    end)
end)

test('registered but missing font falls back consistently and retries on media change',function()
    withFontLibrary(function(lib,callbacks)
        local path='missing';lib.Fetch=function(_,_,name) if name=='Expressway' then return path end end;N.App.fonts:Refresh()
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
        C:RefreshAppearance(false);N.Options.panel:Refresh();U:RefreshFonts()
        assert(writes==before,'native uiUnit roundoff must not trigger font rewrites or reprobes')
        for _,d in ipairs(U.dropdowns) do assert(d.generated==generated[d],'unchanged options must not rebuild native menus') end
    end)
    methods.SetFont=original;N.App.fonts:Refresh()
end)

test('opening options repairs native dropdown checkbox and edit font resets using readback',function()
    withFontLibrary(function()
        local O=N.Options;local font=option(O,'appearance',2);local checkbox=option(O,'navigation',2)
        local label=O.panel._texts['navigation:1:2:label'];local reset={font.Text,label,O.panel._menuFont}
        for _,text in ipairs(reset) do text:SetFont('native-widget-reset.ttf',10,'OUTLINE') end
        O.panel:Close();assert(O:Open('navigation'));assert(label.font=='review-expressway.ttf' and not checkbox.Text:IsShown())
        assert(O:Open('appearance'));assert(font.Text.font=='review-expressway.ttf' and O.panel._menuFont.font=='review-expressway.ttf')
        O.panel:Close()
    end)
end)

test('first late SharedMedia library attachment refreshes and refits the complete options dialog',function()
    local previous=LibStub;local callbacks={};LibStub=nil;setPreference(C,'font','Expressway');N.App.fonts:Refresh()
    assertOwnedFamily(STANDARD_TEXT_FONT)
    local font=option(N.Options,'appearance',2)
    local lib={Fetch=function(_,_,name) if name=='Expressway' then return 'late-first.ttf' end end,List=function()return {'Expressway'}end,RegisterCallback=function(owner,event,fn)registerMedia(callbacks,owner,event,fn)end}
    LibStub=function()return lib end;dispatchEvent('ADDON_LOADED','LateMediaProvider')
    assert(callbacks.LibSharedMedia_Registered and callbacks.LibSharedMedia_SetGlobal)
    assertOwnedFamily('late-first.ttf');assert(font.Text.font=='late-first.ttf' and font.Text:GetScale()==1)
    LibStub=previous;N.App.fonts:Refresh()
end)

test('native selected dropdown labels follow the new profile before generation',function()
    local saved={active=N.App.profiles:Active(),profile=C.profile};local O=N.Options
    assert(N.App.profiles:Duplicate('After'));assert(C:SetPreferences({font='Arial',routeOrder='time',dock='right'}))
    assert(N.App.profiles:Switch(saved.active));local font=option(O,'appearance',2)
    assert(N.App.profiles:Switch('After'));assert(font.Text:GetText()=='Arial')
    local order=option(O,'navigation',1);assert(order.Text:GetText()=='Estimated time')
    local dock=option(O,'position',2);assert(dock.Text:GetText()=='Right screen edge')
    assert(O:Open('profiles'));assert(O.panel._pool['profile-select'].Text:GetText()=='After')
    assert(N.App.profiles:Switch(saved.active));restorePreferences(C,saved.profile)
end)

test('structured compact matches show more rows and scroll all results without changing selection',function()
    C:Stop();local saved=N.Model.Copy(C.profile);C.origin=nil;C.status=nil;C.destination=nil;C.searchOrigin=false;setPreference(C,'width',304);setPreference(C,'fontSize',13);C:RefreshAppearance()
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
    U.rows[40].scripts.OnClick();assert(C.destination.name=='Trainer 40');C:Stop();C.destination=nil;restorePreferences(C,saved);C:RefreshAppearance()
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
    for i=1,40 do C.matches[i]=p end;C.highlight=1;setPreference(C,'locked',false);C:Refresh()
    assert(U.resizeGrip:IsShown() and U.frame.resizable and U.frame.resizeBounds[1]==220)
    local anchor=U.frame.point;U.resizeGrip.scripts.OnMouseDown(nil,'RightButton');assert(not U.resizing)
    U.resizeGrip.scripts.OnMouseDown(nil,'LeftButton');assert(U.resizing and U.frame.sizing=='BOTTOMRIGHT' and C.profile.dock=='none')
    local height=U.resizeChrome+410;U.frame:SetSize(460,height);U.frame.scripts.OnSizeChanged(U.frame,460,height)
    assert(C.profile.width==460 and C.profile.resultsHeight==410 and U.bodyScroll:GetHeight()==410)
    C:Refresh();assert(U.frame.point==anchor and U.frame:GetWidth()==460 and U.frame:GetHeight()==height,'refresh leaves native sizing geometry alone')
    U.resizeGrip.scripts.OnMouseUp(nil,'LeftButton');assert(not U.resizing and U.frame:GetWidth()==460)
    local loaded=N.Settings.Load(C.profile);assert(loaded.width==460 and loaded.resultsHeight==410)
    U.resizeGrip.scripts.OnMouseDown(nil,'LeftButton');setPreference(C,'locked',true);C:Refresh();assert(not U.resizing and not U.resizeGrip:IsShown())
    U.resizeGrip.scripts.OnMouseDown(nil,'LeftButton');assert(not U.resizing)
    setPreference(C,'locked',false);C:Refresh();U.resizeGrip.scripts.OnMouseDown(nil,'LeftButton');C:ShowPanel(false);assert(not U.resizing)
    restorePreferences(C,saved);C:ShowPanel(true);C:Stop();C:RefreshAppearance()
end)

test('idle empty and compact views resize width without changing remembered results height',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local oldFilter=C.filter
    setPreference(C,'locked',false);setPreference(C,'width',240);setPreference(C,'resultsHeight',417);setPreference(C,'fontSize',13);setPreference(C,'scale',1)
    C.destination=nil;C.origin=nil;C.query='';C.status=nil;C.searchOrigin=false;C.filter={categories={},classes={},professions={}};C:RefreshAppearance()
    local function resize(width)
        C:Refresh();assert(U.resizeGrip:IsShown(),'every unlocked panel view exposes its grip')
        local height=U.frame:GetHeight();local results=C.profile.resultsHeight
        U.resizeGrip.scripts.OnMouseDown(U.resizeGrip,'LeftButton');assert(U.resizing and U.frame.sizing=='RIGHT')
        U.frame:SetSize(width,height);U.frame.scripts.OnSizeChanged(U.frame,width,height)
        assert(C.profile.width==width and C.profile.resultsHeight==results,'width-only gestures preserve the results preference')
        U.resizeGrip.scripts.OnMouseUp(U.resizeGrip,'LeftButton');assert(not U.resizing and U.frame:GetWidth()==width)
        assert(N.Settings.Load(C.profile).width==width and U.frame:GetHeight()<300,'hidden results viewport cannot inflate compact states')
    end
    resize(220);assert(U.frame:GetHeight()==139 and not U.go:IsShown())
    assert(U.frame:GetHeight()-19>=45-U.filterButton.point[3]+U.filterButton:GetHeight(),'idle grip clears the filter row')
    C.matches={};C.status='No matching destinations';resize(260);assert(U.go:IsShown() and U.note:IsShown())
    local p=A.Position();local goal=N.Model.Copy(p);goal.id='always-resize';goal.name='Kelv Sternhammer';goal.x=p.x+500
    C.matches=nil;C.destination=goal;C.results={N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=500,seconds=90}},goal,C:Context())};C:Go()
    resize(230);assert(C.compact and U.stop:IsShown())
    assert(U.frame:GetHeight()-19>=-U.stop.point[3]+U.stop:GetHeight(),'compact grip clears the stop action')
    local compactWidth=C.profile.width;U.expand.scripts.OnClick();assert(U.frame:GetWidth()==compactWidth)
    setPreference(C,'locked',true);C:Refresh();assert(not U.resizeGrip:IsShown());U.resizeGrip.scripts.OnMouseDown(U.resizeGrip,'LeftButton');assert(not U.resizing)
    restorePreferences(C,saved);C.filter=oldFilter;C.destination=nil;C:Stop();C:RefreshAppearance()
end)

test('edge tab drags vertically in physical pixels without expanding and restores its preference',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local parentScale=UIParent:GetScale();local oldX,oldY=cursorX,cursorY
    setPreference(C,'locked',false);setPreference(C,'width',240)
    for _,scale in ipairs({.5,1,1.6}) do for _,side in ipairs({'left','right'}) do
        UIParent:SetScale(.75);setPreference(C,'scale',scale);setPreference(C,'dockPosition',.5);C:RefreshAppearance();U:SetDock(C,side,true)
        local handle=U.handle;local beforeX=handle.point[4];local beforeY=handle.point[5]
        local travel=UIParent:GetHeight()*UIParent:GetEffectiveScale()-handle:GetHeight()*handle:GetEffectiveScale()
        cursorX,cursorY=400,500;handle.scripts.OnMouseDown(handle,'LeftButton');handle.scripts.OnDragStart(handle,'LeftButton');assert(U.handleDrag)
        cursorX,cursorY=900,500+travel*.2;handle.scripts.OnUpdate(handle,.016)
        assert(math.abs(C.profile.dockPosition-.3)<.0001 and C.tucked)
        assert(handle.point[4]==beforeX and handle.point[5]>beforeY,'horizontal cursor movement cannot move the tab off its edge')
        C:RefreshAppearance(false);assert(U.handleDrag and math.abs(C.profile.dockPosition-.3)<.0001)
        cursorY=1e6;handle.scripts.OnUpdate(handle,.016);assert(C.profile.dockPosition==0 and handle.point[5]==0)
        cursorY=-1e6;handle.scripts.OnUpdate(handle,.016);assert(C.profile.dockPosition==1)
        assert(math.abs((-handle.point[5]+handle:GetHeight())*handle:GetEffectiveScale()-UIParent:GetHeight()*UIParent:GetEffectiveScale())<.0001,'whole tab stays within screen bounds')
        handle.scripts.OnDragStop(handle);handle.scripts.OnMouseUp(handle,'LeftButton');handle.scripts.OnClick(handle,'LeftButton')
        assert(not U.handleDrag and C.tucked and handle:IsShown(),'release after dragging must not also expand')
        handle.scripts.OnMouseDown(handle,'LeftButton');handle.scripts.OnMouseUp(handle,'LeftButton');handle.scripts.OnClick(handle,'LeftButton')
        assert(not C.tucked and U.frame:IsShown(),'the next genuine click still expands')
        U:SetDock(C,side,true);local position=handle.point[5];assert(C.profile.dockPosition==1)
        restorePreferences(C,N.Settings.Load(C.profile));C:RefreshAppearance();U:SetDock(C,side,true);assert(C.profile.dockPosition==1 and handle.point[5]==position)
    end end
    UIParent:SetScale(parentScale);cursorX,cursorY=oldX,oldY;restorePreferences(C,saved);C:ShowPanel(true);C:RefreshAppearance()
end)

test('edge drag handles unavailable cursor locking hiding side changes and profile replacement',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local cursor=GetCursorPosition;local oldX,oldY=cursorX,cursorY;local parentScale=UIParent:GetScale()
    setPreference(C,'locked',false);setPreference(C,'dockPosition',.4);C:RefreshAppearance();U:SetDock(C,'right',true)
    local handle=U.handle
    local function begin()
        cursorX,cursorY=300,500;handle.scripts.OnMouseDown(handle,'LeftButton');handle.scripts.OnDragStart(handle,'LeftButton');assert(U.handleDrag)
    end
    GetCursorPosition=function() return nil,nil end;handle.scripts.OnMouseDown(handle,'LeftButton');handle.scripts.OnDragStart(handle,'LeftButton')
    assert(not U.handleDrag and C.profile.dockPosition==.4);GetCursorPosition=cursor
    begin();GetCursorPosition=function() return nil,nil end;handle.scripts.OnUpdate(handle,.016);assert(C.profile.dockPosition==.4);GetCursorPosition=cursor
    handle.scripts.OnMouseUp(handle,'LeftButton');assert(not U.handleDrag)
    begin();setPreference(C,'locked',true);C:Refresh();assert(not U.handleDrag)
    local locked=C.profile.dockPosition;handle.scripts.OnMouseDown(handle,'LeftButton');handle.scripts.OnDragStart(handle,'LeftButton');assert(not U.handleDrag and C.profile.dockPosition==locked)
    setPreference(C,'locked',false);C:Refresh();begin();C:ShowPanel(false);assert(not U.handleDrag)
    C:ShowPanel(true);U:SetDock(C,'right',true);begin();U:SetDock(C,'left',true);assert(not U.handleDrag and C.profile.dock=='left')
    begin();local position=C.profile.dockPosition;UIParent:SetScale(.8);dispatchEvent('UI_SCALE_CHANGED')
    assert(not U.handleDrag and C.profile.dockPosition==position,'a screen scale change cancels the old physical-pixel gesture')
    UIParent:SetScale(parentScale);C:RefreshAppearance()
    begin();local prior=C.profile;assert(N.App.profiles:Duplicate('HandleReplacement'));setPreference(C,'dockPosition',.8)
    cursorY=800;local update=handle.scripts.OnUpdate;if update then update(handle,.016) end
    assert(not U.handleDrag and C.profile.dockPosition==.8 and prior.dockPosition~=.8,'profile changes cannot receive an old gesture')
    GetCursorPosition=cursor;cursorX,cursorY=oldX,oldY;restorePreferences(C,saved);C:ShowPanel(true);C:RefreshAppearance()
end)

test('profile frame layer updates panel and tab while menus remain above both',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local O=N.Options;assert(O:Open('position'))
    for _,value in ipairs({'LOW','MEDIUM','HIGH'}) do
        setPreference(C,'strata',value)
        assert(U.frame:GetFrameStrata()==value and U.handle:GetFrameStrata()==value)
        assert(U.frame:GetFrameLevel()==100 and U.handle:GetFrameLevel()==100)
        assert(U.settings:GetFrameLevel()>U.header:GetFrameLevel() and U.resizeGrip:GetFrameLevel()>U.frame:GetFrameLevel())
        assert(U.menu:GetFrameStrata()=='DIALOG' and O.frame:GetFrameStrata()=='DIALOG')
        U:SetDock(C,'right',true);assert(U.handle:GetFrameStrata()==value);U.handle.scripts.OnMouseDown(U.handle,'LeftButton');U.handle.scripts.OnClick();assert(U.frame:GetFrameStrata()==value)
    end
    restorePreferences(C,saved);C:ShowPanel(true)
end)

test('open options placement follows docking resizing and header drags including generated selections',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local d=option(N.Options,'position',2);local left=U.frame.GetLeft
    setPreference(C,'locked',false);U:SetDock(C,'none',false);assert(d.Text:GetText()=='Free (dragged)')
    U:SetDock(C,'right',true);assert(d.Text:GetText()=='Right screen edge')
    U.handle.scripts.OnMouseDown(U.handle,'LeftButton');U.handle.scripts.OnClick()
    U.resizeGrip.scripts.OnMouseDown(U.resizeGrip,'LeftButton');local height=U.frame:GetHeight()
    U.frame:SetSize(260,height);U.frame.scripts.OnSizeChanged(U.frame,260,height);U.resizeGrip.scripts.OnMouseUp(U.resizeGrip,'LeftButton')
    assert(d.Text:GetText()=='Free (dragged)')
    U.frame.GetLeft=function()return 8 end;U.header.scripts.OnDragStart();U.header.scripts.OnDragStop();assert(d.Text:GetText()=='Left screen edge')
    U.frame.GetLeft=left;restorePreferences(C,saved);C:ShowPanel(true);N.Options.panel:Close()
end)

test('narrow large-font navigation wraps its header and footer without covering other controls',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local filter=C.filter;setPreference(C,'width',220);setPreference(C,'fontSize',18);setPreference(C,'scale',1.6);setPreference(C,'locked',false);C:RefreshAppearance()
    local p=A.Position();local goal=N.Model.Copy(p);goal.id='narrow-nav';goal.name='A narrow destination';goal.x=p.x+500
    C.results={N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=500,seconds=90}},goal,C:Context())};C.destination=goal;C.matches=nil;C:Go()
    local function naturalHeight(text)
        local bound=text:GetHeight();text:SetHeight(0);local height=text:GetStringHeight();text:SetHeight(bound);return height
    end
    assert(U.title.wordWrap and U.title:GetHeight()<=32 and naturalHeight(U.title)<=U.title:GetHeight())
    assert(U.expand.text.wordWrap and U.expand:GetHeight()>28 and naturalHeight(U.expand.text)<=U.expand.text:GetHeight())
    assert(U.expand.point[2]+U.expand:GetWidth()<=U.pause.point[2]-6 and U.frame:GetHeight()>=-U.expand.point[3]+U.expand:GetHeight()+22)
    C.compact=false;C.destination=nil;C.matches={goal};C.searchOrigin=false;C.filter={categories={place=true},classes={},professions={}};C:Refresh()
    assert(U.go.text:GetText()=='Compare matches' and U.go.text.wordWrap and U.go:GetHeight()>30)
    assert(U.fold.point[2]+U.fold:GetWidth()+10<=U.go.point[2] and U.go.point[2]+U.go:GetWidth()<=U.stop.point[2]-8)
    assert(naturalHeight(U.go.text)<=U.go.text:GetHeight() and U.frame:GetHeight()>=-U.go.point[3]+U.go:GetHeight()+22)
    restorePreferences(C,saved);C.filter=filter;C.destination=nil;C:Stop();C:RefreshAppearance()
end)

test('header movement survives background refresh and saves release position without snapping back',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local left,top=U.frame.GetLeft,U.frame.GetTop
    setPreference(C,'locked',false);setPreference(C,'dock','none');C:Refresh();U.header.scripts.OnDragStart();assert(U.dragging)
    U.frame:SetPoint('TOPLEFT',UIParent,'TOPLEFT',420,-240);local anchor=U.frame.point
    U.frame.GetLeft=function() return 420 end;U.frame.GetTop=function() return UIParent:GetHeight()/U.frame:GetScale()-240 end
    C:RefreshAppearance(false);C:Refresh();assert(U.dragging and U.frame.point==anchor,'refresh must not restore saved anchors while native move owns them')
    U.header.scripts.OnDragStop();assert(not U.dragging and C.profile.x==420 and C.profile.y==-240 and C.profile.dock=='none' and not C.tucked)
    C:Refresh();assert(U.frame.point[4]==420 and U.frame.point[5]==-240)
    U.frame.GetLeft=left;U.frame.GetTop=top;restorePreferences(C,saved);C:RefreshAppearance()
end)

test('header movement cancels immediately on hide lock or tuck without a stale release docking',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local left,top=U.frame.GetLeft,U.frame.GetTop
    C.destination=nil;C.matches=nil;C.query='';C.status=nil
    U.frame.GetLeft=function() return 420 end;U.frame.GetTop=function() return UIParent:GetHeight()/U.frame:GetScale()-240 end
    local function begin()
        setPreference(C,'locked',false);U:SetDock(C,'none',false);C:ShowPanel(true);U.header.scripts.OnDragStart()
        assert(U.dragging and U.frame.moving)
    end
    begin();local stopped=U.frame.stopped or 0;C:ShowPanel(false)
    assert(not U.dragging and not U.frame.moving and not U.frame:IsShown() and U.frame.stopped>stopped,'hide cancels native motion before layout can early-return')
    U.header.scripts.OnDragStop();assert(not C.tucked and C.profile.dock=='none')
    begin();stopped=U.frame.stopped;setPreference(C,'locked',true);C:RefreshAppearance()
    assert(not U.dragging and not U.frame.moving and U.frame.stopped>stopped,'locking stops native movement immediately')
    local x,y=C.profile.x,C.profile.y;U.header.scripts.OnDragStop();assert(C.profile.x==x and C.profile.y==y and not C.tucked)
    begin();U:SetDock(C,'right',true)
    assert(not U.dragging and not U.frame.moving and C.tucked and U.handle:IsShown() and not U.frame:IsShown())
    U.header.scripts.OnDragStop();assert(C.profile.dock=='right' and C.tucked)
    U.frame.GetLeft=left;U.frame.GetTop=top;restorePreferences(C,saved);C:ShowPanel(true);C:RefreshAppearance()
end)

test('profile switch during a header drag preserves the replacement placement and layer',function()
    C:Stop();C:ShowPanel(true);local profile=C.profile;local active=N.App.profiles:Active();local left,top=U.frame.GetLeft,U.frame.GetTop
    assert(N.App.profiles:Duplicate('AfterDrag'));assert(C:SetPreferences({x=91,y=-77,scale=.5,strata='LOW',width=220,locked=false,dock='none'}))
    assert(N.App.profiles:Switch(active));assert(C:SetPreferences({locked=false,dock='none',scale=1,strata='HIGH'}))
    U.frame.GetLeft=function()return 420 end;U.frame.GetTop=function()return UIParent:GetHeight()/U.frame:GetScale()-240 end
    U.header.scripts.OnDragStart();assert(U.dragging and U.frame.moving)
    assert(N.App.profiles:Switch('AfterDrag'));assert(not U.dragging and not U.frame.moving)
    assert(C.profile.x==91 and C.profile.y==-77 and U.frame:GetScale()==.5 and U.frame:GetFrameStrata()=='LOW')
    U.header.scripts.OnDragStop();assert(C.profile.x==91 and C.profile.y==-77 and C.profile.width==220)
    -- Same-name reset/copy also invalidate a gesture, even though the profile ID remains.
    U.header.scripts.OnDragStart();assert(U.dragging);assert(N.App.profiles:Reset());assert(not U.dragging)
    setPreference(C,'width',261);U.header.scripts.OnDragStart();assert(U.dragging);assert(N.App.profiles:CopyFrom(active));assert(not U.dragging)
    U.frame.GetLeft=left;U.frame.GetTop=top;assert(N.App.profiles:Switch(active));restorePreferences(C,profile);C:ShowPanel(true)
end)

test('geometry gestures cancel on display changes while routine font refresh keeps native control',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local parentScale=UIParent:GetScale();local screenWidth,screenHeight=UIParent:GetWidth(),UIParent:GetHeight()
    C.destination=nil;C.matches=nil;C.query='';C.status=nil;setPreference(C,'locked',false);setPreference(C,'scale',1.6);setPreference(C,'width',240);U:SetDock(C,'none',false);C:RefreshAppearance()
    U.resizeGrip.scripts.OnMouseDown(U.resizeGrip,'LeftButton');assert(U.resizing and U.frame.sizing=='RIGHT')
    C:RefreshAppearance(false);assert(U.resizing and U.frame.sizing=='RIGHT','ordinary font refresh must not end a resize')
    UIParent:SetSize(900,320);dispatchEvent('DISPLAY_SIZE_CHANGED')
    assert(not U.resizing and not U.frame.sizing and math.abs(U.frame:GetScale()-320/660)<.0001,'display shrink cancels native sizing and refits immediately')
    local width=C.profile.width;U.resizeGrip.scripts.OnMouseUp(U.resizeGrip,'LeftButton');assert(C.profile.width==width)
    UIParent:SetSize(screenWidth,screenHeight);C:RefreshAppearance();U.header.scripts.OnDragStart();assert(U.dragging and U.frame.moving)
    UIParent:SetScale(.8);dispatchEvent('UI_SCALE_CHANGED');assert(not U.dragging and not U.frame.moving)
    UIParent:SetScale(parentScale);C:RefreshAppearance();U.resizeGrip.scripts.OnMouseDown(U.resizeGrip,'LeftButton');assert(U.resizing)
    setPreference(C,'width',220);setPreference(C,'x',91);setPreference(C,'y',-77);C:RefreshAppearance()
    assert(not U.resizing and not U.frame.sizing and C.profile.width==220 and C.profile.x==91 and C.profile.y==-77)
    U.resizeGrip.scripts.OnMouseUp(U.resizeGrip,'LeftButton');assert(C.profile.x==91 and C.profile.y==-77)
    restorePreferences(C,saved);UIParent:SetScale(parentScale);UIParent:SetSize(screenWidth,screenHeight);C:ShowPanel(true);C:RefreshAppearance()
end)

test('navigation typography grows ten percent and compass stays world relative as arrow turns',function()
    C:Stop();local p=A.Position();local goal=N.Model.Copy(p);goal.x=p.x+1000;goal.y=p.y+1000;goal.name='Southwind trainer';goal.id='compass'
    local route=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=N.Model.Distance(p,goal),quality='bearing'}},goal,C:Context())
    C.results={route};C.selected=1;C.origin=nil;C.matches=nil;C.destination=goal;C:Go();C.manualPause=false
    U:Guidance(C,p,{speed=7,facing=0},0);local rotation=U.arrow.rotation
    assert(U.cardinal:GetText()=='NW' and U.cardinal:IsShown() and U.next.textColor[1]==1 and U.next.fontFlags=='OUTLINE')
    assert(math.abs(U.next.fontSize-C.profile.fontSize*1.1)<.0001)
    U:Guidance(C,p,{speed=7,facing=math.pi/2},0);assert(U.cardinal:GetText()=='NW' and U.arrow.rotation~=rotation)
    assert(U.tuck.iconKind=='back');U:SetDock(C,'right',true);assert(U.handle.iconKind=='left');U.handle.scripts.OnMouseDown(U.handle,'LeftButton');U.handle.scripts.OnClick()
    U.pause.scripts.OnClick();assert(not U.cardinal:IsShown());C:Stop();setPreference(C,'dock','none');C:Refresh()
end)
test('matching bold weight is validated cached and downgraded without losing the regular family',function()
    withFontLibrary(function(lib,callbacks)
        lib.IsValid=function(_,kind,name) return name=='Expressway' or name=='Expressway Bold' end
        lib.Fetch=function(_,kind,name) return name=='Expressway Bold' and 'expressway-bold.ttf' or 'review-expressway.ttf' end
        N.App.fonts:Refresh()
        assert(U.next.font=='expressway-bold.ttf' and U.next.fontFlags=='' and U.rows[1].detail.font=='expressway-bold.ttf')
        assert(option(N.Options,'appearance',2).Text.font=='review-expressway.ttf' and U.remaining.font=='review-expressway.ttf')
        local target=U.rows[3].name;local original=target.SetFont or methods.SetFont
        target.SetFont=function(self,path,size,flags) if path=='expressway-bold.ttf' then return true end;return original(self,path,size,flags) end
        target.font='previous-font';N.App.fonts:Refresh()
        assert(U.next.font=='review-expressway.ttf' and U.next.fontFlags=='OUTLINE' and U.rows[1].detail.font=='review-expressway.ttf')
        assert(option(N.Options,'appearance',2).Text.font=='review-expressway.ttf' and C.profile.font=='Expressway')
        target.SetFont=nil;callbacks.LibSharedMedia_Registered(nil,'font');assert(U.next.font=='expressway-bold.ttf')
    end)
end)

test('editor labels fields action buttons and route action share consistent alignment at supported widths',function()
    C:Stop();local saved={profile=N.Model.Copy(C.profile),filter=C.filter,searchOrigin=C.searchOrigin};C.destination=nil;C.status=nil;C.matches={}
    for _,width in ipairs({220,240,280,304,460,640}) do for _,size in ipairs({10,13,18}) do for _,scale in ipairs({.5,1,1.6}) do
        setPreference(C,'width',width);setPreference(C,'fontSize',size);setPreference(C,'scale',scale);C:RefreshAppearance()
        assert(U.current.point[2]==U.filterButton.point[2] and U.current:GetWidth()==U.filterButton:GetWidth())
        assert(U.current.point[2]+U.current:GetWidth()==width-14 and U.tuck.point[2]==U.current.point[2])
        assert(U.from:GetWidth()==U.to:GetWidth() and U.from.point[2]+U.from:GetWidth()+4==U.current.point[2])
        assert(U.current.point[3]-U.current:GetHeight()/2==U.from.point[3]-U.from:GetHeight()/2)
        assert(U.filterButton.point[3]-U.filterButton:GetHeight()/2==U.to.point[3]-U.to:GetHeight()/2)
        for _,label in ipairs(U.fieldLabels) do
            assert(label:GetWidth()>=label:GetUnboundedStringWidth())
            assert(math.abs(label.point[2]+label:GetWidth()+8-U.from.point[2])<.0001)
        end
        assert(U.fieldLabels[1]:GetWidth()==U.fieldLabels[2]:GetWidth())
        assert(U.fieldLabels[1].point[3]-U.fieldLabels[1]:GetHeight()/2==U.from.point[3]-U.from:GetHeight()/2)
        for _,label in ipairs({'Find routes','Use origin','Compare matches'}) do
            C.searchOrigin=label=='Use origin';C.filter={categories=label=='Compare matches' and {place=true} or {},classes={},professions={}};C:Refresh()
            assert(U.go.text:GetText()==label and U.go:GetHeight()>=30 and U.go.text.justifyH=='CENTER')
            assert(U.go.point[2]+U.go:GetWidth()/2==width/2)
            local textWidth=U.go.text:GetUnboundedStringWidth()
            assert(U.go:GetWidth()>=textWidth+32-.0001 and U.go:GetWidth()<=textWidth+33,'footer fits the label with comfortable padding: '..U.go:GetWidth()..' / '..textWidth)
            assert(U.go.text:GetWidth()>=textWidth and U.go.point[2]>=14 and U.go.point[2]+U.go:GetWidth()<=width-14)
        end
    end end end
    local measure=U.fieldLabels[1].GetUnboundedStringWidth;local actionMeasure=U.go.text.GetUnboundedStringWidth
    U.fieldLabels[1].GetUnboundedStringWidth=function() return 1000 end;U.go.text.GetUnboundedStringWidth=function() return 1000 end
    setPreference(C,'width',280);C:Refresh();assert(U.from:GetWidth()>=100 and U.go:GetWidth()==252 and U.go.text:GetWidth()<=U.go:GetWidth())
    U.fieldLabels[1].GetUnboundedStringWidth=measure;U.go.text.GetUnboundedStringWidth=actionMeasure
    restorePreferences(C,saved.profile);C.filter=saved.filter;C.searchOrigin=saved.searchOrigin;C:Stop();C:RefreshAppearance()
end)
test('map and minimap preferences default on migrate explicit opt outs and remain independent',function()
    local S=N.Settings
    local p=S.Load({});assert(p.mapMarkers and p.minimapMarkers)
    p=S.Load({overlays=false});assert(not p.mapMarkers and not p.minimapMarkers)
    p=S.Load({overlays=false,mapMarkers=true});assert(p.mapMarkers and not p.minimapMarkers)
    p=S.Load({mapMarkers=false,minimapMarkers=true});assert(not p.mapMarkers and p.minimapMarkers)
    local savedMap,savedMini=C.profile.mapMarkers,C.profile.minimapMarkers
    local mapToggle=option(N.Options,'navigation',2);mapToggle:SetChecked(false);mapToggle.scripts.OnClick(mapToggle);assert(not C.profile.mapMarkers and C.profile.minimapMarkers)
    local miniToggle=option(N.Options,'navigation',3);miniToggle:SetChecked(false);miniToggle.scripts.OnClick(miniToggle);assert(not C.profile.mapMarkers and not C.profile.minimapMarkers)
    setPreference(C,'mapMarkers',savedMap);setPreference(C,'minimapMarkers',savedMini);C:RefreshAppearance()
end)

test('selected destination appears before Go on zone and world maps with independent minimap control',function()
    C:Stop();C.destination=nil;C.origin=nil;C.manualPause=false;C.results={}
    local mapID,shown=WorldMapFrame.GetMapID,WorldMapFrame:IsShown();local project=C_Map.GetMapPosFromWorldPos
    local oldMap,oldMini=C.profile.mapMarkers,C.profile.minimapMarkers;setPreference(C,'mapMarkers',true);setPreference(C,'minimapMarkers',true)
    local id=1429;WorldMapFrame.GetMapID=function() return id end;WorldMapFrame:Show()
    local p=A.Position();local goal=N.Model.Copy(p);goal.name='Map preview';goal.id='map-preview';goal.x=p.x+20
    C:Choose(goal);local O=N.Overlay;O:Update(C,p,{facing=0,speed=7})
    assert(not C.nav.route and O.destination:IsShown() and O.destination.caption=='Destination: Map preview' and O.mini:IsShown())
    id=947;O:Update(C,p,{facing=0,speed=7});assert(O.destination:IsShown(),'use native projection for the currently viewed map')
    setPreference(C,'minimapMarkers',false);O:Update(C,p,{speed=7});assert(not O.mini:IsShown() and O.destination:IsShown())
    setPreference(C,'minimapMarkers',true);setPreference(C,'mapMarkers',false);O:Update(C,p,{speed=7});assert(O.mini:IsShown() and not O.destination:IsShown())
    setPreference(C,'mapMarkers',true);O:Update(C,nil,{speed=7});assert(O.destination:IsShown() and not O.mini:IsShown(),'map coordinates remain useful while player location is missing')
    O:Update(C,p,{dead=true,speed=7});assert(O.destination:IsShown() and not O.mini:IsShown())
    C_Map.GetMapPosFromWorldPos=function() return 999,CreateVector2D(.5,.5) end
    O:Update(C,p,{speed=7});assert(not O.destination:IsShown(),'never place a fabricated pin on an unsupported map')
    C_Map.GetMapPosFromWorldPos=project;WorldMapFrame.GetMapID=mapID;WorldMapFrame:SetShown(shown)
    setPreference(C,'mapMarkers',oldMap);setPreference(C,'minimapMarkers',oldMini);C.destination=nil;C:Stop()
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
    U.from:SetText('Act');U.from:SetFocus();assert(U.go.text:GetText()=='Use origin')
    assert(U.go.point[2]>=74 and U.go.point[2]+U.go:GetWidth()<=U.stop.point[2]-8 and U.go.text:GetWidth()>=U.go.text:GetUnboundedStringWidth())
    U.go.scripts.OnClick()
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
    C.character.known={[1]={state='known'},[2]={state='known'}};setPreference(C,'routeOrder','distance');C.filter={categories={},classes={},professions={}};C.destination=goal;C.origin=nil;C.taxi=nil
    C:Plan();assert(C.results[1].flight==0 and U.routeOrder.value=='distance');C:Go();local active=C.nav.route
    C.compact=false;assert(C:SetRouteOrder('time'));assert(C.results[1].flight>0 and C.nav.route==active)
    assert(U.routeOrder.value=='time' and option(N.Options,'navigation',1).Text:GetText()=='Estimated time' and U.routeHeading:IsShown())
    local results=C.results;assert(not C:SetRouteOrder('invalid') and C:SetRouteOrder('time') and C.results==results)
    C:SetRouteOrder('distance');assert(C.results[1].flight==0 and C.nav.route==active and U.routeOrder.value=='distance' and option(N.Options,'navigation',1).Text:GetText()=='Distance')
    C.data=saved.data;C.character.known=saved.known;restorePreferences(C,saved.profile);C.filter=saved.filter;C.destination=nil;C:Stop();C:RefreshAppearance()
end)

test('route comparison shares only identical destinations and gives legs full width',function()
    C:Stop();local saved=N.Model.Copy(C.profile);setPreference(C,'width',304);setPreference(C,'fontSize',13);setPreference(C,'scale',1);setPreference(C,'resultsHeight',296);C:RefreshAppearance()
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
    restorePreferences(C,saved);C.destination=nil;C:Stop();C:RefreshAppearance()
end)

test('wrapped row measurement settles fractional scale before measuring and keeps footer separate',function()
    C:Stop();local saved=N.Model.Copy(C.profile);setPreference(C,'scale',1.25);setPreference(C,'fontSize',13);setPreference(C,'width',304)
    local p=A.Position();p.name='Measure target';p.role='Trainer';p.zone='Ironforge';C.matches={};C.highlight=1
    for i=1,40 do C.matches[i]=p end
    C:RefreshAppearance();local row=U.rows[1];local scale=row.name:GetEffectiveScale()
    assert(scale==1.25 and row.name:GetHeight()==(math.ceil(13*scale)+2)/scale)
    assert(U.resultsBoundary:IsShown() and -U.go.point[3]>U.bodyTop+U.bodyScroll:GetHeight())
    UIParent:SetSize(1280,540);dispatchEvent('DISPLAY_SIZE_CHANGED');scale=row.name:GetEffectiveScale()
    assert(scale==U.frame:GetEffectiveScale() and row.name:GetHeight()==(math.ceil(13*scale)+2)/scale)
    assert(U.frame:GetHeight()*scale<=540)
    C.highlight=40;setPreference(C,'width',640);C:Refresh();setPreference(C,'width',280);setPreference(C,'fontSize',18);C:RefreshAppearance()
    local selected=U.rows[40];local offset=U.bodyScroll:GetVerticalScroll()
    assert(selected.bodyOffset>=offset and selected.bodyOffset+selected:GetHeight()<=offset+U.bodyScroll:GetHeight()+.001,'reflow reveals the highlighted result')
    U.body.scripts.OnMouseWheel(nil,1);offset=U.bodyScroll:GetVerticalScroll();C:Refresh()
    assert(U.bodyScroll:GetVerticalScroll()==offset,'unchanged layout preserves manual scroll position')
    UIParent:SetSize(1920,1080);restorePreferences(C,saved);C:Stop();C:RefreshAppearance()
end)
test('width resize rebudgets wrapped headings without pushing content outside the frame',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);setPreference(C,'width',640);setPreference(C,'fontSize',18);setPreference(C,'scale',1);setPreference(C,'locked',false);C:RefreshAppearance()
    local p=A.Position();local goal=N.Model.Copy(p);goal.id='resize-wrap';goal.name=string.rep('Long shared destination ',3);goal.x=p.x+500
    local route=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=500,seconds=100}},goal,C:Context())
    C.results={route,route,route};C.destination=goal;C.status=nil;C:Refresh()
    local height=U.frame:GetHeight();local oldChrome=height-U.bodyScroll:GetHeight()
    U.resizeGrip.scripts.OnMouseDown(nil,'LeftButton');U.frame:SetSize(280,height);U.frame.scripts.OnSizeChanged(U.frame,280,height)
    local chrome=U.bodyTop+30
    assert(U.resizeChrome>oldChrome and math.abs(U.resizeChrome-chrome)<.001)
    assert(U.bodyTop+U.bodyScroll:GetHeight()+22<=U.frame:GetHeight()+.001,'rewrapped content stays inside native frame height')
    assert(U.frame.resizeBounds[2]>=chrome+100)
    U.resizeGrip.scripts.OnMouseUp(nil,'LeftButton');restorePreferences(C,saved);C.destination=nil;C:Stop();C:RefreshAppearance()
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
    U.handle.scripts.OnEnter(U.handle);assert(U.handle.borderColor[1]==U.theme.colors.accent[1] and GameTooltip:GetText()=='Click to expand. Drag up or down to move.')
    U.handle.scripts.OnLeave(U.handle);assert(U.handle.borderColor[1]==U.theme.colors.border[1])
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
test('search and route rows share one quiet measured tooltip without changing the global tooltip',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile)
    setPreference(C,'font','Arial');setPreference(C,'fontSize',18);setPreference(C,'scale',1.6);C:RefreshAppearance()
    local p=A.Position();local goal=N.Model.Copy(p)
    goal.id='tip-target';goal.name='Trainer with noisy metadata';goal.x=p.x+120;goal.source='QuestieDB';goal.category='class';goal.role='Warrior Trainer';goal.zone='Ironforge'
    goal.confidence='provider';goal.mobile=true;goal.phase=7;goal.faction='Alliance';goal.questStarts=4;goal.questEnds=2
    local route=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=120,seconds=30}},goal,C:Context())
    route.unavailable='undiscovered';route.conditional=true
    local originals={}
    for _,name in ipairs({'SetOwner','SetText','Show','Hide','SetFontObject'}) do
        originals[name]=rawget(GameTooltip,name)
        GameTooltip[name]=function() error('row tooltip must not mutate global GameTooltip') end
    end
    local function checkRow()
        local row=U.rows[1];row.scripts.OnEnter(row)
        local tip=U.rowTooltip;local line=tip.TextLeft1;local measured=tip.measuredText
        assert(tip:GetText()=='Travel time may vary based on terrain.' and line:GetText()==tip:GetText())
        assert(tip:GetOwner()==row and tip:IsShown() and tip.tooltipAnchor=='ANCHOR_RIGHT')
        assert(tip.template=='SharedTooltipTemplate' and tip.parent==UIParent and tip:GetEffectiveScale()==UIParent:GetEffectiveScale())
        assert(measured.path=='Fonts\\ARIALN.TTF' and measured.size==11 and measured.flags=='','native measurement uses the small regular font before population')
        assert(measured.width>0 and measured.wrap and measured.color[4]==1)
        assert(line.textColor[1]==.76 and line.textColor[2]==.78 and line.textColor[3]==.82)
        assert(row.borderColor[1]==U.theme.colors.accent[1]);row.scripts.OnLeave(row)
        assert(not tip:IsShown() and not U.rowTooltipOwner and row.borderColor[1]==(row.atcfSelected and U.theme.colors.accent[1] or U.theme.colors.border[1]))
    end
    C.destination=nil;C.results={};C.matches={goal};C.highlight=1;C:Refresh();checkRow()
    C.matches=nil;C.destination=goal;C.results={route};C.selected=1;C:Refresh();checkRow()
    assert(not U.rows[1].go.enabled and U.rows[1].locked:IsShown(),'unavailable routes retain their visible eligibility status')
    local tip=U.rowTooltip;local allocated,registered=#frames,#U.texts
    for i=1,20 do
        C.matches=i%2==0 and {goal} or nil;C:Refresh();checkRow()
    end
    assert(U.rowTooltip==tip and #frames==allocated and #U.texts==registered,'hover and pooled-row reuse allocate no extra tooltip or font registrations')
    for _,name in ipairs({'SetOwner','SetText','Show','Hide','SetFontObject'}) do GameTooltip[name]=originals[name] end
    restorePreferences(C,saved);C.destination=nil;C:Stop();C:RefreshAppearance()
end)

test('row tooltip ownership survives stale leave and clears when its row view or font changes',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile)
    local p=A.Position();p.name='Tooltip lifecycle target';p.id='tip-lifecycle';C.matches={p,p};C.highlight=1;C:Refresh()
    local first,second=U.rows[1],U.rows[2]
    first.scripts.OnEnter(first);second.scripts.OnEnter(second);local tip=U.rowTooltip
    first.scripts.OnLeave(first);assert(tip:IsShown() and U.rowTooltipOwner==second,'stale leave cannot hide the new owner')
    first:Hide();assert(tip:IsShown() and U.rowTooltipOwner==second,'stale row hide cannot hide the new owner')
    second:Hide();assert(not tip:IsShown() and not U.rowTooltipOwner)
    first:Show();second:Show();first.scripts.OnEnter(first);first.scripts.OnMouseDown(first,'LeftButton');assert(not tip:IsShown())
    first.scripts.OnEnter(first);U.bodyScroll:SetVerticalScroll(10);assert(not tip:IsShown(),'scrolling clears the former row anchor')
    first.scripts.OnEnter(first);U.bodyScroll:Hide();assert(not tip:IsShown(),'compact view hides the results viewport')
    U.bodyScroll:Show();first.scripts.OnEnter(first);C:ShowPanel(false);assert(not tip:IsShown() and not U.frame:IsShown())
    C:ShowPanel(true);first.scripts.OnEnter(first);C.matches={};C:Refresh();assert(not tip:IsShown(),'replacing the match pool removes stale tooltip anchors')
    C.matches={p,p};C:Refresh();first.scripts.OnEnter(first)
    setPreference(C,'font','Arial');setPreference(C,'fontSize',18);setPreference(C,'scale',1.6);setPreference(C,'colors.text',{1,.2,.1});N.App.fonts:Refresh()
    assert(not tip:IsShown() and not U.rowTooltipOwner,'appearance refresh hides the old measured tooltip')
    assert(tip.TextLeft1.textColor[1]==.76 and tip.TextLeft1.textColor[2]==.78,'panel appearance cannot recolor the owned tooltip')
    first.scripts.OnEnter(first);assert(tip.measuredText.path=='Fonts\\ARIALN.TTF' and tip.measuredText.size==11 and tip:GetScale()==1)
    first.scripts.OnLeave(first);restorePreferences(C,saved);C.destination=nil;C:Stop();C:RefreshAppearance()
end)
test('interaction identity uses only an ordinary NPC GUID with guarded native or strict fallback parsing',function()
    local savedGUID,savedInfo,savedSecret=UnitGUID,C_CreatureInfo,issecretvalue
    local guid='Creature-0-1234-0-0-1498-000000ABCD';local calls=0
    UnitGUID=function(unit) assert(unit=='npc','interaction identity must never inspect target or mouseover');return guid end
    C_CreatureInfo={GetCreatureID=function(value) calls=calls+1;assert(value==guid);return 1498 end}
    assert(A.InteractionNPCID()==1498 and calls==1)
    C_CreatureInfo=nil;assert(A.InteractionNPCID()==1498)
    guid='Vehicle-0-1234-0-0-1498-000000ABCD';assert(A.InteractionNPCID()==1498)
    for _,invalid in ipairs({'Player-0-1234-0-0-1498-000000ABCD','Pet-0-1234-0-0-1498-000000ABCD','GameObject-0-1234-0-0-1498-000000ABCD','Creature-1498','Creature-0-1234-0-0-0-000000ABCD','Creature-0-1234-0-0-name-000000ABCD'}) do
        guid=invalid;assert(A.InteractionNPCID()==nil)
    end
    guid='Creature-0-1234-0-0-1498-000000ABCD'
    for _,invalid in ipairs({false,0,-1,1.5,math.huge,0/0,'1498'}) do
        C_CreatureInfo={GetCreatureID=function() return invalid end};assert(A.InteractionNPCID()==nil,'available native getter failure must not silently parse around its result')
    end
    C_CreatureInfo={GetCreatureID=function() error('unavailable') end};assert(A.InteractionNPCID()==nil)
    local secret=setmetatable({},{__index=function() error('secret GUID was inspected') end,__eq=function() error('secret identity was compared') end})
    issecretvalue=function(value) return rawequal(value,secret) end
    guid=secret;assert(A.InteractionNPCID()==nil)
    guid='Creature-0-1234-0-0-1498-000000ABCD';C_CreatureInfo.GetCreatureID=function() return secret end;assert(A.InteractionNPCID()==nil)
    UnitGUID=function() error('unit unavailable') end;assert(A.InteractionNPCID()==nil)
    UnitGUID=nil;assert(A.InteractionNPCID()==nil)
    UnitGUID,C_CreatureInfo,issecretvalue=savedGUID,savedInfo,savedSecret
end)

local function arrivalFixture()
    local saved={data=C.data,destinations=C.destinations,filter=C.filter,provider=C.provider,guid=UnitGUID,creature=C_CreatureInfo,secret=issecretvalue,position=A.Position,now=now,x=playerX,y=playerY}
    C:Stop();C:ShowPanel(true);C.origin=nil;C.destination=nil;C.taxi=nil;C.query='';C.originQuery='';C.matches=nil;C.searching=nil;C.filter={categories={},classes={},professions={}};timers={};onTaxi=false;dead=false
    C.data={nodes={},edges={}};local p=A.Position();local goal=N.Model.Copy(p);goal.x=p.x+400;goal.id='arrival-npc';goal.npcID=1498;goal.name='Arrival trainer';goal.category='class';goal.confidence='provider';goal.mobile=true
    C.destinations={goal};C_CreatureInfo=nil
    UnitGUID=function(unit) assert(unit=='npc');return 'Creature-0-1234-0-0-1498-000000ABCD' end
    local function start(destination)
        A.Position=saved.position;onTaxi=false;dead=false;C.taxi=nil;C.origin=nil;C:Stop();C:Choose(destination or goal)
        local route=N.Routes.Summary({{mode='walk',start=p,finish=destination or goal,distance=N.Model.Distance(p,destination or goal),quality='bearing'}},destination or goal,C:Context())
        C.results={route};C.selected=1;C:Go();assert(C.nav.route==route);return route
    end
    local function cleanup()
        A.Position=saved.position;UnitGUID,C_CreatureInfo,issecretvalue=saved.guid,saved.creature,saved.secret
        onTaxi=false;dead=false;now=saved.now;playerX,playerY=saved.x,saved.y;C:Stop();C.origin=nil;C.destination=nil;C.query='';C.originQuery='';C.searchOrigin=nil;C.taxi=nil;C.expected=nil
        C.data=saved.data;C.destinations=saved.destinations;C.filter=saved.filter;C.provider=saved.provider;C:ShowPanel(true);timers={}
    end
    return goal,start,cleanup
end

test('only genuine NPC show events complete the active destination rather than a preview or target',function()
    local goal,start,cleanup=arrivalFixture();local route=start()
    local preview=N.Model.Copy(goal);preview.id='preview-npc';preview.npcID=999;C:Choose(preview)
    UnitGUID=function(unit) return unit=='npc' and 'Creature-0-1234-0-0-999-000000ABCD' or nil end
    dispatchEvent('GOSSIP_SHOW');assert(C.nav.route==route and not C.arrivalUntil,'preview identity cannot complete the active route')
    UnitGUID=function(unit) return unit=='target' and 'Creature-0-1234-0-0-1498-000000ABCD' or nil end
    dispatchEvent('GOSSIP_SHOW');assert(C.nav.route==route,'targeting the destination is not an interaction')
    UnitGUID=function() return 'Creature-0-1234-0-0-1498-000000ABCD' end
    dispatchEvent('PLAYER_TARGET_CHANGED');assert(C.nav.route==route and not registered('PLAYER_TARGET_CHANGED'))
    local kinds=Enum.PlayerInteractionType
    dispatchEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW',kinds.Item);assert(C.nav.route==route)
    dispatchEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW',kinds.TradePartner);assert(C.nav.route==route)
    dispatchEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW',kinds.WorldMap);assert(C.nav.route==route)
    local secret=setmetatable({},{__eq=function() error('secret interaction type compared') end})
    issecretvalue=function(value) return rawequal(value,secret) end
    dispatchEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW',secret);assert(C.nav.route==route);issecretvalue=nil
    for _,event in ipairs({'GOSSIP_SHOW','QUEST_GREETING','QUEST_DETAIL','QUEST_PROGRESS','QUEST_COMPLETE','TRAINER_SHOW','MERCHANT_SHOW','BANKFRAME_OPENED','AUCTION_HOUSE_SHOW'}) do
        start();assert(registered(event),'missing supported interaction registration: '..event)
        dispatchEvent(event);assert(not C.nav.route and C.arrivalUntil,'matching interaction did not complete: '..event)
    end
    for _,kind in ipairs({kinds.Gossip,kinds.QuestGiver,kinds.Merchant,kinds.Trainer,kinds.Banker,kinds.Auctioneer,kinds.StableMaster}) do
        start();dispatchEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW',kind);assert(not C.nav.route and C.arrivalUntil)
    end
    cleanup()
end)

test('NPC interaction ignores unavailable identity death and taxi but accepts a paused mobile destination without coordinates',function()
    local goal,start,cleanup=arrivalFixture();local route=start();local valid='Creature-0-1234-0-0-1498-000000ABCD'
    for _,read in ipairs({function() return nil end,function() return 'Player-0-1234-0-0-1498-000000ABCD' end,function() error('restricted unit') end}) do
        UnitGUID=read;dispatchEvent('QUEST_DETAIL');assert(C.nav.route==route and not C.arrivalUntil)
    end
    local secret={};issecretvalue=function(value) return rawequal(value,secret) end;UnitGUID=function() return secret end
    dispatchEvent('GOSSIP_SHOW');assert(C.nav.route==route);issecretvalue=nil
    UnitGUID=function() return valid end;C_CreatureInfo={GetCreatureID=function() error('restricted getter') end}
    dispatchEvent('GOSSIP_SHOW');assert(C.nav.route==route);C_CreatureInfo=nil
    dead=true;dispatchEvent('TRAINER_SHOW');assert(C.nav.route==route);dead=false
    onTaxi=true;dispatchEvent('TRAINER_SHOW');assert(C.nav.route==route);onTaxi=false
    C.manualPause=true;C.nav.state='paused';C.nav.suspendedState='walking';A.Position=function() return nil end
    dispatchEvent('TRAINER_SHOW');assert(not C.nav.route and C.arrivalUntil and not C.manualPause,'actual matching service interaction supersedes missing position and a user pause')
    cleanup()
end)

test('arrival resets transient navigation and queued search while preserving profiles character knowledge and placement',function()
    local goal,start,cleanup=arrivalFixture();start();local profile,character,known,timings,places=C.profile,C.character,C.character.known,C.character.timings,C.character.places
    local dock,position,strata,width,scale=profile.dock,profile.dockPosition,profile.strata,profile.width,profile.scale
    C:Search('queued origin',true);local generation=C.searchGeneration
    C.origin=goal;C.destination=goal;C.matches={goal};C.planned=true;C.lastSelection='origin';C.status='stale';C.chosenFlight={from=1,to=2};C.expected={from=1,to=2}
    C.hidden=true;C.tucked=true;U.from:SetFocus();U.to:SetFocus();local at=now
    dispatchEvent('TRAINER_SHOW')
    assert(not C.nav.route and C.nav.state=='editing' and not C.character.intent and not C.chosenFlight and not C.expected)
    assert(not C.origin and not C.destination and not C.matches and not C.searching and not C.planned and not C.searchOrigin and not C.lastSelection and #C.results==0)
    assert((C.query or '')=='' and (C.originQuery or '')=='' and not C.compact and not U.from:HasFocus() and not U.to:HasFocus())
    assert(C.searchGeneration>generation and C.arrivalUntil==at+3 and C.hidden and C.tucked)
    assert(C.profile==profile and C.character==character and character.known==known and character.timings==timings and character.places==places)
    assert(profile.dock==dock and profile.dockPosition==position and profile.strata==strata and profile.width==width and profile.scale==scale)
    local queued=timers;timers={};for _,fn in ipairs(queued) do fn() end
    assert(not C.matches and not C.searching and not C.origin and not C.destination,'the canceled search cannot revive editor selections')
    now=at+1;dispatchEvent('GOSSIP_SHOW');assert(C.arrivalUntil==at+3,'duplicate interaction events cannot extend arrival')
    C:ShowPanel(true);now=at+2.9;C:Tick();assert(C.arrivalUntil and U.note:GetText()=='Arrived!')
    now=at+3.1;C:Tick();assert(not C.arrivalUntil and not U.note:IsShown() and not C.nav.route)
    cleanup()
end)

test('arrival confirmation returns to the editor and a new search replaces the transient notice immediately',function()
    local goal,start,cleanup=arrivalFixture();start();C.nav.state='nearby';C:Refresh()
    assert(U.pause.iconKind=='done');U.pause.scripts.OnClick()
    assert(not C.nav.route and C.arrivalUntil and not C.compact and U.editor:IsShown() and not U.guidance:IsShown())
    assert(U.note:IsShown() and U.note:GetText()=='Arrived!' and U.note.justifyH=='CENTER')
    C:Search('Arrival',false);assert(not C.arrivalUntil and U.note:GetText()~='Arrived!')
    local queued=timers;timers={};for _,fn in ipairs(queued) do fn() end;assert(#C.matches==1 and C.matches[1]==goal)
    C:Stop();C:Arrive();assert(not C.arrivalUntil,'arrival without an active route must not create a success notice')
    cleanup()
end)

test('flight destination arrival requires the fresh reconciled final taxi node and never a cached or earlier master',function()
    local _,start,cleanup=arrivalFixture();local savedAll,savedMap,savedRoutes=C_TaxiMap.GetAllTaxiNodes,C_TaxiMap.GetTaxiNodesForMap,GetNumRoutes
    local p=A.Position();local source=N.Model.Copy(p);source.id=301;source.name='First master';source.category='flight'
    local goal=N.Model.Copy(p);goal.id=303;goal.x=p.x+500;goal.name='Final master';goal.category='flight';C.data.nodes={[301]=source,[303]=goal}
    C_TaxiMap.GetTaxiNodesForMap=function() return {} end;GetNumRoutes=function() return 0 end
    C_TaxiMap.GetAllTaxiNodes=function() return {{nodeID=301,state=0,slotIndex=1}} end
    local route=start(goal);UnitGUID=function() return nil end
    dispatchEvent('TAXIMAP_OPENED');assert(C.nav.route==route and C.taxi.from==301,'opening an earlier master cannot complete the final destination')
    C.taxi={from=303,offers={}};local position=A.Position;A.Position=function() return nil end
    dispatchEvent('TAXIMAP_OPENED');assert(C.nav.route==route and not C.arrivalUntil,'cached taxi context cannot stand in for this interaction')
    A.Position=position;C_TaxiMap.GetAllTaxiNodes=function() return {{nodeID=303,state=0,slotIndex=1}} end
    dispatchEvent('TAXIMAP_OPENED');assert(C.nav.route==route and not C.taxi,'an unreconciled final node must not complete arrival')
    playerY=playerY+.25;dispatchEvent('TAXIMAP_OPENED');assert(not C.nav.route and C.arrivalUntil,'opening the actual reconciled final flight point confirms arrival')
    C_TaxiMap.GetAllTaxiNodes,C_TaxiMap.GetTaxiNodesForMap,GetNumRoutes=savedAll,savedMap,savedRoutes;cleanup()
end)
test('map projection retains authoritative city coordinates and composes only proven parent map rectangles',function()
    local inverse,info,rect=C_Map.GetMapPosFromWorldPos,C_Map.GetMapInfo,C_Map.GetMapRectOnMap
    local p={map=0,x=120,y=240,uiMapID=1453,mx=.25,my=.5};local parents={[1453]=1415,[1415]=947}
    C_Map.GetMapPosFromWorldPos=function() return nil end
    C_Map.GetMapInfo=function(id) return {parentMapID=parents[id]} end
    C_Map.GetMapRectOnMap=function(child,parent)
        if child==1453 and parent==1415 then return .2,.4,.1,.5 end
        if child==1415 and parent==947 then return .1,.9,.2,.8 end
        error('projection requested an unproven map relationship')
    end
    local x,y=A.Project(p,1453);assert(x==.25 and y==.5,'optional inverse must not hide a known position on its own map')
    x,y=A.Project(p,1415);assert(math.abs(x-.25)<.00001 and math.abs(y-.3)<.00001)
    x,y=A.Project(p,947);assert(math.abs(x-.3)<.00001 and math.abs(y-.38)<.00001)
    assert(not A.Project(p,1454) and not A.Project(p,14531),'no sibling zone or other floor projection')
    parents[1415]=1453;assert(not A.Project(p,947),'cycles terminate without a fabricated pin');parents[1415]=947
    C_Map.GetMapRectOnMap=function() return nil end;assert(not A.Project(p,947),'missing native rectangle fails closed')
    local secret=setmetatable({},{__lt=function() error('secret compared') end,__sub=function() error('secret subtracted') end})
    issecretvalue=function(value) return rawequal(value,secret) end
    C_Map.GetMapInfo=function() return {parentMapID=secret} end;assert(not A.Project(p,947))
    C_Map.GetMapInfo=function(id) return {parentMapID=parents[id]} end
    C_Map.GetMapRectOnMap=function() return secret,.8,.1,.9 end;assert(not A.Project(p,947))
    C_Map.GetMapPosFromWorldPos=function() return secret,CreateVector2D(.5,.5) end
    C_Map.GetMapRectOnMap=function() return .8,.2,.1,.9 end;assert(not A.Project(p,947),'reversed rectangle is invalid')
    issecretvalue=nil;C_Map.GetMapPosFromWorldPos=function() return nil end
    for _,bad in ipairs({-1,1.1,0/0,math.huge}) do local invalid=N.Model.Copy(p);invalid.mx=bad;assert(not A.Project(invalid,1453)) end
    C_Map.GetMapPosFromWorldPos=function(_,_,id) return id,CreateVector2D(1.2,-.2) end
    local worldOnly={map=0,x=120,y=240};assert(not A.Project(worldOnly,947))
    x,y=A.Project(worldOnly,947,true);assert(x==1.2 and y==-.2,'flight geometry still reaches the clipping stage outside canvas bounds')
    C_Map.GetMapPosFromWorldPos,C_Map.GetMapInfo,C_Map.GetMapRectOnMap=inverse,info,rect
end)

test('selected NPC keeps its native map pin when the optional inverse is unavailable',function()
    C:Stop();C:ShowPanel(true);C.origin=nil;C.destination=nil;C.results={};local inverse=C_Map.GetMapPosFromWorldPos
    local mapID,shown,enabled=WorldMapFrame.GetMapID,WorldMapFrame:IsShown(),C.profile.mapMarkers
    WorldMapFrame.GetMapID=function() return 1429 end;WorldMapFrame:Show();setPreference(C,'mapMarkers',true)
    local goal=A.FromMap(1429,.2,.7);goal.name='Mapped trainer';goal.id='mapped-trainer';goal.npcID=1498;goal.category='class'
    C_Map.GetMapPosFromWorldPos=function() return nil end;C:Choose(goal);local pin=N.Overlay.destination
    assert(pin:IsShown() and pin.caption=='Destination: Mapped trainer' and pin.point[4]==.2*canvas:GetWidth() and pin.point[5]==-.7*canvas:GetHeight())
    C_Map.GetMapPosFromWorldPos=inverse;WorldMapFrame.GetMapID=mapID;WorldMapFrame:SetShown(shown);setPreference(C,'mapMarkers',enabled);C.destination=nil;C:Stop()
end)

test('native navigation arrows preserve atlas UVs and fixed gold through both guarded artwork fallbacks',function()
    local atlas=C_Texture.GetAtlasInfo;local texture=U.guidance:CreateTexture();texture:SetSize(32,32);texture:SetPoint('TOPLEFT',0,-4)
    C_Texture.GetAtlasInfo=function(name) if name=='ui-worldmaparrow-2x' then return {width=64,height=64} end end
    texture:SetRotation(2);U:NavigationArrow(texture)
    assert(texture.atcfArrowAsset=='ui-worldmaparrow-2x' and texture.atlas=='ui-worldmaparrow-2x' and texture.coords[1]==.1 and texture.coords[2]==.2)
    assert(texture.rotation==0 and texture.desaturated and texture.color[1]==1 and texture.color[2]==.82 and texture.color[3]==0)
    assert(texture:GetWidth()==32 and texture:GetHeight()==32 and texture.point[1]=='TOPLEFT')
    C_Texture.GetAtlasInfo=function() return nil end;texture:SetRotation(1);U:NavigationArrow(texture)
    assert(texture.atcfArrowAsset==6152823 and texture.texture==6152823 and texture.coords[1]==1/128 and texture.coords[2]==65/128 and texture.coords[3]==1/128 and texture.coords[4]==65/128 and texture.rotation==0)
    texture.SetTexture=function(self,path,...) if path==6152823 then return false end;return methods.SetTexture(self,path,...) end
    U:NavigationArrow(texture);assert(texture.atcfArrowAsset=='fallback' and texture.texture:find('Media\\arrow.tga',1,true) and texture.coords[1]==0 and texture.coords[2]==1 and texture.coords[3]==0 and texture.coords[4]==1)
    local accent=C.profile.colors.accent;setPreference(C,'colors.accent',{.1,.2,.3});U:ApplyAppearance();assert(U.arrow.color[1]==1 and U.arrow.color[2]==.82 and U.arrow.color[3]==0,'profile accent cannot tint the player-facing arrow away from native gold')
    setPreference(C,'colors.accent',accent);C_Texture.GetAtlasInfo=atlas;C:RefreshAppearance()
end)

test('populated result view leaves a stable sixteen pixel footer gap at supported widths scales and font sizes',function()
    C:Stop();C:ShowPanel(true);local saved=N.Model.Copy(C.profile);local goal=A.Position();goal.id='footer-gap';goal.name=string.rep('Trainer name ',4);goal.category='class'
    C.destination=nil;C.origin=nil;C.matches={};C.highlight=1;C.status=nil;for i=1,40 do C.matches[i]=goal end
    for _,width in ipairs({220,240,640}) do for _,size in ipairs({10,18}) do for _,scale in ipairs({.75,1.5}) do
        setPreference(C,'width',width);setPreference(C,'fontSize',size);setPreference(C,'scale',scale);C:RefreshAppearance()
        local endOfRows=U.bodyTop+U.bodyScroll:GetHeight();local buttonTop=-U.go.point[3]
        assert(U.go:IsShown() and U.resultsBoundary:IsShown() and math.abs(buttonTop-endOfRows-16)<.001)
        assert(math.abs(buttonTop-(-U.resultsBoundary.point[3])-12)<.001,'boundary and action must not visually touch')
        assert(buttonTop+U.go:GetHeight()+22<=U.frame:GetHeight()+.001,'footer retains resize-grip clearance')
        assert(U.frame:GetHeight()*U.frame:GetScale()<=UIParent:GetHeight()+.001,'larger font and scale still fit the display')
    end end end
    restorePreferences(C,saved);C:Stop();C:RefreshAppearance()
end)
test('editor actions clear arrival notice before changing the current input or view',function()
    local goal,start,cleanup=arrivalFixture()
    for _,action in ipairs({function() C:Edit(true) end,function() C:Choose(goal) end,function() C:Plan() end,function() C:Go() end,function() C:Back() end}) do
        N.Options.panel:Close();C:ShowPanel(true);start();assert(C:Arrive() and C.arrivalUntil);action();assert(not C.arrivalUntil and U.note:GetText()~='Arrived!')
    end
    cleanup()
end)

test('map pins retain normalized position and readable size across zoom while native arrows revert cleanly to preview crows',function()
    C:Stop();C:ShowPanel(true);C.origin=nil;C.destination=nil;C.results={};local mapScale,mapID=WorldMapFrame.GetCanvasScale,WorldMapFrame.GetMapID
    local oldScale,shown=canvas:GetScale(),WorldMapFrame:IsShown();local oldMap,oldMini=C.profile.mapMarkers,C.profile.minimapMarkers
    local zoom=1;WorldMapFrame.GetCanvasScale=function() return zoom end;WorldMapFrame.GetMapID=function() return 1429 end;WorldMapFrame:Show();setPreference(C,'mapMarkers',true);setPreference(C,'minimapMarkers',true)
    local goal=A.FromMap(1429,.52,.5);goal.name='Native arrow destination';goal.id='zoom-goal';C:Choose(goal)
    local O=N.Overlay;local pin=O.destination;local p=A.Position();local route=N.Routes.Summary({{mode='walk',start=p,finish=goal,distance=N.Model.Distance(p,goal)}},goal,C:Context())
    C.results={route};C.selected=1;C:Go();assert(C.nav.route==route and pin.arrow and pin.icon.atcfArrowAsset)
    assert(pin.icon.color[1]==1 and pin.icon.color[2]==.82 and O.icon.color[1]==1 and O.icon.color[2]==.82)
    for _,value in ipairs({.5,1,2}) do
        zoom=value;canvas:SetScale(value);O:Update(C,p,{facing=0,speed=7})
        assert(O.destination==pin and pin:IsShown() and math.abs(pin:GetWidth()*pin:GetEffectiveScale()-18)<.001)
        assert(math.abs(pin.point[4]/(canvas:GetWidth()*zoom)-goal.mx)<.001 and math.abs(-pin.point[5]/(canvas:GetHeight()*zoom)-goal.my)<.001,'compensated scale must preserve the map point')
    end
    local preview=A.FromMap(1429,.6,.4);preview.name='Other preview';preview.id='zoom-preview';C:Choose(preview);O:Update(C,p,{facing=0,speed=7})
    assert(not pin.arrow and pin.icon.texture:find('Media\\eagle.tga',1,true) and not pin.icon.desaturated and pin.icon.rotation==0)
    assert(pin.icon.coords[1]==0 and pin.icon.coords[2]==1 and O.map:IsShown() and O.map.arrow and O.map.icon.atcfArrowAsset)
    assert(O.miniMode=='arrow' and O.icon.atcfArrowAsset,'previewing elsewhere retains the active minimap direction')
    local allocated=#frames;for _=1,5 do O:Update(C,p,{facing=0,speed=7}) end;assert(#frames==allocated and O.destination==pin)
    C:Stop();O:Update(C,p,{facing=0,speed=7})
    assert(O.miniMode=='eagle' and O.icon.texture:find('Media\\eagle.tga',1,true) and not O.icon.desaturated and O.icon.rotation==0)
    assert(O.icon.coords[1]==0 and O.icon.coords[2]==1 and O.icon.coords[3]==0 and O.icon.coords[4]==1 and not O.map:IsShown())
    canvas:SetScale(oldScale);WorldMapFrame.GetCanvasScale=mapScale;WorldMapFrame.GetMapID=mapID;WorldMapFrame:SetShown(shown);setPreference(C,'mapMarkers',oldMap);setPreference(C,'minimapMarkers',oldMini);C.destination=nil;C:Stop()
end)
test('Back dismisses filter menu header menu and options without stranding the timed arrival note',function()
    local _,start,cleanup=arrivalFixture();N.Options.frame:Hide()
    local dialogs={
        {open=function() U.filterButton.menuOpen=true;U.filterButton:TriggerEvent('OnMenuOpen') end,shown=function() return U.filterButton:IsMenuOpen() end},
        {open=function() U.settings.scripts.OnClick() end,shown=function() return U.menu:IsShown() end},
        {open=function() N.Options:Open() end,shown=function() return N.Options.frame:IsShown() end},
    }
    for _,dialog in ipairs(dialogs) do
        N.Options.panel:Close();C:ShowPanel(true);start();assert(C:Arrive());local deadline=C.arrivalUntil
        dialog.open();assert(dialog.shown() and U.note:IsShown() and U.note:GetText()=='Arrived!')
        C:Back();assert(not dialog.shown() and C.arrivalUntil==deadline,'dismissing a dialog must leave the arrival expiration scheduled')
        now=deadline+.1;C:Tick()
        assert(not C.arrivalUntil and not U.note:IsShown() and U.frame:GetHeight()==139 and U.editor:IsShown() and not C.nav.route,'expiration restores the normal idle editor after any Back early return')
    end
    cleanup()
end)
test('taxi reconciliation replaces normalized coordinates together with their map and clears unavailable projections',function()
    local _,_,cleanup=arrivalFixture();local taxi,inverse,info=A.Taxi,C_Map.GetMapPosFromWorldPos,C_Map.GetMapInfo
    local player=A.Position();local node=N.Model.Copy(player);node.id=600;node.name='Reprojected master';node.category='flight';node.x=player.x+30;node.y=player.y+20
    node.uiMapID=1455;node.mx=.9;node.my=.8;C.data.nodes[600]=node
    A.Taxi=function() return {from=600,offers={}} end
    local projected=0;local expectedX,expectedY=node.y/4000,node.x/2000
    C_Map.GetMapPosFromWorldPos=function(continent,point,mapID)
        local x,y=point:GetXY();assert(continent==node.map and x==node.x and y==node.y and mapID==player.uiMapID,'project the actual flight node rather than the nearby player')
        projected=projected+1;return mapID,CreateVector2D(expectedX,expectedY)
    end
    C:TaxiOpened();assert(projected==1 and node.uiMapID==player.uiMapID and node.mx==expectedX and node.my==expectedY)
    assert(node.mx~=player.mx and node.my~=player.my,'the observing player is not the precise destination coordinate')
    local x,y=A.Project(node,player.uiMapID);assert(x==expectedX and y==expectedY and projected==1)
    node.uiMapID=1455;node.mx=.9;node.my=.8
    C_Map.GetMapPosFromWorldPos=function() return nil end;C_Map.GetMapInfo=function() return nil end
    C:TaxiOpened();assert(node.uiMapID==player.uiMapID and node.mx==nil and node.my==nil,'a new map cannot retain the old map coordinate pair')
    assert(not A.Project(node,player.uiMapID),'unavailable projection hides the pin instead of fabricating a stale-map position')
    A.Taxi=taxi;C_Map.GetMapPosFromWorldPos=inverse;C_Map.GetMapInfo=info;cleanup()
end)
test('Forever service corrections classify missing titles without importing Retail flag semantics',function()
    local P=N.Providers
    for _,id in ipairs({270513,270581,270582}) do
        local category,role,class,profession=P.Classify(nil,nil,nil,nil,id)
        assert(category=='transmog' and role=='Transmogrifier' and not class and not profession)
    end
    assert(P.Classify('  Transmogrifier  ',0)=='transmog')
    assert(not P.Classify(nil,0,nil,nil,273057),'the locationless same-name NPC is not an alias')
    assert(not P.Classify('Banshee Queen',268435459),'the high flag bit is not reliable Forever service evidence')
    assert(P.Classify('Banshee Queen',268435459,{1})=='quest')
    assert(P.Classify('Transmogrification Enthusiast',0,{1})=='quest','incidental titles do not establish a service')
end)

test('transmogrifier provider records retain maps faction phase source and distinct spawns',function()
    local previous=LibQuestieDB;local P=N.Providers
    -- Synthetic positions exercise plumbing without bundling provider coordinates.
    local records={
        [270581]={name='Fyrenz Vishonar',friendlyToFaction='A',spawns={[1519]={{30,40},{35,40,7}}}},
        [270513]={name='Spellweaver Thaldris',friendlyToFaction='A',spawns={[36]={{20,60}}}},
        [270582]={name="Mon'ye",subName='',friendlyToFaction='H',spawns={[1637]={{40,50}}}},
        [273057]={name='Fyrenz Vishonar'},
        [80]={name='Localized service',subName='Localized title',friendlyToFaction='AH',questStarts={1},spawns={[36]={{25,60}}},waypoints={[36]={{25,60}}}},
        [81]={name='Hostile service',subName='Transmogrifier',spawns={[36]={{30,60}}}},
        [82]={name='Missing positions',subName='Transmogrifier',friendlyToFaction='AH'},
        [83]={name='Invalid positions',subName='Transmogrifier',friendlyToFaction='AH',spawns={[999]={{50,50}},[36]={{'bad',60},{-1,60},{25,101}}}},
    }
    LibQuestieDB={flavor={name='Forever'},RequireContract=function(v) return v==3 end,
        Support={Get=function() return {private={areaIdToUiMapId='return { [36]=1416, [1519]=1453, [1637]=1454 }'}} end},
        Npc={GetAllIds=function() return {270581,270513,270582,273057,80,81,82,83} end,
            Get=function(id,key) return records[id][key] end,GetRaw=function(id,key) if id==80 and key=='subName' then return 'Transmogrifier' end end}}
    local state=assert(P.Connect());while not P.Step(state,1) do end
    assert(#state.items==6 and state.counts.unmapped==4)
    local first,second,thaldris,monye,localized,hostile=unpack(state.items)
    assert(first.npcID==270581 and first.id~=second.id and first.uiMapID==1453 and first.mx==.3 and first.my==.4)
    assert(first.role=='Transmogrifier' and first.confidence=='provider' and first.source=='QuestieDB Forever')
    assert(second.phase==7 and not second.floor and thaldris.uiMapID==1416)
    assert(monye.uiMapID==1454 and monye.faction=='Horde' and monye.role=='Transmogrifier')
    assert(localized.categories.transmog and localized.categories.quest and localized.mobile and localized.faction=='Neutral')
    assert(not hostile.available and #N.Model.Search(state.items,'transmog',{},{faction='Alliance'})==4)
    assert(#N.Model.Search(state.items,'transmogrifier',{},{faction='Horde'})==2)
    assert(N.Model.Search(state.items,"Mon'ye",{},{faction='Horde'})[1]==monye)
    assert(P.Step(state,30) and #state.items==6,'a completed indexing pass cannot duplicate spawns')
    assert(records[270581].subName==nil and records[270582].subName=='','provider records stay read-only')
    LibQuestieDB=previous
end)

test('nearby stationary transmogrifier samples produce one search destination and retain route alternatives',function()
    local previous=LibQuestieDB;local P,M,R=N.Providers,N.Model,N.Routes
    local records={
        [270581]={name='Fyrenz Vishonar',friendlyToFaction='A',spawns={[1519]={{30,40},{30.02,40.02},{30.04,40.01}}}},
        [270513]={name='Spellweaver Thaldris',friendlyToFaction='A',spawns={[36]={{20,60},{20,60.2}}}},
        [270582]={name="Mon'ye",friendlyToFaction='H',spawns={[1637]={{40,50}}}},
    }
    LibQuestieDB={flavor={name='Forever'},RequireContract=function(v) return v==3 end,
        Support={Get=function() return {private={areaIdToUiMapId={[1519]=1453,[36]=1416,[1637]=1454}}} end},
        Npc={GetAllIds=function() return {270581,270513,270582} end,Get=function(id,key) return records[id][key] end}}
    local state=assert(P.Connect());while not P.Step(state,1) do end
    assert(#state.items==3 and state.counts.spawns==6,'raw samples remain counted without duplicate destinations')
    assert(state.items[1].id=='qdb:270581:1519:1' and state.items[1].mx==.3 and state.items[1].my==.4)
    assert(#records[270581].spawns[1519]==3 and #records[270513].spawns[36]==2,'provider records remain untouched')
    local ctx={faction='Alliance',speed=7,flightPrior=32,known={}}
    for _,query in ipairs({'transmog','transmogrifier','transmogrifiers','transmogrification'}) do
        assert(#M.Search(state.items,query,{},ctx)==2)
        assert(#M.Search(state.items,query,{categories={transmog=true}},ctx)==2)
    end
    local fyrenz=M.Search(state.items,'Fyrenz Vishonar',{},ctx);assert(#fyrenz==1)
    assert(#M.Search(state.items,'Spellweaver Thaldris',{},ctx)==1)
    assert(#M.Search(state.items,'',{categories={transmog=true}},ctx)==2)
    assert(#M.Search(state.items,'transmog',{},{faction='Horde'})==1)
    local origin={map=0,x=0,y=0};local data={nodes={},edges={}}
    local routes=R.Plan(origin,M.Search(state.items,'transmog',{},ctx),data,ctx)
    assert(#routes==2 and routes[1].destination.npcID~=routes[2].destination.npcID)
    local finish=M.Copy(fyrenz[1]);finish.x=finish.x-10
    data.nodes={[1]=origin,[2]=finish};data.edges={{id='test-flight',from=1,to=2,start=origin,finish=finish,mode='flight',distance=1000}}
    ctx.known={[1]={state='known'},[2]={state='known'}}
    routes=R.Plan(origin,fyrenz,data,ctx)
    assert(#routes==2 and M.RouteMode(routes[1])~=M.RouteMode(routes[2]),'real walk and flight choices survive consolidation')
    assert(U:SharedDestination(routes)==fyrenz[1])
    assert(P.Step(state,30) and #state.items==3,'repeated indexing does not restore discarded samples')
    LibQuestieDB=previous
end)

test('spawn consolidation preserves distant identities phases floors maps and mobile NPCs',function()
    local previous,fromMap=LibQuestieDB,A.FromMap;local P=N.Providers
    -- World-yard fixture isolates the five-yard boundary without map scaling.
    A.FromMap=function(map,x,y) return {map=map==3 and 1 or 0,uiMapID=map,x=x*100,y=y*100,floor=y>.5 and 2 or 1} end
    local records={
        [270581]={name='Same name',friendlyToFaction='A',spawns={
            [1]={{20,40},{24,40},{16,40},{20,40,7},{20,40,8},{20,60},{25.01,40}},
            [2]={{20,40}},[3]={{20,40}},[4]={{20,40}},
        }},
        [270513]={name='Same name',friendlyToFaction='A',spawns={[1]={{20,40}}}},
        [270582]={name='Same name',friendlyToFaction='H',spawns={[1]={{20,40}}}},
        [80]={name='Mobile',subName='Transmogrifier',friendlyToFaction='AH',spawns={[1]={{20,40},{20.01,40}}},waypoints={[1]={{20,40}}}},
        [81]={name='Different floor',subName='Transmogrifier',friendlyToFaction='AH',spawns={[1]={{20,49.9},{20,50.1}}}},
    }
    LibQuestieDB={flavor={name='Forever'},RequireContract=function(v) return v==3 end,
        Support={Get=function() return {private={areaIdToUiMapId={[1]=1,[2]=2,[3]=3,[4]=1}}} end},
        Npc={GetAllIds=function() return {270581,270513,270582,80,81} end,Get=function(id,key) return records[id][key] end}}
    local state=assert(P.Connect());while not P.Step(state,1) do end
    local kept={};for _,p in ipairs(state.items) do kept[p.id]=p end
    assert(#state.items==15 and state.counts.spawns==16)
    assert(kept['qdb:270581:1:1'] and not kept['qdb:270581:1:2'] and kept['qdb:270581:1:3'],'cluster diameter cannot grow through nearby chains')
    for _,index in ipairs({4,5,6,7}) do assert(kept['qdb:270581:1:'..index]) end
    for _,area in ipairs({2,3,4}) do assert(kept['qdb:270581:'..area..':1']) end
    assert(kept['qdb:270513:1:1'] and kept['qdb:270582:1:1'])
    assert(kept['qdb:80:1:1'].mobile and kept['qdb:80:1:2'].mobile)
    assert(kept['qdb:81:1:1'].floor~=kept['qdb:81:1:2'].floor)
    LibQuestieDB=previous;A.FromMap=fromMap
end)

test('corrected service identities tolerate malformed optional provider labels and waypoints',function()
    local previous=LibQuestieDB;local P=N.Providers
    for _,malformed in ipairs({true,false,17,{},'   '}) do
        local record={name=malformed,subName=malformed,waypoints=malformed,friendlyToFaction='A',spawns={[1519]={{30,40}}}}
        LibQuestieDB={flavor={name='Forever'},RequireContract=function(v) return v==3 end,
            Support={Get=function() return {private={areaIdToUiMapId='return { [1519]=1453 }'}} end},
            Npc={GetAllIds=function() return {270581} end,Get=function(_,key) return record[key] end,GetRaw=function() return malformed end}}
        local state=assert(P.Connect());assert(P.Step(state,2) and #state.items==1)
        local point=state.items[1];assert(point.name=='270581' and point.role=='Transmogrifier' and not point.mobile)
        assert(N.Model.Search(state.items,'transmog',{},{faction='Alliance'})[1]==point)
        assert(U:DestinationDetail(point):find('Transmogrifier',1,true))
    end
    LibQuestieDB=previous
end)

test('transmog results compare route select Go and interaction arrival through the current UI',function()
    local goal,start,cleanup=arrivalFixture();local profile=N.Model.Copy(C.profile);local profiles=C.profiles
    goal.npcID=270581;goal.name='Fyrenz Vishonar';goal.category='transmog';goal.role='Transmogrifier';goal.zone='Stormwind City';goal.faction='Alliance'
    local incidental=N.Model.Copy(goal);incidental.id='incidental-transmog';incidental.npcID=99;incidental.name='Transmog Collector';incidental.category='quest';incidental.role='Quest NPC';incidental.x=goal.x-399
    local horde=N.Model.Copy(goal);horde.id='wrong-faction';horde.npcID=270582;horde.name="Mon'ye";horde.faction='Horde'
    C.destinations={incidental,horde,goal};C:BindFilters();C:Filter('all');flushSearch()
    C:Search('transmog');flushSearch();assert(C.matches[1]==goal and #C.matches==2)
    C:Plan();assert(#C.results==1 and C.results[1].destination==goal and C.results[1].legs[1].quality=='bearing')
    for _,width in ipairs({220,240,640}) do for _,size in ipairs({10,18}) do for _,scale in ipairs({.75,1.5}) do
        setPreference(C,'width',width);setPreference(C,'fontSize',size);setPreference(C,'scale',scale);C:RefreshAppearance()
        assert(U.destinationName:GetText()=='Fyrenz Vishonar' and U.destinationDetail:GetText():find('Transmogrifier',1,true))
        assert(U.destinationName:GetWidth()<=width and U.go.text:GetUnboundedStringWidth()<=U.go:GetWidth())
    end end end
    C:Go();local route=C.nav.route;assert(route and route.destination.npcID==270581)
    C.query='';C:Filter('categories','transmog');flushSearch();assert(#C.matches==1 and C.matches[1]==goal and C.nav.route==route)
    local saved=N.Settings.Profiles(nil,C.profile);local reloaded=N.Settings.Profiles(saved)
    assert(reloaded.profiles.Default.searchFilters.categories.transmog,'reload retains the new checkbox')
    C:Filter('categories','quest');flushSearch();assert(#C.matches==2)
    C:Filter('all');flushSearch();assert(#C.matches==2 and not N.Model.HasFilter(C.filter))
    C:Stop();C.destination=nil;C:Filter('categories','transmog');flushSearch();U.go.scripts.OnClick()
    assert(#C.results==1 and C.results[1].destination==goal and not C.destination,'Compare matches plans the service category')
    C:Go();UnitGUID=function(unit) assert(unit=='npc');return 'Creature-0-1234-0-0-270581-000000ABCD' end
    dispatchEvent('GOSSIP_SHOW');assert(not C.nav.route and C.arrivalUntil)
    restorePreferences(C,profile);cleanup();C:BindFilters();C:RefreshAppearance()
end)
-- Re-load the real TOC into a fresh namespace with restored SavedVariables.
-- Keep these independent lifecycle checks last so earlier interaction fixtures
-- cannot accidentally supply a hidden flag or pre-created frame at startup.
local function boot(character,legacy,profiles,provider)
    timers={};frames={};SlashCmdList={};SLASH_ASTHECROWFLIES_SND_ATCF1=nil
    AsTheCrowFliesCharacter=N.Model.Copy(character)
    AsTheCrowFliesDB=N.Model.Copy(legacy)
    AsTheCrowFliesProfiles=N.Model.Copy(profiles)
    local fresh={}
    for _,name in ipairs(files) do assert(loadfile(ROOT..'/AsTheCrowFlies/'..name))('AsTheCrowFlies',fresh) end
    if provider then
        fresh.Providers.Connect=function() return {items={},ids={},cursor=1} end
        fresh.Providers.Step=function() return true end
    end
    local c=fresh.Core
    assert(not c.ready and not fresh.UI.frame,'frames must wait for restored SavedVariables')
    dispatchEvent('ADDON_LOADED','AnotherAddon');assert(not c.ready)
    dispatchEvent('ADDON_LOADED','AsTheCrowFlies');assert(c.ready)
    return fresh
end
local function flushLifecycle()
    for _=1,20 do
        if #timers==0 then return end
        local pending=timers;timers={};for _,fn in ipairs(pending) do fn() end
    end
    error('lifecycle callbacks did not settle')
end
local function indexingComparison(hasMatch)
    local fresh=boot(nil,nil,nil,true);local c=fresh.Core
    local goal=fresh.Model.Copy(fresh.Adapter.Position());goal.x=goal.x+100
    goal.id='indexed-auctioneer';goal.name='Indexed auctioneer';goal.category='auction'
    c.provider.ids={1};c.provider.cursor=1
    fresh.Providers.Step=function(provider)
        provider.items=hasMatch and {goal} or {};provider.cursor=2;return true
    end
    c.filter.categories.auction=true;c:Plan()
    assert(c.status=='Indexing NPC destinations...' and #c.results==0)
    return fresh,goal
end
test('provider completion finishes waiting comparisons with routes or final empty status',function()
    for _,hasMatch in ipairs({true,false}) do
        local fresh,goal=indexingComparison(hasMatch);local c=fresh.Core
        flushLifecycle()
        assert(c.providerStatus==nil and c.providerPlanGeneration==nil)
        if hasMatch then assert(#c.results==1 and c.results[1].destination==goal and not c.status)
        else assert(#c.results==0 and c.status=='No matching destinations.') end
        assert(c.hidden and not fresh.UI.frame:IsShown(),'completion respects panel visibility')
    end
end)
test('provider completion does not resurrect superseded comparisons',function()
    for _,action in ipairs({'edit','back','stop','choose','search'}) do
        local fresh,goal=indexingComparison(true);local c=fresh.Core
        if action=='edit' then c:Edit(true)
        elseif action=='back' then c:Back()
        elseif action=='stop' then c:Stop()
        elseif action=='choose' then c:Choose(goal,false)
        else c:Search('Indexed',false) end
        local generation=c.searchGeneration
        flushLifecycle()
        assert(#c.results==0 and c.providerPlanGeneration==nil,'abandoned comparison must not return: '..action)
        assert(c.searchGeneration==generation,'completion must not start another plan: '..action)
        if action=='choose' then assert(c.destination==goal)
        elseif action=='search' then assert(#c.matches==1 and c.matches[1]==goal) end
    end
end)
test('waiting comparison completion preserves active navigation',function()
    local fresh,goal=indexingComparison(true);local c=fresh.Core
    local p=fresh.Adapter.Position();local active=fresh.Model.Copy(p);active.x=p.x+300;active.id='active';active.name='Active destination'
    c:Choose(active);c:Plan();c:Go();local route=c.nav.route
    assert(route and route.destination==active)
    c.destination=nil;c:Plan();assert(c.status=='Indexing NPC destinations...')
    flushLifecycle()
    assert(#c.results==1 and c.results[1].destination==goal)
    assert(c.nav.route==route and c.character.intent=='active' and c.nav.state=='walking')
end)
local function hiddenLifecycle(fresh)
    local c,u=fresh.Core,fresh.UI
    local function check() assert(c.hidden and not u.frame:IsShown() and not u.handle:IsShown(),'hidden panel or tab reopened') end
    check()
    for _,event in ipairs({'PLAYER_LOGIN','PLAYER_ENTERING_WORLD','UI_SCALE_CHANGED','DISPLAY_SIZE_CHANGED','ADDON_LOADED','TAXIMAP_OPENED','TAXIMAP_CLOSED','GOSSIP_SHOW'}) do
        dispatchEvent(event,'LibSharedMedia-3.0');flushLifecycle();c:Tick();check()
    end
end
test('fresh and legacy startups stay hidden throughout login and provider completion',function()
    for _,character in ipairs({false,{version=1,build='1.60.1.70338',known={},timings={},places={}}}) do
        local fresh=boot(character or nil,{font='Arial',width=420,scale=.85},nil,true)
        local c,u=fresh.Core,fresh.UI
        hiddenLifecycle(fresh)
        assert(c.character.hidden==true and AsTheCrowFliesCharacter==c.character)
        assert(c.profile.font=='Arial' and c.profile.width==420 and c.profile.scale==.85)
        assert(not u.frame.showCount and not u.handle.showCount,'startup must never transiently reveal a panel or tab')
    end
end)
test('explicit hide survives logout reload and login with settings and character knowledge',function()
    local fresh=boot({version=1,build='1.60.1.70338',hidden=false,known={[90]={state='known',faction='Alliance'}},timings={trip={20,22}},places={}},
        {font='Arial',width=420,searchFilters={categories={transmog=true}}})
    SlashCmdList.ASTHECROWFLIES_SND_ATCF('show');assert(fresh.UI.frame:IsShown())
    SlashCmdList.ASTHECROWFLIES_SND_ATCF('hide');assert(AsTheCrowFliesCharacter.hidden==true)
    dispatchEvent('PLAYER_LOGOUT')
    local reloaded=boot(AsTheCrowFliesCharacter,AsTheCrowFliesDB,AsTheCrowFliesProfiles,true)
    hiddenLifecycle(reloaded)
    assert(reloaded.Core.profile.width==420 and reloaded.Core.profile.searchFilters.categories.transmog)
    assert(reloaded.Core.character.known[90].state=='known' and reloaded.Core.character.timings.trip[2]==22)
    assert(reloaded.Core.nav.route==nil,'reload must still stop navigation')
end)
test('show settings buttons and keybinding reveal update the durable visibility choice',function()
    local fresh=boot();local c,u,o=fresh.Core,fresh.UI,fresh.Options
    option(o,'position',6).scripts.OnClick();assert(u.frame:IsShown() and AsTheCrowFliesCharacter.hidden==false)
    option(o,'position',7).scripts.OnClick();assert(not u.frame:IsShown() and AsTheCrowFliesCharacter.hidden==true)
    AsTheCrowFlies_Toggle();assert(u.frame:IsShown() and not c.hidden and AsTheCrowFliesCharacter.hidden==false)
    local reloaded=boot(AsTheCrowFliesCharacter,AsTheCrowFliesDB,AsTheCrowFliesProfiles)
    assert(reloaded.UI.frame:IsShown() and reloaded.Core.character.hidden==false,'explicit show restores across login')
    reloaded.UI:SetDock(reloaded.Core,'right',true)
    assert(reloaded.UI.handle:IsShown() and AsTheCrowFliesCharacter.hidden==false,'tuck is separate from Hide')
    SlashCmdList.ASTHECROWFLIES_SND_ATCF('hide');assert(not reloaded.UI.handle:IsShown())
    SlashCmdList.ASTHECROWFLIES_SND_ATCF('show');assert(reloaded.UI.frame:IsShown() and not reloaded.Core.tucked)
end)
test('profile placement and options changes cannot reveal a hidden panel',function()
    local fresh=boot();local c,u,o=fresh.Core,fresh.UI,fresh.Options
    SlashCmdList.ASTHECROWFLIES_SND_ATCF('opts');assert(o.frame:IsShown());hiddenLifecycle(fresh)
    for _,entry in ipairs({{'DuplicateProfile','Other'},{'SwitchProfile','Default'},{'CopyProfile','Other'},{'ResetProfile'}}) do
        assert(fresh.App.profiles[({DuplicateProfile='Duplicate',SwitchProfile='Switch',CopyProfile='CopyFrom',ResetProfile='Reset'})[entry[1]]](fresh.App.profiles,entry[2]));hiddenLifecycle(fresh)
    end
    u:SetDock(c,'right',true);hiddenLifecycle(fresh)
    u:SetDock(c,'none',false);hiddenLifecycle(fresh)
    assert(c.character.hidden and AsTheCrowFliesCharacter.hidden)
end)
test('visibility survives build changes and invalid values default hidden without mutating future data',function()
    local s=N.Settings
    for _,value in ipairs({true,false}) do
        local saved={version=1,build='old',hidden=value,known={[90]={state='known'}},timings={trip={20}},places={}}
        local loaded=s.Character(saved,'new')
        assert(loaded.hidden==value and not next(loaded.known) and not next(loaded.timings))
    end
    for _,value in ipairs({0,'false',{},true}) do assert(s.Character({version=1,hidden=value},'new').hidden==true) end
    local future={version=99,hidden=true,unknown='keep'}
    local fresh=boot(future,{version=99,unknown='profile'},{version=99,unknown='store'})
    fresh.Core:ShowPanel(true)
    assert(AsTheCrowFliesCharacter.version==99 and AsTheCrowFliesCharacter.hidden==true and AsTheCrowFliesCharacter.unknown=='keep')
    assert(AsTheCrowFliesDB.version==99 and AsTheCrowFliesDB.unknown=='profile' and AsTheCrowFliesProfiles.version==99)
    local before=fresh.Core.profile.width
    local ok,err=fresh.App:SetMany({width=300,dock='right'});assert(not ok and err.code=='readOnly')
    assert(not fresh.App.profiles:Reset());assert(fresh.Core.profile.width==before)
    assert(AsTheCrowFliesDB.version==99 and AsTheCrowFliesProfiles.version==99)
end)
test('theme chrome preserves explicit colors and saved visibility',function()
    local fresh=boot();local c,u=fresh.Core,fresh.UI;local f=u.frame
    assert(f.template=='BackdropTemplate' and f.backdrop.edgeFile=='Interface\\Buttons\\WHITE8X8')
    assert(fresh.App:Set('theme','forever'));assert(f.backdrop.edgeFile=='Interface\\DialogFrame\\UI-DialogBox-Border')
    assert(f.borderColor[1]==fresh.SomethingNeedDoing.Themes.forever.colors.border[1])
    local sizes=f.nativeBackdropSizes or 0;f.scripts.OnSizeChanged(f,400,250);assert(f.nativeBackdropSizes==sizes+1)
    setPreference(c,'colors.background',{.2,.3,.4});assert(f.backdropColor[1]==.2 and f.backdropColor[4]==.94)
    assert(fresh.Options:Open());assert(u.menu.backdropColor[1]==.2 and fresh.Options.frame.backdropColor[1]~=.2)
    assert(c.hidden and not f:IsShown())
end)
test('button hover survives tooltip updates and releases on disable hide and menu close',function()
    local fresh=boot();local c,u=fresh.Core,fresh.UI;local button=u.pause
    c:ShowPanel(true);button:Show();button.scripts.OnEnter(button);assert(button.borderColor[1]==u.theme.colors.accent[1])
    local enter=button.scripts.OnEnter
    for _=1,20 do u:PauseIcon(c) end
    assert(button.scripts.OnEnter==enter,'guidance updates must not accumulate tooltip hooks')
    button:SetEnabled(false);assert(button.alpha==.5 and button.borderColor[1]==u.theme.colors.border[1])
    button:SetEnabled(true);assert(button.alpha==1 and button.borderColor[1]==u.theme.colors.accent[1])
    button:Hide();button:Show();assert(button.borderColor[1]==u.theme.colors.border[1] and not GameTooltip:IsShown())
    c.tucked=true;u:Layout(c);u.handle.scripts.OnEnter(u.handle);assert(u.handle.borderColor[1]==u.theme.colors.accent[1])
    c.tucked=false;u:Layout(c);c.tucked=true;u:Layout(c)
    assert(u.handle.borderColor[1]==u.theme.colors.border[1],'tucking again must not retain the previous hover')
    local o=fresh.Options;local font=option(o,'appearance',2);font.menuOpen=true;o:Open('profiles')
    assert(not font:IsMenuOpen(),'switching pages dismisses dropdowns owned by the hidden page')
end)

test('selection remains distinct from hover through search and route refreshes',function()
    local fresh=boot();local c,u=fresh.Core,fresh.UI;c:ShowPanel(true)
    local point=fresh.Adapter.Position();point.name='First';point.id='first';point.category='place'
    local other=fresh.Model.Copy(point);other.name='Second';other.id='second'
    c.matches={point,other};c.highlight=1;c:Refresh()
    local first,second=u.rows[1],u.rows[2]
    second.scripts.OnEnter(second);assert(first.atcfSelected and not second.atcfSelected)
    assert(first.backdropColor[1]~=second.backdropColor[1],'hover must not look selected')
    first.scripts.OnEnter(first);first.scripts.OnLeave(first);c:Refresh()
    assert(first.backdropColor[1]~=second.backdropColor[1],'refresh must retain selection fill')
    c.highlight=2;c:Refresh();assert(first.backdropColor[1]~=second.backdropColor[1] and second.atcfSelected)
    second.scripts.OnLeave(second);second:Hide();second:Show();assert(second.atcfSelected and second.backdropColor[1]~=first.backdropColor[1])
    local route=fresh.Routes.Summary({{mode='walk',start=point,finish=other,distance=50,seconds=10}},other,c:Context())
    c.matches=nil;c.results={route,route};c.selected=1;c:Refresh();second.scripts.OnEnter(second)
    assert(first.atcfSelected and not second.atcfSelected and first.backdropColor[1]~=second.backdropColor[1])
end)
test('navigation menu stays on screen at bottom edges and follows layout changes',function()
    local fresh=boot();local c,u=fresh.Core,fresh.UI;c:ShowPanel(true)
    -- Resolve the actual panel anchor in its local coordinates, not a fixed mock top.
    u.frame.GetTop=function(frame) return UIParent:GetHeight()/frame:GetScale()+frame.point[5] end
    for _,screen in ipairs({{1920,1080},{960,360}}) do
        UIParent:SetSize(unpack(screen))
        for _,uiScale in ipairs({.85,1}) do
            UIParent:SetScale(uiScale)
            for _,panelScale in ipairs({.5,1,1.6}) do
                setPreference(c,'scale',panelScale)
                for _,side in ipairs({'none','left','right'}) do
                    setPreference(c,'dock',side);setPreference(c,'dockPosition',1);setPreference(c,'y',-10000);c.tucked=false;c:Refresh()
                    u.menu:Hide();u.settings.scripts.OnClick();assert(u.menu:IsShown() and u.menu.clamped)
                    local top=u.frame:GetTop()+u.menu.point[5]
                    local available=UIParent:GetHeight()/u.frame:GetScale()
                    assert(top<=available and top-u.menu:GetHeight()>=0,'all menu actions must remain on-screen')
                    setPreference(c,'dock','none');setPreference(c,'y',0);c:Refresh()
                    assert(u.menu.point[5]==-40,'normal placement must recover while the menu stays open')
                end
            end
        end
    end
    UIParent:SetScale(1);UIParent:SetSize(1920,1080)
end)
test('short options preserve type size and expose every control through scroll navigation',function()
    local fresh=boot();local o=fresh.Options;local panel=o.panel
    UIParent:SetSize(960,360);local font=option(o,'appearance',2)
    assert(panel.frame:GetScale()==1 and panel.frame:GetHeight()==344 and font.Text:GetScale()==1)
    assert(font.Text.fontSize==13 and panel._maximum>0 and panel.bar:IsShown())
    assert(font.parent==panel.body and panel.body.parent==panel.scroll)
    font.menuOpen=true;panel.scroll.scripts.OnMouseWheel(nil,-1)
    assert(panel.scroll:GetVerticalScroll()==30 and not font:IsMenuOpen())
    assert(o:Open('profiles'));local name=panel._pool['profile-name'];name:SetFocus()
    local active=panel._pool['profile-select'];active.menuOpen=true
    assert(o:Open('appearance'));assert(not name:HasFocus() and not active:IsMenuOpen())
    for _,page in ipairs({'appearance','navigation','position','profiles'}) do assert(o:Open(page)) end
    local framesBefore=#frames
    for _,screen in ipairs({{960,360},{600,400},{1920,1080}}) do
        UIParent:SetSize(unpack(screen))
        for _,scale in ipairs({.85,.9,1}) do
            UIParent:SetScale(scale);dispatchEvent('DISPLAY_SIZE_CHANGED')
            for _,page in ipairs({'appearance','navigation','position','profiles'}) do
                assert(o:Open(page));panel.bar:SetValue(panel._maximum)
                assert(panel.frame:GetWidth()*panel.frame:GetScale()<=screen[1]-16+.001)
                assert(panel.frame:GetHeight()*panel.frame:GetScale()<=screen[2]-16+.001)
                assert(panel.body:GetHeight()-panel.scroll:GetVerticalScroll()<=panel.scroll:GetHeight()+.001)
            end
            assert(font.Text:GetScale()==1)
        end
    end
    assert(#frames==framesBefore,'page changes and layout reuse controls')
    UIParent:SetScale(1);UIParent:SetSize(1920,1080);panel:Close()
end)
test('dropdown captions retain readable UTF8 text and complete selected identities',function()
    local fresh=boot();local c,o=fresh.Core,fresh.Options;local font=option(o,'appearance',2)
    for _,uiScale in ipairs({.75,.85,.9,1,1.25}) do
        UIParent:SetScale(uiScale)
        for _,name in ipairs({string.rep('W',48),string.rep('界',16),string.rep('W',128)}) do
            assert(fresh.App:Set('font',name));assert(o.panel:Refresh())
            local caption=font.Text:GetText()
            assert(fresh.App:Get('font')==name and font._fullCaption==name and font.Text:GetScale()==1)
            assert(caption:sub(-3)=='...' and #caption<#name and caption:sub(1,-4)==name:sub(1,#caption-3))
            if name:sub(1,3)=='界' then assert((#caption-3)%3==0) end
            assert(font.Text:GetUnboundedStringWidth()<=font.Text:GetWidth())
            font.scripts.OnEnter(font);assert(GameTooltip:GetOwner()==font and GameTooltip:GetText()==name)
            font.scripts.OnLeave(font);assert(not GameTooltip:IsShown())
            font.Text:SetText(name);assert(font.Text:GetText()==caption and font._fullCaption==name)
        end
    end
    UIParent:SetScale(1)
    local name=string.rep('P',48);assert(fresh.App.profiles:Duplicate(name));assert(o:Open('profiles'))
    local active=o.panel._pool['profile-select'];assert(fresh.App.profiles:Active()==name and active._fullCaption==name)
    assert(active.Text:GetScale()==1 and active.Text:GetText():sub(-3)=='...')
    assert(fresh.App.profiles:Switch('Default'));assert(active.Text:GetText()=='Default')
    assert(o:Open('appearance'));assert(fresh.App:Set('font','Arial'));assert(font.Text:GetText()=='Arial' and not font._truncated)
end)

-- Logout must cancel the consumer ticker once, before SND disposes its scope.
test('scoped logout cancels navigation ticker before SND shutdown',function()
    local fresh=boot(nil,nil,nil);local c=fresh.Core;local cancelled=0
    c.ticker.Cancel=function() assert(fresh.App:IsReady());cancelled=cancelled+1 end
    dispatchEvent('PLAYER_LOGOUT');dispatchEvent('PLAYER_LOGOUT')
    assert(cancelled==1 and not fresh.App:IsReady() and not SlashCmdList.ASTHECROWFLIES_SND_ATCF)
    local changed=0;c.RefreshAppearance=function() changed=changed+1 end
    dispatchEvent('UI_SCALE_CHANGED');assert(changed==0)
end)

print('PASS runtime scenarios: '..count..'; frames allocated='..#frames)
