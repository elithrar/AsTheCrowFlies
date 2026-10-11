local _,N=...;local M=N.Model;local U={texts={}};N.UI=U
local MEDIA="Interface\\AddOns\\AsTheCrowFlies\\Media\\"
local accent={.78,.85,.61};local ink={.93,.94,.97}
function U:Font(object,size)
    local path=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local pref=self.owner and self.owner.profile.font or "Expressway"
    local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
    if pref=="Arial" then path="Fonts\\ARIALN.TTF"
    elseif lsm and lsm:IsValid("font",pref) then path=lsm:Fetch("font",pref) end
    if not self.fontProbe then self.fontProbe=UIParent:CreateFontString(nil,"OVERLAY");self.fontProbe:Hide() end
    local valid,loaded=pcall(self.fontProbe.SetFont,self.fontProbe,path,12,"")
    local actual=self.fontProbe:GetFont()
    if not valid or loaded==false or type(actual)~="string" or actual:gsub("/","\\"):lower()~=path:gsub("/","\\"):lower() then path=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF" end
    local ok,result=pcall(object.SetFont,object,path,size,"")
    if not ok or result==false then object:SetFontObject(GameFontNormal) end
    self.fontObjects=self.fontObjects or {};if not self.fontObjects[object] then self.texts[#self.texts+1]={object,size};self.fontObjects[object]=true end;return object
end
function U:RefreshFonts()
    for _,v in ipairs(self.texts) do self:Font(v[1],v[2]) end
    for _,d in ipairs(self.dropdowns or {}) do d:GenerateMenu() end
end
function U:WatchFonts()
    local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
    if not lsm or self.fontLibrary==lsm or not lsm.RegisterCallback then return end
    self.fontLibrary=lsm
    local changed=function(_,kind) if kind=="font" then self:RefreshFonts();self:Refresh(self.owner) end end
    lsm.RegisterCallback(self,"LibSharedMedia_Registered",changed);lsm.RegisterCallback(self,"LibSharedMedia_SetGlobal",changed)
    self:RefreshFonts()
end
function U:ClassLabel(token)
    if not token then return "Class trainer" end
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or (LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[token]) or token:sub(1,1)..token:sub(2):lower()
end
function U:Text(parent,text,size,x,y,width,height)
    local t=parent:CreateFontString(nil,"OVERLAY");self:Font(t,size or 12)
    t:SetPoint("TOPLEFT",x or 0,y or 0);t:SetSize(width or 100,height or 20)
    t:SetJustifyH("LEFT");t:SetJustifyV("MIDDLE");t:SetTextColor(unpack(ink));t:SetShadowColor(0,0,0,.65);t:SetShadowOffset(1,-1);t:SetWordWrap(false);t:SetText(text or "")
    self.inkTexts=self.inkTexts or {};self.inkTexts[#self.inkTexts+1]=t;return t
end
function U:Surface(f,color)
    local pieces={};local radius=6;local crop=18/256
    local function texture() local t=f:CreateTexture(nil,"BACKGROUND");pieces[#pieces+1]=t;return t end
    for _,corner in ipairs({{"TOPLEFT",0,crop,0,crop},{"TOPRIGHT",1-crop,1,0,crop},{"BOTTOMLEFT",0,crop,1-crop,1},{"BOTTOMRIGHT",1-crop,1,1-crop,1}}) do
        local t=texture();t:SetTexture(MEDIA.."surface.tga");t:SetTexCoord(corner[2],corner[3],corner[4],corner[5]);t:SetPoint(corner[1],f,corner[1],0,0);t:SetSize(radius,radius)
    end
    local center=texture();center:SetColorTexture(1,1,1,1);center:SetPoint("TOPLEFT",f,"TOPLEFT",radius,0);center:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-radius,0)
    local left=texture();left:SetColorTexture(1,1,1,1);left:SetPoint("TOPLEFT",f,"TOPLEFT",0,-radius);left:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,radius);left:SetWidth(radius)
    local right=texture();right:SetColorTexture(1,1,1,1);right:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,-radius);right:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,radius);right:SetWidth(radius)
    local surface={pieces=pieces};function surface:SetVertexColor(...) for _,t in ipairs(self.pieces) do t:SetVertexColor(...) end end
    surface:SetVertexColor(unpack(color or {.045,.048,.062,.97}))
    if not color then self.backgrounds=self.backgrounds or {};self.backgrounds[#self.backgrounds+1]=surface end
    return surface
end
function U:ApplyAppearance()
    local colors=self.owner.profile.colors
    if not colors then return end
    for _,surface in ipairs(self.backgrounds or {}) do surface:SetVertexColor(colors.background[1],colors.background[2],colors.background[3],.97) end
    for _,entry in ipairs(self.texts) do entry[1]:SetTextColor(unpack(colors.text)) end
    for _,row in ipairs(self.rows or {}) do row.lockedText:SetTextColor(.95,.25,.25) end
    for _,t in ipairs({self.eagle,self.arrow}) do if t then t:SetVertexColor(unpack(colors.accent)) end end
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
    if not self.menuFont then self.menuFont=CreateFont("AsTheCrowFliesMenuFont");self:Font(self.menuFont,12) end
    if d.Text then self:Font(d.Text,12);d.Text:ClearAllPoints();d.Text:SetPoint("LEFT",d,"LEFT",9,0);d.Text:SetSize(w-36,28);d.Text:SetJustifyH("LEFT");d.Text:SetJustifyV("MIDDLE");d.Text:SetWordWrap(false) end
    d:SetupMenu(function(_,root)
        root:SetScrollMode(280)
        for _,entry in ipairs(entries()) do
            local row=root:CreateRadio(entry.label,function() return d.value==entry.value end,function() d.value=entry.value;d:SetDefaultText(entry.label);choose(entry.value) end)
            row:AddInitializer(function(button) button.fontString:SetFontObject(self.menuFont) end)
        end
    end)
    self.dropdowns=self.dropdowns or {};self.dropdowns[#self.dropdowns+1]=d;return d
end
function U:FilterMenu(parent,c)
    -- The intrinsic DropdownButton owns mouse dismissal, Escape and menu input.
    local d=CreateFrame("DropdownButton",nil,parent);self.filterButton=d
    d:SetPoint("TOPLEFT",c.profile.width-36,-42);d:SetSize(24,28);self:Surface(d,{.13,.14,.17,1})
    self.filterLines={}
    local points={{5,7},{19,7},{14,14},{14,21},{10,23},{10,14},{5,7}}
    for i=1,#points-1 do
        local line=d:CreateLine(nil,"ARTWORK");line:SetThickness(1.5)
        line:SetStartPoint("TOPLEFT",d,points[i][1],-points[i][2]);line:SetEndPoint("TOPLEFT",d,points[i+1][1],-points[i+1][2]);self.filterLines[#self.filterLines+1]=line
    end
    if not self.menuFont then self.menuFont=CreateFont("AsTheCrowFliesMenuFont");self:Font(self.menuFont,12) end
    d:SetupMenu(function(_,root)
        root:SetScrollMode(280)
        local function checkbox(container,label,selected,group,key)
            local row=container:CreateCheckbox(label,selected,function() c:Filter(group,key) end)
            row:AddInitializer(function(button) button.fontString:SetFontObject(self.menuFont) end)
            return row
        end
        checkbox(root,"All",function() return not M.HasFilter(c.filter) end,"all")
        for _,entry in ipairs({{"Auction houses","auction"},{"Class trainers","class"},{"Profession trainers","profession"},{"Other trainers","trainer"},{"Quest NPCs","quest"},{"Flight points","flight"},{"Saved places","place"}}) do
            local key=entry[2]
            local row=checkbox(root,entry[1],function() return c.filter.categories[key]==true end,"categories",key)
            if key=="class" or key=="profession" then
                local group=key=="class" and "classes" or "professions";row:SetScrollMode(280)
                checkbox(row,key=="class" and "All classes" or "All professions",function() return c.filter.categories[key] and not next(c.filter[group]) end,group,"all")
                for _,value in ipairs(N.Providers[group]) do
                    local selected=value
                    checkbox(row,key=="class" and self:ClassLabel(selected) or selected,function() return c.filter.categories[key] and c.filter[group][selected]==true end,group,selected)
                end
            end
        end
    end)
    d:HookScript("OnMouseDown",function() self.from:ClearFocus();self.to:ClearFocus() end)
    self:Tip(d,"Filter destinations")
    self.dropdowns=self.dropdowns or {};self.dropdowns[#self.dropdowns+1]=d
    return d
end
function U:Edit(parent,label,y,origin)
    self:Text(parent,label,11,14,y,48,32):SetTextColor(.65,.68,.73)
    local e=CreateFrame("EditBox",nil,parent);e:SetPoint("TOPLEFT",62,y);e:SetSize(self.owner.profile.width-102,32);e:SetAutoFocus(false);e:SetMaxLetters(100)
    self:Surface(e,{.09,.10,.125,1});self:Font(e,13);e:SetTextInsets(8,8,0,0)
    e:SetScript("OnTextChanged",function(_,user)
        if user then
            self.owner:Edit(true)
            if origin then self.owner.origin=nil;self.owner.originQuery=e:GetText()
            else self.owner.destination=nil;self.owner.query=e:GetText() end
            if e:GetText():find("%S") or (not origin and M.HasFilter(self.owner.filter)) then self.owner:Search(e:GetText(),origin) else self.owner:Refresh() end
        end
    end)
    e:SetScript("OnEnterPressed",function()
        if self.owner:Enter()=="selected" then local point=origin and self.owner.origin or self.owner.destination;e:SetText(point and point.name or "");e:SetFocus()
        else e:ClearFocus() end
    end)
    e:SetScript("OnEscapePressed",function() self.owner.searchGeneration=self.owner.searchGeneration+1;self.owner.matches=nil;self.owner.searching=nil;self.owner.planned=nil;e:ClearFocus();self.owner:Refresh() end)
    e:SetScript("OnArrowPressed",function(_,key)
        local c=self.owner;if c.matches and #c.matches>0 then c.highlight=math.max(1,math.min(#c.matches,(c.highlight or 1)+(key=="UP" and -1 or 1)));c:Refresh() end
    end)
    e:SetScript("OnEditFocusLost",function() e:HighlightText(0,0) end)
    return e
end
function U:Create(c)
    self.owner=c;local f=CreateFrame("Frame","AsTheCrowFliesPanel",UIParent);self.frame=f
    f:SetMovable(true);f:EnableMouse(true);f:SetClampedToScreen(true);f:SetFrameStrata("MEDIUM");self:Surface(f)
    local header=CreateFrame("Frame",nil,f);self.header=header;header:SetPoint("TOPLEFT");header:SetSize(c.profile.width-72,42);header:EnableMouse(true);header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function() if not c.profile.locked then f:StartMoving() end end)
    header:SetScript("OnDragStop",function()
        f:StopMovingOrSizing()
        local left,top=f:GetLeft(),f:GetTop();local scale=f:GetScale();local screen=UIParent:GetWidth()/scale
        c.profile.x=left;c.profile.y=top-UIParent:GetHeight()/scale;c.profile.dock=left<24 and "left" or (left+c.profile.width>screen-24 and "right" or "none")
        self:Layout(c)
    end)
    local eagle=header:CreateTexture(nil,"ARTWORK");self.eagle=eagle;eagle:SetTexture(MEDIA.."eagle.tga");eagle:SetPoint("TOPLEFT",14,-11);eagle:SetSize(24,24);eagle:SetVertexColor(unpack(accent))
    self.title=self:Text(header,"AS THE CROW FLIES",11,46,-11,184,24)
    self.settings=self:Button(f,"...",c.profile.width-62,-9,26,26,function() self.menu:SetShown(not self.menu:IsShown()) end)
    self.settings:SetFrameLevel(header:GetFrameLevel()+3);self:Tip(self.settings,"Navigation menu")
    self.tuck=self:Button(f,"<",c.profile.width-32,-9,24,26,function() c:Back() end)
    self.tuck:SetFrameLevel(header:GetFrameLevel()+3);self:Tip(self.tuck,"Back to the previous view")
    self.editor=CreateFrame("Frame",nil,f);self.editor:SetPoint("TOPLEFT",0,-45);self.editor:SetPoint("TOPRIGHT",0,-45);self.editor:SetHeight(76)
    self.from=self:Edit(self.editor,"From",0,true);self.to=self:Edit(self.editor,"To",-40,false)
    self.current=self:Button(self.editor,"@",c.profile.width-34,-2,22,28,function() c:Edit(true);c.origin=nil;self.from:SetText("Current location");c:Refresh() end)
    self:Tip(self.current,"Reset origin to your current location")
    self:FilterMenu(self.editor,c)
    self.body=CreateFrame("Frame",nil,f);self.body:SetPoint("TOPLEFT",14,-125);self.body:SetWidth(c.profile.width-28)
    self.rows={}
    for i=1,3 do
        local b=self:Button(self.body,"",0,-(i-1)*83,c.profile.width-28,77,function()
            if c.matches then local index=(c.matchOffset or 0)+i;c:Choose(c.matches[index],c.searchOrigin)
            else c.selected=i;c:Refresh() end
        end)
        b.text:Hide();b.name=self:Text(b,"",13,10,-6,c.profile.width-50,21)
        b.detail=self:Text(b,"",11,10,-27,c.profile.width-50,41);b.detail:SetWordWrap(true)
        b.go=self:Button(b,"Go",c.profile.width-80,-23,44,30,function()
            if not c.matches and c.results[i] and not c.results[i].unavailable then c.selected=i;c:Go() end
        end);b.go:Hide()
        b.locked=CreateFrame("Frame",nil,b);b.locked:SetAllPoints(b);b.locked:SetFrameLevel(b:GetFrameLevel()+4)
        local shade=b.locked:CreateTexture(nil,"BACKGROUND");shade:SetAllPoints();shade:SetColorTexture(0,0,0,.68)
        b.lockedText=self:Text(b.locked,"Undiscovered flight points",11,6,0,c.profile.width-40,22);b.lockedText:ClearAllPoints();b.lockedText:SetPoint("CENTER");b.lockedText:SetTextColor(.95,.25,.25)
        b.locked:Hide()
        self.rows[i]=b
    end
    self.body:EnableMouseWheel(true);self.body:SetScript("OnMouseWheel",function(_,delta)
        if c.matches then c.highlight=math.max(1,math.min(#c.matches,(c.highlight or 1)-delta));c:Refresh() end
    end)
    self.note=self:Text(f,"",11,14,-200,c.profile.width-28,44);self.note:SetWordWrap(true);self.note:SetTextColor(.68,.71,.76)
    self.go=self:Button(f,"Find routes",14,-246,c.profile.width-88,30,function() if not c.destination and M.HasFilter(c.filter) then c:Plan() else c:Enter() end end)
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
    self.fold=self:Button(f,"Fold",14,-125,50,30,function() c.compact=true;c:Refresh() end)
    local handle=CreateFrame("Button",nil,UIParent);self.handle=handle;handle:SetSize(24,64);handle:SetFrameStrata("MEDIUM");self:Surface(handle)
    handle.text=self:Text(handle,">",16,0,0,24,64);handle.text:SetJustifyH("CENTER");handle:SetScript("OnClick",function() c.tucked=false;self:Layout(c) end)
    self.from:SetText("Current location");self:Layout(c)
    local menu=CreateFrame("Frame","AsTheCrowFliesMenu",f);self.menu=menu;menu:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-40);menu:SetSize(196,172);menu:SetFrameStrata("DIALOG");menu:SetFrameLevel(f:GetFrameLevel()+20);menu:EnableMouse(true);self:Surface(menu)
    local function action(label,y,fn) return self:Button(menu,label,8,y,180,26,function() menu:Hide();fn() end) end
    self.menuOptions=action("Settings",-8,function() N.Options:Open() end)
    self.menuSave=action("Save current location",-40,function() SlashCmdList.ASTHECROWFLIES("remember") end)
    self.menuLock=action("Lock / unlock panel",-72,function() c.profile.locked=not c.profile.locked;c:Refresh() end)
    self.menuTuck=action("Tuck to screen edge",-104,function() c.tucked=true;self:Layout(c) end)
    self.menuClose=action("Close menu",-136,function() end);menu:Hide()
    UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"AsTheCrowFliesMenu")
end
function U:Layout(c)
    -- Reserve the same bounded expanded footprint in every state.
    local f,p=self.frame,c.profile;local scale=math.min(p.scale,UIParent:GetHeight()/660,UIParent:GetWidth()/(p.width+16));f:SetScale(scale);f:SetWidth(p.width);f:ClearAllPoints()
    local function move(control,x,y) control:ClearAllPoints();control:SetPoint("TOPLEFT",x,y) end
    self.header:SetWidth(p.width-72);self.title:SetWidth(p.width-118)
    move(self.settings,p.width-62,-9);move(self.tuck,p.width-32,-9);move(self.current,p.width-34,-2)
    self.from:SetWidth(p.width-102);self.to:SetWidth(p.width-102);self.body:SetWidth(p.width-28)
    move(self.filterButton,p.width-36,-42);self.note:SetWidth(p.width-28)
    local goWidth=p.width-(c.nav.route and 148 or 88);self.go:SetWidth(goWidth);self.go.text:SetWidth(goWidth-16)
    self.guidance:SetWidth(p.width-28);self.next:SetWidth(p.width-70);self.remaining:SetWidth(p.width-70);self.directionNote:SetWidth(p.width-28)
    self.expand:SetWidth(p.width-154);self.expand.text:SetWidth(p.width-170);move(self.pause,p.width-132,-147)
    for _,row in ipairs(self.rows) do row:SetWidth(p.width-28);row.lockedText:SetWidth(p.width-40) end
    local sw,sh=UIParent:GetWidth()/scale,UIParent:GetHeight()/scale
    local x=p.dock=="right" and sw-p.width-8 or p.dock=="left" and 8 or p.x
    local y=math.max(-(sh-math.min(f:GetHeight(),sh)),math.min(0,p.y))
    f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",math.max(0,math.min(sw-p.width,x)),y)
    self.handle:SetScale(scale);self.handle:ClearAllPoints()
    self.handle:SetPoint(p.dock=="right" and "RIGHT" or "LEFT",UIParent,p.dock=="right" and "RIGHT" or "LEFT",0,0)
    self.handle.text:SetText(p.dock=="right" and "<" or ">");self.handle:SetShown(not c.hidden and c.tucked==true);f:SetShown(not c.hidden and not c.tucked)
end
function U:Refresh(c)
    if self.menuLock then self.menuLock.text:SetText(c.profile.locked and "Unlock panel" or "Lock panel") end
    local compact=c.compact and c.nav.route~=nil
    local expanded=c.searching or c.matches~=nil or c.destination~=nil or #c.results>0 or c.nav.route~=nil or c.planned
    self.editor:SetShown(not compact);self.body:SetShown(not compact and expanded);self.guidance:SetShown(compact);self.expand:SetShown(compact);self.go:SetShown(not compact and expanded and (c.matches~=nil or #c.results==0));self.note:SetShown(not compact and expanded)
    self.stop:SetShown(c.nav.route~=nil);self.fold:SetShown(not compact and c.nav.route~=nil)
    local tint=M.HasFilter(c.filter) and c.profile.colors.accent or {.65,.68,.73}
    for _,line in ipairs(self.filterLines) do line:SetColorTexture(tint[1],tint[2],tint[3],1) end
    self.pause:SetShown(compact);self.pause.text:SetText(c.nav.state=="nearby" and "Done" or c.manualPause and "Resume" or "Pause")
    if not self.from:HasFocus() then self.from:SetText(c.origin and c.origin.name or "Current location") end
    if not self.to:HasFocus() then self.to:SetText(c.destination and c.destination.name or c.query or "") end
    if compact then self.frame:SetHeight(188);self.stop:ClearAllPoints();self.stop:SetPoint("TOPLEFT",c.profile.width-66,-147)
    else
        local count=math.min(3,c.matches and #c.matches or #c.results);local offset=math.max(0,(c.highlight or 1)-3);c.matchOffset=offset;local bodyHeight=0
        for i,b in ipairs(self.rows) do
            local item=c.matches and c.matches[offset+i] or c.results[i];b:SetShown(item~=nil)
            b.go:SetShown(item~=nil and not c.matches)
            b.go:SetEnabled(item~=nil and not c.matches and not item.unavailable)
            b.locked:SetShown(item~=nil and not c.matches and item.unavailable=="undiscovered")
            b.lockedText:SetTextColor(.95,.25,.25)
            b.name:SetWidth(c.profile.width-(c.matches and 50 or 100));b.detail:SetWidth(c.profile.width-(c.matches and 50 or 100))
            if item then
                if c.matches then
                    local position=N.Adapter.Position();local distance=M.Distance(position,item)
                    local where=distance and ("~"..M.Yards(distance)) or (position and item.map and position.map~=item.map and "Other continent" or "Distance unavailable")
                    local restriction=item.mobile and " • Moving NPC" or item.phase and item.phase~=0 and " • Phase-dependent" or ""
                    b.name:SetText(item.name);b.detail:SetText((item.role or item.category).." • "..(item.zone or "").."\n"..where..restriction)
                else
                    b.name:SetText(item.destination.name)
                    b.detail:SetText(M.RouteLegs(item,c.ctx.speed))
                end
                local detailHeight=math.min(66,math.max(20,b.detail:GetStringHeight()));local rowHeight=math.max(62,detailHeight+38)
                b.detail:SetHeight(detailHeight);b:SetHeight(rowHeight);b:ClearAllPoints();b:SetPoint("TOPLEFT",0,-bodyHeight)
                b.go:ClearAllPoints();b.go:SetPoint("RIGHT",b,"RIGHT",-8,0);bodyHeight=bodyHeight+rowHeight+6
                b.bg:SetVertexColor(unpack((c.matches and offset+i==c.highlight or not c.matches and i==c.selected) and {.22,.27,.18,1} or {.10,.11,.14,1}))
                local tip
                if c.matches then
                    tip=item.name.."\n"..(item.source or "Flight point")
                    if item.confidence=="provider" then tip=tip.."\nAvailability may depend on phase or quest progress." end
                    if item.faction then tip=tip.."\nFaction: "..item.faction end
                    if item.mobile then tip=tip.."\nThis NPC moves; the marker is a recorded location." end
                    if item.phase and item.phase~=0 then tip=tip.."\nPhase requirement: "..tostring(item.phase).." (not checked)" end
                    if (item.questStarts or 0)>0 then tip=tip.."\nQuest giver; available quests depend on your progress." end
                    if (item.questEnds or 0)>0 then tip=tip.."\nQuest turn-in NPC; requires the relevant quest." end
                else
                    tip=item.destination.name.."\n"..M.RouteLegs(item,c.ctx.speed).."\nWalk "..M.Yards(item.walk).." + fly "..M.Yards(item.flight)
                    for _,leg in ipairs(item.legs) do if leg.mode=="flight" then tip=tip.."\n"..(leg.start.name or tostring(leg.from)).." > "..(leg.finish.name or tostring(leg.to)) end end
                    tip=tip.."\n~ Ground time includes 35% for detours; bearings only."..(item.unavailable=="undiscovered" and "\nDiscover the required flight points first." or item.conditional and "\nConfirm this flight at the departure master." or "")
                end
                self:Tip(b,tip)
            end
        end
        local y=125+bodyHeight;self.body:SetHeight(math.max(1,bodyHeight));self.note:ClearAllPoints();self.note:SetPoint("TOPLEFT",14,-y)
        local message=expanded and c.status or nil
        if not message and c.matches and #c.matches==0 then
            local categories=c.filter.categories or {};local npcSearch=c.searchOrigin or not M.HasFilter(c.filter)
            for key in pairs(categories) do if key~="flight" and key~="place" then npcSearch=true end end
            if npcSearch and c.provider and type(c.provider.ids)=="table" and c.provider.cursor<=#c.provider.ids then
                message="Indexing NPC destinations..."
            elseif npcSearch and not c.provider then
                message="No matches. NPC search requires Forever QuestieDB."
            else message="No matching destinations. Try another name or category." end
        end
        self.note:SetText(message or "");self.note:SetShown(message~=nil)
        local footer=y+(message and 44 or 0)
        self.go:ClearAllPoints();self.go:SetPoint("TOPLEFT",c.nav.route and 74 or 14,-footer);self.stop:ClearAllPoints();self.stop:SetPoint("TOPLEFT",c.profile.width-66,-footer)
        self.fold:ClearAllPoints();self.fold:SetPoint("TOPLEFT",14,-footer)
        self.go.text:SetText("Find routes");self.frame:SetHeight(expanded and (footer+42) or 129)
    end
    self:Layout(c)
end
function U:Guidance(c,p,ctx,now)
    if not c.nav.route then return end
    local target=N.Navigation.Target(c.nav);local distance,seconds=N.Navigation.Remaining(c.nav,p,ctx.speed,now)
    local leg=c.nav.route.legs[c.nav.leg]
    self.next:SetText(c.nav.state=="arrived" and "Arrived" or leg and leg.mode=="flight" and ("Fly to "..(leg.finish.name or "flight point")) or target and target.name or c.nav.route.destination.name)
    self.remaining:SetText((c.nav.state=="paused" or c.nav.state=="unavailable" or c.manualPause) and "Estimate paused" or c.nav.state=="arrived" and "Journey complete" or "~"..M.Yards(distance).." • "..M.Time(seconds).."*")
    self.directionNote:SetText(c.manualPause and "Paused" or c.nav.message or "")
    self.pause.text:SetText(c.nav.state=="nearby" and "Done" or c.manualPause and "Resume" or "Pause")
    local east,north=M.Vector(p,target,ctx.facing)
    self.arrow:SetShown(not c.manualPause and east~=nil and c.nav.state~="flying" and c.nav.state~="paused" and c.nav.state~="unavailable" and c.nav.state~="arrived")
    if east then self.arrow:SetRotation(-math.atan2(east,north));if not ctx.facing and not c.manualPause and not c.nav.message and c.nav.state~="arrived" then self.directionNote:SetText("Bearing from north") end end
end
function U:Toggle(c)
    if c.hidden then c.hidden=false;c.tucked=false elseif c.tucked then c.tucked=false elseif c.nav.route then c.compact=not c.compact else c.tucked=true end
    self:Refresh(c)
end
_G.BINDING_HEADER_ASTHECROWFLIES="As The Crow Flies"
_G.BINDING_NAME_ASTHECROWFLIES_TOGGLE="Expand / collapse navigation"
