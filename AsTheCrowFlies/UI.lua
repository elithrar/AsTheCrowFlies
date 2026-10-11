local _,N=...;local M=N.Model;local U={texts={}};N.UI=U
local MEDIA="Interface\\AddOns\\AsTheCrowFlies\\Media\\"
local accent={.78,.85,.61};local ink={.93,.94,.97}
function U:Font(object,size)
    local path=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local pref=self.owner and self.owner.profile.font or "Expressway"
    local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
    if pref=="Arial" then path="Fonts\\ARIALN.TTF"
    elseif lsm and lsm:IsValid("font",pref) then path=lsm:Fetch("font",pref) end
    local ok,result=pcall(object.SetFont,object,path,size,"")
    if not ok or result==false then object:SetFontObject(GameFontNormal) end
    self.texts[#self.texts+1]={object,size};return object
end
function U:Text(parent,text,size,x,y,width,height)
    local t=parent:CreateFontString(nil,"OVERLAY");self:Font(t,size or 12)
    t:SetPoint("TOPLEFT",x or 0,y or 0);t:SetSize(width or 100,height or 20)
    t:SetJustifyH("LEFT");t:SetJustifyV("MIDDLE");t:SetTextColor(unpack(ink));t:SetShadowColor(0,0,0,.65);t:SetShadowOffset(1,-1);t:SetWordWrap(false);t:SetText(text or "")
    return t
end
function U:Surface(f,color)
    local bg=f:CreateTexture(nil,"BACKGROUND");bg:SetTexture(MEDIA.."surface.tga");bg:SetAllPoints(f);bg:SetVertexColor(unpack(color or {.045,.048,.062,.97}));return bg
end
function U:Button(parent,label,x,y,w,h,callback)
    local b=CreateFrame("Button",nil,parent);b:SetPoint("TOPLEFT",x,y);b:SetSize(w,h or 28)
    local inset=w<40 and 2 or 8
    b.bg=self:Surface(b,{.13,.14,.17,1});b.text=self:Text(b,label,12,inset,0,w-inset*2,h or 28);b.text:SetJustifyH("CENTER")
    b:SetScript("OnClick",callback);b:SetScript("OnEnter",function() b.bg:SetVertexColor(.22,.24,.28,1) end);b:SetScript("OnLeave",function() b.bg:SetVertexColor(.13,.14,.17,1) end)
    return b
end
function U:Tip(frame,text)
    frame:SetScript("OnEnter",function() GameTooltip:SetOwner(frame,"ANCHOR_RIGHT");GameTooltip:SetText(text,nil,nil,nil,nil,true);GameTooltip:Show() end)
    frame:SetScript("OnLeave",function() GameTooltip:Hide() end)
end
function U:Menu(parent,x,y,w,label,entries,choose)
    local d=CreateFrame("DropdownButton",nil,parent,"WowStyle1DropdownTemplate");d:SetPoint("TOPLEFT",x,y);d:SetSize(w,28);d:SetDefaultText(label)
    if d.Text then self:Font(d.Text,12);d.Text:SetWordWrap(false) end
    d:SetupMenu(function(_,root)
        root:SetScrollMode(280)
        for _,entry in ipairs(entries()) do
            root:CreateRadio(entry.label,function() return d.value==entry.value end,function() d.value=entry.value;d:SetDefaultText(entry.label);choose(entry.value) end)
        end
    end)
    return d
end
function U:Edit(parent,label,y,origin)
    self:Text(parent,label,11,14,y,48,32):SetTextColor(.65,.68,.73)
    local e=CreateFrame("EditBox",nil,parent);e:SetPoint("TOPLEFT",62,y);e:SetSize(self.owner.profile.width-102,32);e:SetAutoFocus(false);e:SetMaxLetters(100)
    self:Surface(e,{.09,.10,.125,1});self:Font(e,13);e:SetTextInsets(8,8,0,0)
    e:SetScript("OnTextChanged",function(_,user)
        if user then
            self.owner:Edit()
            if origin then self.owner.origin=nil else self.owner.destination=nil end
            self.owner:Search(e:GetText(),origin)
        end
    end)
    e:SetScript("OnEnterPressed",function()
        if self.owner:Enter()=="selected" then local point=origin and self.owner.origin or self.owner.destination;e:SetText(point and point.name or "");e:SetFocus()
        else e:ClearFocus() end
    end)
    e:SetScript("OnEscapePressed",function() self.owner.searchGeneration=self.owner.searchGeneration+1;self.owner.matches=nil;e:ClearFocus();self.owner:Refresh() end)
    e:SetScript("OnArrowPressed",function(_,key)
        local c=self.owner;if c.matches and #c.matches>0 then c.highlight=math.max(1,math.min(#c.matches,(c.highlight or 1)+(key=="UP" and -1 or 1)));c:Refresh() end
    end)
    e:SetScript("OnEditFocusLost",function() e:HighlightText(0,0) end)
    return e
end
function U:Create(c)
    self.owner=c;local f=CreateFrame("Frame","AsTheCrowFliesPanel",UIParent);self.frame=f
    f:SetMovable(true);f:EnableMouse(true);f:SetClampedToScreen(true);f:SetFrameStrata("MEDIUM");self:Surface(f)
    local header=CreateFrame("Frame",nil,f);header:SetPoint("TOPLEFT");header:SetPoint("TOPRIGHT");header:SetHeight(42);header:EnableMouse(true);header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function() if not c.profile.locked then f:StartMoving() end end)
    header:SetScript("OnDragStop",function()
        f:StopMovingOrSizing()
        local left,top=f:GetLeft(),f:GetTop();local scale=f:GetScale();local screen=UIParent:GetWidth()/scale
        c.profile.x=left;c.profile.y=top-UIParent:GetHeight()/scale;c.profile.dock=left<24 and "left" or (left+c.profile.width>screen-24 and "right" or "none")
        self:Layout(c)
    end)
    local eagle=header:CreateTexture(nil,"ARTWORK");eagle:SetTexture(MEDIA.."eagle.tga");eagle:SetPoint("TOPLEFT",14,-11);eagle:SetSize(24,24);eagle:SetVertexColor(unpack(accent))
    self.title=self:Text(header,"AS THE CROW FLIES",11,46,-11,184,24)
    self.settings=self:Button(f,"...",c.profile.width-56,-9,22,24,function() N.Options.frame:SetShown(not N.Options.frame:IsShown()) end)
    self.tuck=self:Button(f,"<",c.profile.width-30,-9,20,24,function() c.tucked=true;self:Layout(c) end)
    self:Tip(self.tuck,"Tuck to screen edge. The handle restores this panel.")
    self.editor=CreateFrame("Frame",nil,f);self.editor:SetPoint("TOPLEFT",0,-45);self.editor:SetPoint("TOPRIGHT",0,-45);self.editor:SetHeight(151)
    self.from=self:Edit(self.editor,"From",0,true);self.to=self:Edit(self.editor,"To",-40,false)
    self.current=self:Button(self.editor,"@",c.profile.width-34,-2,22,28,function() c:Edit();c.origin=nil;self.from:SetText("Current location");c:Refresh() end)
    self:Tip(self.current,"Reset origin to your current location")
    self.category=self:Menu(self.editor,14,-81,c.profile.width-28,"Destination category",function() return {
        {label="All destinations",value="all"},{label="Auction houses",value="auction"},{label="Class trainer",value="class"},{label="Profession trainer",value="profession"},{label="Other / unknown trainers",value="trainer"},{label="Quest NPC",value="quest"},{label="Flight point",value="flight"},{label="Saved places",value="place"}}
    end,function(value)
        c:Edit();c.filter={category=value};c.query="";c.destination=nil;self.to:SetText("");c:Search("",false);c:Refresh()
    end)
    self.specialization=self:Menu(self.editor,14,-115,c.profile.width-28,"Choose specialization",function()
        local list={};local values=c.filter.category=="class" and N.Providers.classes or N.Providers.professions
        for _,v in ipairs(values) do list[#list+1]={label=v,value=v} end;return list
    end,function(value)
        c:Edit();c.destination=nil;if c.filter.category=="class" then c.filter.class=value else c.filter.profession=value end;c:Search("",false)
    end)
    self.body=CreateFrame("Frame",nil,f);self.body:SetPoint("TOPLEFT",14,-200);self.body:SetWidth(c.profile.width-28)
    self.rows={}
    for i=1,3 do
        local b=self:Button(self.body,"",0,-(i-1)*83,c.profile.width-28,77,function()
            if c.matches then local index=(c.matchOffset or 0)+i;c:Choose(c.matches[index],c.searchOrigin)
            else c.selected=i;c:Refresh() end
        end)
        b.text:Hide();b.name=self:Text(b,"",13,10,-6,c.profile.width-50,21)
        b.detail=self:Text(b,"",11,10,-27,c.profile.width-50,41);b.detail:SetWordWrap(true)
        self.rows[i]=b
    end
    self.body:EnableMouseWheel(true);self.body:SetScript("OnMouseWheel",function(_,delta)
        if c.matches then c.highlight=math.max(1,math.min(#c.matches,(c.highlight or 1)-delta));c:Refresh() end
    end)
    self.note=self:Text(f,"",11,14,-200,c.profile.width-28,44);self.note:SetWordWrap(true);self.note:SetTextColor(.68,.71,.76)
    self.go=self:Button(f,"Find routes",14,-246,c.profile.width-88,30,function() if #c.results>0 then c:Go() elseif not c.destination and c.filter.category~="all" then c:Plan() else c:Enter() end end)
    self.stop=self:Button(f,"Stop",c.profile.width-66,-246,52,30,function() c:Stop() end)
    self.guidance=CreateFrame("Frame",nil,f);self.guidance:SetPoint("TOPLEFT",14,-48);self.guidance:SetSize(c.profile.width-28,94)
    self.arrow=self.guidance:CreateTexture(nil,"ARTWORK");self.arrow:SetTexture(MEDIA.."arrow.tga");self.arrow:SetPoint("TOPLEFT",0,-4);self.arrow:SetSize(32,32);self.arrow:SetVertexColor(unpack(accent))
    self.next=self:Text(self.guidance,"",13,42,0,c.profile.width-70,25)
    self.remaining=self:Text(self.guidance,"",11,42,-25,c.profile.width-70,20)
    self.directionNote=self:Text(self.guidance,"",11,0,-51,c.profile.width-28,38);self.directionNote:SetWordWrap(true)
    self.expand=self:Button(f,"Edit / routes",14,-147,c.profile.width-154,28,function() c.compact=false;c:Refresh() end)
    self.pause=self:Button(f,"Pause",c.profile.width-132,-147,60,28,function()
        if c.nav.state=="nearby" then c.nav.state="arrived";c.nav.message="Arrival confirmed";c.character.intent=nil
        else c.manualPause=not c.manualPause;c.nav.measure=nil end;c:Refresh()
    end)
    self.fold=self:Button(self.editor,"Fold",c.profile.width-64,-117,50,26,function() c.compact=true;c:Refresh() end)
    local handle=CreateFrame("Button",nil,UIParent);self.handle=handle;handle:SetSize(24,64);handle:SetFrameStrata("MEDIUM");self:Surface(handle)
    handle.text=self:Text(handle,">",16,0,0,24,64);handle.text:SetJustifyH("CENTER");handle:SetScript("OnClick",function() c.tucked=false;self:Layout(c) end)
    self.from:SetText("Current location");self:Layout(c)
end
function U:Layout(c)
    local f,p=self.frame,c.profile;local scale=math.min(p.scale,UIParent:GetHeight()/560);f:SetScale(scale);f:SetWidth(p.width);f:ClearAllPoints()
    local sw,sh=UIParent:GetWidth()/scale,UIParent:GetHeight()/scale
    local x=p.dock=="right" and sw-p.width-8 or p.dock=="left" and 8 or p.x
    local y=math.max(-(sh-math.min(f:GetHeight(),sh)),math.min(0,p.y))
    f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",math.max(0,math.min(sw-p.width,x)),y)
    self.handle:SetScale(scale);self.handle:ClearAllPoints()
    self.handle:SetPoint(p.dock=="right" and "RIGHT" or "LEFT",UIParent,p.dock=="right" and "RIGHT" or "LEFT",0,0)
    self.handle.text:SetText(p.dock=="right" and "<" or ">");self.handle:SetShown(c.tucked==true);f:SetShown(not c.tucked)
end
function U:Refresh(c)
    local compact=c.compact and c.nav.route~=nil
    self.editor:SetShown(not compact);self.body:SetShown(not compact);self.guidance:SetShown(compact);self.expand:SetShown(compact);self.go:SetShown(not compact);self.note:SetShown(not compact)
    self.pause:SetShown(compact);self.pause.text:SetText(c.nav.state=="nearby" and "Done" or c.manualPause and "Resume" or "Pause")
    self.fold:SetShown(c.nav.route~=nil);self.specialization:SetShown(not c.nav.route and (c.filter.category=="class" or c.filter.category=="profession"))
    self.specialization:SetDefaultText(c.filter.class or c.filter.profession or (c.filter.category=="class" and c.ctx.class) or "All professions")
    if not self.from:HasFocus() then self.from:SetText(c.origin and c.origin.name or "Current location") end
    if not self.to:HasFocus() then self.to:SetText(c.destination and c.destination.name or c.query or "") end
    if compact then self.frame:SetHeight(188);self.stop:ClearAllPoints();self.stop:SetPoint("TOPLEFT",c.profile.width-66,-147)
    else
        local count=math.min(3,c.matches and #c.matches or #c.results);local offset=math.max(0,(c.highlight or 1)-3);c.matchOffset=offset
        for i,b in ipairs(self.rows) do
            local item=c.matches and c.matches[offset+i] or c.results[i];b:SetShown(item~=nil)
            if item then
                if c.matches then
                    b.name:SetText(item.name);b.detail:SetText((item.role or item.category).." • "..(item.zone or "").."\n"..(item.faction or "Faction unknown").." • "..(item.mobile and "last known area" or "eligibility unverified"))
                else
                    local selected=c.selected==i
                    b.name:SetText((selected and "Selected: " or "")..item.destination.name)
                    local via=""
                    for _,leg in ipairs(item.legs) do if leg.mode=="flight" then via="\nVia "..(leg.start.name or "flight master").." > "..(leg.finish.name or "flight point");break end end
                    b.detail:SetText("~"..M.Yards(item.distance).." • "..M.Time(item.eta).."*"..(via~="" and via or "\nWalking bearing only"))
                end
                b.bg:SetVertexColor(unpack((c.matches and offset+i==c.highlight or not c.matches and i==c.selected) and {.22,.27,.18,1} or {.10,.11,.14,1}))
                local tip
                if c.matches then
                    tip=item.name.."\n"..(item.source or "Client flight candidate").."\nSpawn: "..tostring(item.id)
                    if item.phase then tip=tip.."\nPhase requirement: "..tostring(item.phase).." (not checked)" end
                    if (item.questStarts or 0)>0 then tip=tip.."\nQuest giver; current eligibility unknown" end
                    if (item.questEnds or 0)>0 then tip=tip.."\nQuest turn-in NPC; current eligibility unknown" end
                else
                    tip=item.destination.name.."\nWalk "..M.Yards(item.walk).." + fly "..M.Yards(item.flight)
                    for _,leg in ipairs(item.legs) do if leg.mode=="flight" then tip=tip.."\n"..(leg.start.name or tostring(leg.from)).." > "..(leg.finish.name or tostring(leg.to)) end end
                    tip=tip.."\nCompass bearings only: no verified ground path. ETA excludes stops/detours; flight prior uncalibrated. "..(item.conditional and "Flight availability must be checked at the master." or "")
                end
                self:Tip(b,tip)
            end
        end
        local y=200+count*83;self.body:SetHeight(math.max(1,count*83));self.note:ClearAllPoints();self.note:SetPoint("TOPLEFT",14,-y)
        self.note:SetText(c.status or (#c.results>0 and ((c.profile.routeOrder=="time" and "Estimated time" or "Distance").." • ground paths unverified\n*Soft ETA"..(c.categoryCapped and ("; "..c.categoryCompared.." sampled candidates") or "; flight prior uncalibrated")) or c.providerStatus or "Search for a destination. /atcf remember saves a place."))
        self.go:ClearAllPoints();self.go:SetPoint("TOPLEFT",14,-y-49);self.stop:ClearAllPoints();self.stop:SetPoint("TOPLEFT",c.profile.width-66,-y-49)
        self.go.text:SetText(#c.results>0 and (c.origin and "Use current location" or "Go") or "Find routes");self.frame:SetHeight(y+91)
    end
    self:Layout(c)
end
function U:Guidance(c,p,ctx,now)
    if not c.nav.route then return end
    local target=N.Navigation.Target(c.nav);local distance,seconds=N.Navigation.Remaining(c.nav,p,ctx.speed,now)
    local leg=c.nav.route.legs[c.nav.leg]
    self.next:SetText(c.nav.state=="arrived" and "Arrived" or leg and leg.mode=="flight" and ("Fly to "..(leg.finish.name or "flight point")) or target and target.name or c.nav.route.destination.name)
    self.remaining:SetText((c.nav.state=="paused" or c.nav.state=="unavailable" or c.manualPause) and "Estimate paused" or c.nav.state=="arrived" and "Journey complete" or "~"..M.Yards(distance).." • "..M.Time(seconds).."*")
    self.directionNote:SetText(c.manualPause and "Navigation paused" or c.nav.message or "Compass bearing • ground path unverified")
    self.pause.text:SetText(c.nav.state=="nearby" and "Done" or c.manualPause and "Resume" or "Pause")
    local east,north=M.Vector(p,target,ctx.facing)
    self.arrow:SetShown(not c.manualPause and east~=nil and c.nav.state~="flying" and c.nav.state~="paused" and c.nav.state~="unavailable" and c.nav.state~="arrived")
    if east then self.arrow:SetRotation(-math.atan2(east,north));if not ctx.facing and not c.manualPause and not c.nav.message and c.nav.state~="arrived" then self.directionNote:SetText("North-relative bearing • ground path unverified") end end
end
function U:Toggle(c)
    if c.tucked then c.tucked=false elseif c.nav.route then c.compact=not c.compact else c.tucked=true end
    self:Refresh(c)
end
_G.BINDING_HEADER_ASTHECROWFLIES="As The Crow Flies"
_G.BINDING_NAME_ASTHECROWFLIES_TOGGLE="Expand / collapse navigation"
