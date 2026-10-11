local ADDON,N=...;local M,A,R,V=N.Model,N.Adapter,N.Routes,N.Navigation
local C={nav=V.New(),destinations={},filter={categories={},classes={},professions={}},results={},selected=1,searchGeneration=0};N.Core=C
function C:BindFilters(refresh)
    self.profile.searchFilters=self.profile.searchFilters or {categories={},classes={},professions={}}
    self.filter=self.profile.searchFilters
    if refresh then
        if self.matches~=nil or self.searching then self:Search(self.searchOrigin and self.originQuery or self.query or "",self.searchOrigin)
        elseif #self.results>0 then self:Plan() end
    end
end
function C:Filter(group,key)
    local f=self.filter
    if group=="all" then f.categories={};f.classes={};f.professions={}
    elseif group=="categories" then
        f.categories[key]=not f.categories[key] or nil
        if key=="class" and f.categories[key] and not next(f.classes) and self.ctx.class then f.classes[self.ctx.class]=true end
        if not f.categories[key] and key=="class" then f.classes={} end
        if not f.categories[key] and key=="profession" then f.professions={} end
    else
        f.categories[group=="classes" and "class" or "profession"]=true
        if key=="all" then f[group]={} else f[group][key]=not f[group][key] or nil end
    end
    self.destination=nil;self:Edit(true);self:Search(self.query or "",false)
end
function C:Context()
    self.ctx=A.Context(self.ctx and self.ctx.speed);self.ctx.known=self.character.known;self.ctx.timings=self.character.timings;self.ctx.flightPrior=self.profile.flightPrior;self.ctx.requireObserved=true
    self.ctx.routeOrder=self.profile.routeOrder
    self.ctx.taxiFrom=self.taxi and self.taxi.from or nil
    return self.ctx
end
function C:Reindex()
    self.destinations={}
    for _,p in ipairs(self.provider and self.provider.items or {}) do self.destinations[#self.destinations+1]=p end
    for _,p in ipairs(self.character.places) do self.destinations[#self.destinations+1]=p end
    for id,p in pairs(self.data.nodes) do
        local known=self.character.known[id]
        if known and known.state=="known" then self.destinations[#self.destinations+1]=p end
    end
end
function C:Refresh()
    if N.UI.frame then N.UI:Refresh(self) end
    if self.ready then N.Overlay:Update(self,A.Position(),self.ctx or self:Context()) end
end
function C:RefreshAppearance(retryFonts)
    if self.refreshingAppearance then return end;self.refreshingAppearance=true
    if retryFonts then N.UI:ResetFonts() end
    for _=1,3 do
        local revision=N.UI.fontRevision
        N.UI:RefreshFonts()
        if N.Options.frame then N.Options:Refresh(true) end
        -- Menu generation or native widget states can replace a font. Repair
        -- those after updating controls, then measure with the settled family.
        N.UI:RefreshFonts();N.UI:ApplyAppearance();self:Refresh()
        if N.Options.frame then N.Options:Layout() end
        if revision==N.UI.fontRevision then break end
    end
    self.refreshingAppearance=false
end
function C:ApplyProfile()
    if not self.readOnly then AsTheCrowFliesDB=self.profile end
    self:RefreshAppearance(true)
end
function C:SetRouteOrder(value)
    if value~="distance" and value~="time" then return false end
    if self.profile.routeOrder==value then return true end
    self.profile.routeOrder=value
    if #self.results>0 then self:Plan() end
    self:ApplyProfile()
    return true
end
function C:ShowPanel(show)
    self.hidden=not show;if show then self.tucked=false end
    if N.UI.menu then N.UI.menu:Hide() end
    for _,d in ipairs(N.UI.dropdowns or {}) do d:CloseMenu() end
    self:Refresh()
end
function C:Edit(preserveNavigation)
    if not preserveNavigation then self.manualPause=false;V.Stop(self.nav);self.character.intent=nil;self.chosenFlight=nil;N.Overlay:Clear() end
    self.searchGeneration=self.searchGeneration+1;self.matches=nil;self.searching=nil;self.planned=nil
    self.compact=false;self.results={};self:Refresh()
end
function C:Back()
    if N.UI.filterButton and N.UI.filterButton:IsMenuOpen() then N.UI.filterButton:CloseMenu();return end
    if N.UI.menu and N.UI.menu:IsShown() then N.UI.menu:Hide();return end
    if N.Options.frame and N.Options.frame:IsShown() then N.Options.frame:Hide();return end
    self.searchGeneration=self.searchGeneration+1;self.searching=nil;self.planned=nil;N.UI.from:ClearFocus();N.UI.to:ClearFocus();self.status=nil
    if self.compact then self.compact=false
    elseif #self.results>0 then self.results={};self.destination=nil;self:Search(self.query or "",false)
    elseif self.matches then self.matches=nil
    elseif self.destination or self.origin then
        if self.origin and (self.lastSelection=="origin" or not self.destination) then local name=self.origin.name;self.origin=nil;self:Search(name or "",true)
        else self.destination=nil;self:Search(self.query or "",false) end
        self.lastSelection=nil
    elseif self.nav.route then self.compact=true
    else self.tucked=true end
    self:Refresh()
end
function C:SearchPosition(origin)
    return not origin and self.origin or A.Position()
end
function C:Search(query,origin)
    if origin then self.originQuery=query else self.query=query end
    self.searchGeneration=self.searchGeneration+1;local generation=self.searchGeneration;self.matches=nil;self.results={};self.searching=true;self.searchOrigin=origin;self:Refresh()
    local function run()
        if generation~=self.searchGeneration then return end
        self.searching=nil;self.matches=M.Search(self.destinations,query,origin and {} or self.filter,self:Context(),40,self:SearchPosition(origin));self.highlight=1;self.searchOrigin=origin;self.status=nil;self:Refresh()
    end
    if C_Timer and C_Timer.After then C_Timer.After(.12,run) else run() end
end
function C:Choose(p,origin)
    if not p then return end
    self.searchGeneration=self.searchGeneration+1;self.matches=nil;self.searching=nil
    if origin then self.origin=p;self.lastSelection="origin" else self.destination=p;self.lastSelection="destination" end
    self.results={};self:Refresh()
end
function C:Enter()
    if self.matches and self.matches[self.highlight or 1] then self:Choose(self.matches[self.highlight or 1],self.searchOrigin);return "selected" end
    self:Plan()
    return "planned"
end
function C:PrimaryActionLabel()
    if self.searchOrigin and (self.matches~=nil or self.searching) then return "Use origin" end
    if not self.destination and M.HasFilter(self.filter) then return "Compare matches" end
    return "Find routes"
end
function C:PrimaryAction()
    if self.searching then return end
    if self.searchOrigin and self.matches~=nil then
        local origin=self.matches[self.highlight or 1]
        self.status=nil
        if origin then self:Choose(origin,true);return "selected" end
        self:Refresh();return
    end
    if not self.destination and M.HasFilter(self.filter) then self:Plan();return "planned" end
    if self.matches and self.matches[self.highlight or 1] then self:Choose(self.matches[self.highlight or 1],false) end
    self:Plan()
    return "planned"
end
function C:Plan(useCurrent)
    self.searchGeneration=self.searchGeneration+1;self.matches=nil;self.searching=nil;self.planned=true;self.status=nil
    local origin=not useCurrent and self.origin or A.Position()
    if useCurrent then self.origin=nil end
    local candidates,ranks
    if self.destination then candidates={self.destination}
    else
        candidates,ranks=M.Search(self.destinations,self.query or "",self.filter,self:Context())
        if (self.query or ""):find("%S") and candidates[1] and ranks then
            local best=ranks[candidates[1]];local preferred={}
            for _,p in ipairs(candidates) do if ranks[p]==best then preferred[#preferred+1]=p end end;candidates=preferred
        end
    end
    if not self.destination and not M.HasFilter(self.filter) and not (self.query or ""):find("%S") then self.results={};self.status="Choose a destination or filter";self:Refresh();return end
    if #candidates==0 then
        local categories=self.filter.categories or {};local npc=not M.HasFilter(self.filter)
        for key in pairs(categories) do if key~="place" and key~="flight" then npc=true end end
        self.results={};self.status=npc and not self.provider and "NPC search requires Forever QuestieDB." or npc and type(self.provider.ids)=="table" and self.provider.cursor<=#self.provider.ids and "Indexing NPC destinations..." or "No matching destinations."
        self:Refresh();return
    end
    local capped;candidates,capped=R.Candidates(origin,candidates,self.data,self:Context(),12)
    self.results,self.status=R.Plan(origin,candidates,self.data,self:Context());self.selected=1
    self.categoryCapped=capped;self.categoryCompared=#candidates
    if not self.nav.route then self.nav.state="results" end
    self:Refresh()
end
function C:Go()
    if self.results[self.selected] and self.results[self.selected].unavailable then self.status="Discover the required flight points first.";self:Refresh();return end
    if self.origin then self:Plan(true);self.status="Recalculated from current location. Review, then Go.";self:Refresh();return end
    local r=self.results[self.selected];local p=A.Position()
    if V.Start(self.nav,r,p,GetTime()) then
        self.manualPause=false
        self.character.intent=r.destination.id;self.compact=true;self.chosenFlight=nil
        if self.taxi then self:TaxiOpened() end
    else self.status=self.nav.message or "Choose a route first" end
    self:Refresh()
end
function C:Stop() self:Edit();self.status=nil;self:Refresh() end
function C:TaxiOpened()
    local p=A.Position();if not p then return end
    A.ObserveMap(p.uiMapID,self.character,self.data.nodes)
    local observation=A.Taxi(p.uiMapID,self.character,self.data);self.taxi=observation
    if not observation then
        self:Reindex();if #self.results>0 then self:Plan() else self:Refresh() end;return
    end
    -- Runtime master proximity is a sanity check against coordinate/axis mistakes.
    local node=self.data.nodes[observation.from]
    if not node or (M.Distance(p,node) or math.huge)>150 then
        self.taxi=nil;self:Reindex();if #self.results>0 then self:Plan() end
        self.status="Flight-master position could not be reconciled";self:Refresh();return
    end
    node.uiMapID=p.uiMapID
    -- An offered whole itinerary can include fly-through nodes the player has
    -- never discovered. Store it as one observed edge, never split its timing.
    local edges={};for _,edge in ipairs(self.data.edges) do if not edge.live then edges[#edges+1]=edge end end
    for to,offer in pairs(observation.offers) do
        if self.data.nodes[to] then
            self.character.known[to]={state="known",faction=self.data.nodes[to].faction or self.ctx.faction}
            edges[#edges+1]={id="offered:"..offer.key,from=offer.from,to=offer.to,start=node,finish=self.data.nodes[to],mode="flight",distance=offer.distance,geometry=offer.geometry,offered=true,live=true,timingKey=offer.key}
        end
    end
    self.character.known[observation.from]={state="known",faction=node.faction or self.ctx.faction};self.data.edges=edges;self:Reindex()
    local route=self.nav.route
    if route then
        local start=self.nav.leg;if route.legs[start] and route.legs[start].mode=="walk" then start=start+1 end
        local finish=start;while route.legs[finish+1] and route.legs[finish+1].mode=="flight" do finish=finish+1 end
        local first,last=route.legs[start],route.legs[finish]
        if first and last and first.mode=="flight" and first.from==observation.from then
            local offer=observation.offers[last.to]
            if offer then
                local edge={id="offered:"..offer.key,from=offer.from,to=offer.to,start=self.data.nodes[offer.from],finish=self.data.nodes[offer.to],mode="flight",distance=offer.distance,geometry=offer.geometry,offered=true,timingKey=offer.key,seconds=N.Settings.Timing(self.character.timings,offer.key) or offer.distance/self.profile.flightPrior}
                for _=start,finish do table.remove(route.legs,start) end;table.insert(route.legs,start,edge)
                N.Overlay.pathKey=nil
                self.expected=offer;self.nav.leg=start;self.nav.state="awaiting_flight"
            else self.expected=nil;self.nav.state="unavailable";self.nav.message="This flight is not offered here; recalculate" end
        end
    end
    if #self.results>0 then self:Plan() else self:Refresh() end
end
function C:TaxiSelected(slot)
    if not self.taxi or not self.nav.route then return end
    self.chosenFlight=nil
    for _,offer in pairs(self.taxi.offers) do if offer.slot==slot then self.chosenFlight={from=offer.from,to=offer.to,at=GetTime(),key=offer.key} end end
end
function C:Tick()
    if not self.ready then return end
    local ctx=self:Context();local p=A.Position();local now=GetTime()
    local chosen=self.chosenFlight
    if chosen and not self.nav.flightSeen and self.nav.state~="flying" and now-chosen.at>10 then self.chosenFlight=nil;chosen=nil end
    local sample
    if self.manualPause then self.nav.measure=nil end
    if not self.manualPause or ctx.onTaxi or self.nav.flightSeen then sample=V.Update(self.nav,p,now,ctx.onTaxi,ctx.dead,chosen) end
    if self.manualPause then self.nav.measure=nil;sample=nil end
    if sample then N.Settings.Sample(self.character.timings,sample.key,sample.seconds);self.chosenFlight=nil end
    if self.nav.state=="arrived" then self.character.intent=nil end
    N.UI:Guidance(self,p,ctx,now);N.Overlay:Update(self,p,ctx)
end
function C:Initialize()
    self.build=A.Build();self.profile,self.readOnly=N.Settings.Load(AsTheCrowFliesDB,self.build)
    self.profiles,self.profilesReadOnly=N.Settings.Profiles(AsTheCrowFliesProfiles,self.profile)
    self.readOnly=self.readOnly or self.profilesReadOnly
    self.profile=self.profiles.profiles[self.profiles.active]
    self:BindFilters()
    if not self.readOnly then AsTheCrowFliesProfiles=self.profiles end
    if not self.readOnly then AsTheCrowFliesDB=self.profile end
    local futureCharacter=type(AsTheCrowFliesCharacter)=="table" and type(AsTheCrowFliesCharacter.version)=="number" and AsTheCrowFliesCharacter.version>1
    self.character=N.Settings.Character(AsTheCrowFliesCharacter,self.build)
    if not futureCharacter then AsTheCrowFliesCharacter=self.character end
    self.data={nodes={},edges={}}
    local localData=N.Data.LocalTaxi
    if localData and localData.build==self.build then
        self.data=M.Copy(localData)
        for _,p in pairs(self.data.nodes) do
            local known=self.character.known[p.id];if known then p.faction=known.faction end
            local map,v
            if CreateVector2D then map,v=A.Call(C_Map and C_Map.GetMapPosFromWorldPos,p.map,CreateVector2D(p.x,p.y)) end
            if A.Number(map) then p.uiMapID=map;local x,y=A.XY(v);p.mx,p.my=x,y end
        end
        for _,e in ipairs(self.data.edges) do e.start=self.data.nodes[e.from];e.finish=self.data.nodes[e.to] end
    end
    for _,id in ipairs(self.data.taxiMaps or {}) do A.ObserveMap(id,self.character,self.data.nodes) end
    self:Context();self:Reindex();self.ready=true
    N.UI:Create(self);N.Overlay:Create();N.Options:Create(self)
    N.UI:WatchFonts();self:RefreshAppearance(false)
    self.status=self.character.intent and "Previous route stopped on reload. Choose a destination to resume." or nil
    if self.build~=N.Data.build then self.status="Unvalidated client build: flight data disabled" end
    self:Refresh()
    if hooksecurefunc and TakeTaxiNode then hooksecurefunc("TakeTaxiNode",function(slot) self:TaxiSelected(slot) end) end
    self.ticker=C_Timer.NewTicker(.25,function() self:Tick() end)
    local provider,message=N.Providers.Connect();self.provider=provider;self.providerStatus=message or "Indexing Forever NPCs..."
    if provider then
        local function step()
            local done=N.Providers.Step(provider,40)
            if done then
                self:Reindex();self.providerStatus=nil
                if self.matches~=nil then self:Search(self.searchOrigin and self.originQuery or self.query or "",self.searchOrigin) else self:Refresh() end
            else C_Timer.After(.01,step) end
        end
        C_Timer.After(.1,step)
    end
end
local frame=CreateFrame("Frame");C.events=frame
for _,event in ipairs({"ADDON_LOADED","TAXIMAP_OPENED","TAXIMAP_CLOSED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LOGOUT","UI_SCALE_CHANGED","DISPLAY_SIZE_CHANGED"}) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent",function(_,event,arg)
    if event=="ADDON_LOADED" and arg==ADDON then C:Initialize()
    elseif C.ready then
        if event=="ADDON_LOADED" then N.UI:WatchFonts()
        elseif event=="TAXIMAP_OPENED" then C:TaxiOpened()
        elseif event=="TAXIMAP_CLOSED" then
            C.taxi=nil;for _,edge in ipairs(C.data.edges) do if edge.live then edge.offered=false end end
            local function invalidate(route)
                if route then for _,edge in ipairs(route.legs) do if edge.mode=="flight" then edge.offered=false;route.conditional=true end end end
            end
            for _,route in ipairs(C.results) do invalidate(route) end;invalidate(C.nav.route);C:Refresh()
        elseif event=="PLAYER_LOGIN" then
            C_Timer.After(0,function() C:RefreshAppearance(false) end)
        elseif event=="PLAYER_ENTERING_WORLD" then
            C.nav.measure=nil;C.nav.previous=nil
            local p=A.Position();if p then A.ObserveMap(p.uiMapID,C.character,C.data.nodes);C:Reindex();if #C.results>0 then C:Plan() end end
            C:RefreshAppearance(false)
        elseif event=="PLAYER_LOGOUT" then if C.ticker then C.ticker:Cancel() end
        elseif event=="UI_SCALE_CHANGED" or event=="DISPLAY_SIZE_CHANGED" then C:RefreshAppearance(false) end
    end
end)
SLASH_ASTHECROWFLIES1="/atcf"
SlashCmdList.ASTHECROWFLIES=function(text)
    if not C.ready then return end
    local cmd,rest=(text or ""):match("^%s*(%S*)%s*(.-)$");cmd=cmd:lower()
    if cmd=="stop" then C:Stop()
    elseif cmd=="" or cmd=="options" or cmd=="opts" then N.Options:Open()
    elseif cmd=="hide" then C:ShowPanel(false)
    elseif cmd=="show" then C:ShowPanel(true)
    elseif cmd=="remember" then
        local point=N.Providers.Remember(C.character,A.Position(),rest~="" and rest or (GetZoneText() or "Saved place"))
        C:Reindex();C.status=point and "Location saved" or "Location unavailable";C:Refresh()
    else C.status="Use /atcf options, show, hide or stop.";C:Refresh() end
end
N.Toggle=function() if C.ready then N.UI:Toggle(C) end end
_G.AsTheCrowFlies_Toggle=N.Toggle
