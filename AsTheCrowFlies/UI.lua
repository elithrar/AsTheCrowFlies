local _,N=...;local M=N.Model;local U={texts={}};N.UI=U
local MEDIA="Interface\\AddOns\\AsTheCrowFlies\\Media\\"
local accent={.78,.85,.61};local ink={.93,.94,.97}
-- One checked family for all owned text, including native option controls.
-- Native font heights are uiUnits: cache their readback, not an exact size echo.
U.fontRevision=0
local function samePath(a,b)
    return type(a)=="string" and type(b)=="string" and a:gsub("/","\\"):lower()==b:gsub("/","\\"):lower()
end
local function setFont(object,path,size,flags)
    local ok,result=pcall(object.SetFont,object,path,size,flags or "")
    if not ok or result==false then return false end
    local actual,height=object:GetFont()
    return samePath(actual,path) and type(height)=="number" and height>0
end
function U:ResetFonts() self.fontResolution=nil end
function U:ResolveFont()
    local fallback=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local pref=self.owner and self.owner.profile.font or "Expressway"
    local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
    local requested=pref=="Arial" and "Fonts\\ARIALN.TTF" or fallback
    if pref~="Arial" and pref~="Game font" and lsm and lsm:IsValid("font",pref) then requested=lsm:Fetch("font",pref) end
    if type(requested)~="string" or requested=="" then requested=fallback end
    local key=pref..":"..requested..":"..fallback
    local state=self.fontResolution
    if not state or state.key~=key or state.library~=lsm then
        if not self.fontProbe then self.fontProbe=UIParent:CreateFontString(nil,"OVERLAY");self.fontProbe:Hide() end
        state={key=key,library=lsm,path=setFont(self.fontProbe,requested,12) and requested or fallback,default=fallback}
        if state.path==requested and lsm and lsm:IsValid("font",pref.." Bold") then
            local bold=lsm:Fetch("font",pref.." Bold")
            if type(bold)=="string" and bold~=requested and setFont(self.fontProbe,bold,12) then state.bold=bold end
        end
        self.fontResolution=state;self.fontRevision=self.fontRevision+1
    end
    return state
end
function U:Font(object,baseSize)
    self.fontObjects=self.fontObjects or {}
    local entry=self.fontObjects[object]
    if not entry then entry={object,baseSize};self.texts[#self.texts+1]=entry;self.fontObjects[object]=entry else entry[2]=baseSize end
    local size=(object.atcfFixedFont and baseSize or math.max(9,baseSize+((self.owner and self.owner.profile.fontSize) or 13)-13))*(object.atcfFontScale or 1)
    local state=self:ResolveFont();local path=object.atcfEmphasis and state.bold or state.path
    local fontFlags=object.atcfEmphasis and not state.bold and "OUTLINE" or ""
    local actual,height,flags=object:GetFont()
    local changed=actual~=object.atcfFontPath or height~=object.atcfFontHeight or flags~=object.atcfFontFlags
    local key=path..":"..size..":"..fontFlags
    if state.native then
        if object.atcfNativeFont~=state.native or changed then object:SetFontObject(state.native) end
        object.atcfNativeFont=state.native;object.atcfFontKey=nil
    elseif object.atcfFontKey~=key or changed then
        object.atcfNativeFont=nil
        local applied=setFont(object,path,size,fontFlags)
        if not applied and state.bold and path==state.bold then
            state.bold=nil;self.fontRevision=self.fontRevision+1;path=state.path;fontFlags="OUTLINE"
            applied=setFont(object,path,size,fontFlags)
        end
        if not applied then
            -- A late per-control rejection downgrades the entire family. The
            -- refresh pass replays earlier objects before doing final layout.
            if state.path~=state.default or state.bold then state.path=state.default;state.bold=nil;self.fontRevision=self.fontRevision+1 end
            path=state.path;fontFlags=object.atcfEmphasis and "OUTLINE" or ""
            if not setFont(object,path,size,fontFlags) then
                state.native=GameFontNormal or GameTooltipText;self.fontRevision=self.fontRevision+1
                object:SetFontObject(state.native);object.atcfNativeFont=state.native
                local nativePath=object:GetFont();state.path=nativePath or state.default
            end
        end
        object.atcfFontKey=not state.native and (path..":"..size..":"..fontFlags) or nil
    end
    object.atcfFontPath,object.atcfFontHeight,object.atcfFontFlags=object:GetFont()
    if object.atcfSoftShadow then
        object:SetShadowColor(0,0,0,.35);object:SetShadowOffset(0,0)
    end
    return object
end
function U:RefreshFonts()
    for _=1,3 do
        local revision=self.fontRevision
        for _,v in ipairs(self.texts) do self:Font(v[1],v[2]) end
        if revision==self.fontRevision then break end
    end
end
function U:SyncMenus()
    local path,size,flags=self.menuFont:GetFont();local key=tostring(path)..":"..tostring(size)..":"..tostring(flags)
    for _,d in ipairs(self.dropdowns or {}) do
        -- Native generated selection text overrides SetDefaultText. Refresh
        -- after values change, never before a profile switch's new values.
        if d.atcfMenuFont~=key or d.atcfSelectionValue~=d.value then
            d:GenerateMenu();d.atcfMenuFont=key;d.atcfSelectionValue=d.value
        end
    end
end
function U:WatchFonts()
    local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
    if not lsm or self.fontLibrary==lsm or not lsm.RegisterCallback then return end
    self.fontLibrary=lsm
    self.fontChanged=self.fontChanged or function(_,kind) if kind=="font" and self.owner then self.owner:RefreshAppearance(true) end end
    lsm.RegisterCallback(self,"LibSharedMedia_Registered",self.fontChanged);lsm.RegisterCallback(self,"LibSharedMedia_SetGlobal",self.fontChanged)
    self.fontChanged(nil,"font")
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
    for _,entry in ipairs(self.texts) do if not entry[1].atcfOptions then entry[1]:SetTextColor(unpack(colors.text)) end end
    for _,row in ipairs(self.rows or {}) do row.name:SetTextColor(1,.82,0);row.lockedText:SetTextColor(.95,.25,.25) end
    if self.destinationName then self.destinationName:SetTextColor(1,.82,0) end
    if self.next then self.next:SetTextColor(1,.82,0) end
    if self.eagle then self.eagle:SetVertexColor(.88,.66,.16) end
    if self.arrow then self.arrow:SetVertexColor(unpack(colors.accent)) end
end
function U:Rectangle(f,color)
    local texture=f:CreateTexture(nil,"BACKGROUND");texture:SetAllPoints(f);texture:SetColorTexture(1,1,1,1)
    texture:SetVertexColor(unpack(color or {.045,.048,.062,.97}))
    if not color then self.backgrounds=self.backgrounds or {};self.backgrounds[#self.backgrounds+1]=texture end
    return texture
end
function U:Button(parent,label,x,y,w,h,callback)
    local b=CreateFrame("Button",nil,parent);b:SetPoint("TOPLEFT",x,y);b:SetSize(w,h or 28)
    local inset=w<40 and 2 or 8
    b.bg=self:Rectangle(b,{.13,.14,.17,1});b.text=self:Text(b,label,12,inset,0,w-inset*2,h or 28);b.text:SetJustifyH("CENTER")
    b.normalColor={.13,.14,.17,1};b.hoverColor={.22,.24,.28,1}
    b:SetScript("OnClick",callback);b:SetScript("OnEnter",function() b.bg:SetVertexColor(unpack(b.hoverColor)) end);b:SetScript("OnLeave",function() b.bg:SetVertexColor(unpack(b.normalColor)) end)
    return b
end
function U:Tip(frame,text)
    frame:SetScript("OnEnter",function() if frame.bg then frame.bg:SetVertexColor(unpack(frame.hoverColor)) end;GameTooltip:SetOwner(frame,"ANCHOR_RIGHT");GameTooltip:SetText(text,nil,nil,nil,nil,true);GameTooltip:Show() end)
    frame:SetScript("OnLeave",function() if frame.bg then frame.bg:SetVertexColor(unpack(frame.normalColor)) end;GameTooltip:Hide() end)
end
function U:ButtonColor(b,normal,hover) b.normalColor=normal;b.hoverColor=hover;b.bg:SetVertexColor(unpack(normal)) end
-- Use the client's control artwork, independent of the selected font. Atlas
-- dimensions describe the glyph; the 20px holder remains the alignment box.
local nativeIcons={
    cog={{file="Interface\\WorldMap\\GEAR_64GREY",width=64,height=64,size=20},{atlas="OptionsIcon-Brown",size=18}},
    back={{atlas="common-icon-rotateleft",size=18},{atlas="common-icon-backarrow",size=18},{file="Interface\\ChatFrame\\ChatFrameExpandArrow",width=16,height=16,size=20,flip=true}},
    location={{file="Interface\\Minimap\\UI-Minimap-Ping-Center",width=16,height=16,size=18}},
    left={{atlas="common-icon-backarrow",size=18},{file="Interface\\ChatFrame\\ChatFrameExpandArrow",width=16,height=16,size=20,flip=true}},
    right={{atlas="common-icon-forwardarrow",size=18},{file="Interface\\ChatFrame\\ChatFrameExpandArrow",width=16,height=16,size=20}},
}
function U:NativeIcon(icon,kind)
    local texture=icon.texture
    if not texture then
        texture=icon:CreateTexture(nil,"ARTWORK");icon.texture=texture;texture:SetPoint("CENTER")
        if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
        if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
    end
    texture:Hide();texture:SetTexture(nil);texture:SetRotation(0);texture:SetVertexColor(1,1,1,1);texture:SetDesaturated(true);icon.asset=nil
    for _,asset in ipairs(nativeIcons[kind] or {}) do
        local applied,width,height=false,asset.width,asset.height
        if asset.atlas and C_Texture and C_Texture.GetAtlasInfo and texture.SetAtlas then
            local ok,info=pcall(C_Texture.GetAtlasInfo,asset.atlas)
            if ok and info and M.Number(info.width) and info.width>0 and M.Number(info.height) and info.height>0 then
                -- SetAtlas returns no success value. pcall status is separate.
                applied=pcall(texture.SetAtlas,texture,asset.atlas,false,nil,true,"CLAMP","CLAMP")
                if applied and texture.GetAtlas then applied=texture:GetAtlas()==asset.atlas end
                width,height=info.width,info.height
            end
        elseif asset.file then
            local ok,result=pcall(texture.SetTexture,texture,asset.file,"CLAMP","CLAMP")
            applied=ok and result==true
            if applied then texture:SetTexCoord(asset.flip and 1 or 0,asset.flip and 0 or 1,0,1) end
        end
        if applied then
            local factor=asset.size/math.max(width,height)
            texture:SetSize(width*factor,height*factor);texture:Show();icon.asset=asset.atlas or asset.file;return true
        end
    end
    texture:SetTexture(nil);return false
end
function U:Icon(b,kind)
    b.text:Hide();b.icons=b.icons or {}
    if nativeIcons[kind] and not b.nativePushed then
        local pushed=b:CreateTexture(nil,"BACKGROUND",nil,1);pushed:SetColorTexture(0,0,0,.3);pushed:SetAllPoints(b)
        b:SetPushedTexture(pushed);b.nativePushed=pushed
    end
    if not b.icons[kind] then
        local icon=CreateFrame("Frame",nil,b);icon:SetSize(20,20);icon:SetPoint("CENTER");b.icons[kind]=icon
        local function line(x1,y1,x2,y2,width)
            local l=icon:CreateLine(nil,"ARTWORK");l:SetThickness(width or 2);l:SetColorTexture(.95,.96,.98,1)
            l:SetStartPoint("CENTER",icon,x1,y1);l:SetEndPoint("CENTER",icon,x2,y2)
        end
        if nativeIcons[kind] then
            icon.nativeAvailable=self:NativeIcon(icon,kind)
        elseif kind=="pause" then line(-3,5,-3,-5,3);line(3,5,3,-5,3)
        elseif kind=="play" then line(-4,6,5,0);line(5,0,-4,-6);line(-4,-6,-4,6)
        elseif kind=="done" then line(-6,0,-2,-4);line(-2,-4,6,5)
        else line(-4,4,4,-4);line(-4,-4,4,4) end
    end
    for name,icon in pairs(b.icons) do icon:SetShown(name==kind) end
    if nativeIcons[kind] and not b.icons[kind].nativeAvailable then
        -- An unexpected missing client asset must not leave an invisible action.
        b.text:SetText(({cog="S",back="<",location="+",left="<",right=">"})[kind]);b.text:Show()
    end
    b.iconKind=kind
end
function U:PauseIcon(c)
    self:Icon(self.pause,c.nav.state=="nearby" and "done" or c.manualPause and "play" or "pause")
    self:Tip(self.pause,c.nav.state=="nearby" and "Confirm arrival" or c.manualPause and "Resume navigation" or "Pause navigation")
end
function U:SetDock(c,side,tuck)
    c.profile.dock=(side=="left" or side=="right") and side or "none";c.tucked=tuck and c.profile.dock~="none" or false;c.hidden=false
    self:Layout(c)
end
function U:WrappedHeight(text,minimum)
    text:SetHeight(0)
    local scale=text:GetEffectiveScale();local height=math.max(minimum or 0,(math.ceil(text:GetStringHeight()*scale)+2)/scale)
    text:SetHeight(height);return height
end
function U:ListingDistance(distance,seconds)
    if not M.Number(distance) then return "Distance unavailable" end
    local yards=distance>=1000 and string.format("%.1fk",distance/1000) or string.format("%.0f",distance)
    local time=""
    if M.Number(seconds) then
        local minutes=math.max(1,math.floor(seconds/60+.5))
        time=" (est. "..(seconds<60 and "<1 minute" or minutes..(minutes==1 and " minute" or " minutes"))..")"
    end
    return "Distance: ~"..yards.." yards"..time
end
function U:RouteTotal(route)
    local distance=route.distance
    local yards=M.Number(distance) and (distance>=1000 and string.format("%.1fk",distance/1000) or string.format("%.0f",distance))
    return (M.Number(route.eta) and "Est. "..M.Minutes(route.eta) or "Time unavailable")..(yards and " • ~"..yards.." yards" or " • Distance unavailable")
end
function U:DestinationDetail(destination)
    local categories={class="Class trainer",profession="Profession trainer",trainer="Trainer",auction="Auction house",quest="Quest NPC",flight="Flight point",place="Saved place"}
    return (destination.role or categories[destination.category] or "Destination")..(destination.zone and destination.zone~="" and (" • "..destination.zone) or "")
end
function U:SharedDestination(results)
    local first=results[1] and results[1].destination
    if not first then return end
    for _,route in ipairs(results) do
        local other=route.destination
        if other~=first and (not first.id or first.id~=other.id or first.map~=other.map or first.x~=other.x or first.y~=other.y) then return end
    end
    return first
end
function U:SavePlacement(c)
    local left,top=self.frame:GetLeft(),self.frame:GetTop()
    if left and top then c.profile.x=left;c.profile.y=top-UIParent:GetHeight()/self.frame:GetScale() end
end
function U:FinishResize(c)
    if not self.resizing then return end
    self.frame:StopMovingOrSizing();self:SavePlacement(c);self.resizing=false
end
function U:ScrollIndicator(offset)
    local range=self.bodyScrollRange or 0;local visible=self.bodyScroll:GetHeight()
    self.scrollRail:SetShown(range>0 and self.bodyScroll:IsShown());self.scrollThumb:SetShown(range>0 and self.bodyScroll:IsShown())
    if range<=0 then return end
    local height=math.max(12,visible*visible/(visible+range));self.scrollRail:SetHeight(visible);self.scrollThumb:SetHeight(height)
    self.scrollThumb:ClearAllPoints();self.scrollThumb:SetPoint("TOPLEFT",self.scrollRail,"TOPLEFT",0,-math.min(range,math.max(0,offset or 0))/range*(visible-height))
end
function U:Menu(parent,x,y,w,label,entries,choose)
    local d=CreateFrame("DropdownButton",nil,parent,"WowStyle1DropdownTemplate");d:SetPoint("TOPLEFT",x,y);d:SetSize(w,28);d:SetDefaultText(label)
    if not self.menuFont then self.menuFont=CreateFont("AsTheCrowFliesMenuFont");self.menuFont.atcfFixedFont=true;self.menuFont.atcfOptions=true;self:Font(self.menuFont,12);self.menuFont:SetTextColor(unpack(ink)) end
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
    d:SetPoint("TOPLEFT",c.profile.width-38,-42);d:SetSize(24,28);self:Rectangle(d,{.13,.14,.17,1})
    self.filterLines={}
    local points={{5,7},{19,7},{14,14},{14,21},{10,23},{10,14},{5,7}}
    for i=1,#points-1 do
        local line=d:CreateLine(nil,"ARTWORK");line:SetThickness(1.5)
        line:SetStartPoint("TOPLEFT",d,points[i][1],-points[i][2]);line:SetEndPoint("TOPLEFT",d,points[i+1][1],-points[i+1][2]);self.filterLines[#self.filterLines+1]=line
    end
    if not self.menuFont then self.menuFont=CreateFont("AsTheCrowFliesMenuFont");self.menuFont.atcfFixedFont=true;self.menuFont.atcfOptions=true;self:Font(self.menuFont,12);self.menuFont:SetTextColor(unpack(ink)) end
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
    local caption=self:Text(parent,label,12,14,y,44,32);caption:SetTextColor(.65,.68,.73)
    self.fieldLabels=self.fieldLabels or {};self.fieldLabels[#self.fieldLabels+1]=caption
    local e=CreateFrame("EditBox",nil,parent);e:SetPoint("TOPLEFT",62,y);e:SetSize(self.owner.profile.width-104,32);e:SetAutoFocus(false);e:SetMaxLetters(100)
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
    f:SetMovable(true);f:SetResizable(true);f:EnableMouse(true);f:SetClampedToScreen(true);f:SetFrameStrata("MEDIUM");self:Surface(f)
    local header=CreateFrame("Frame",nil,f);self.header=header;header:SetPoint("TOPLEFT");header:SetSize(c.profile.width-78,44);header:EnableMouse(true);header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function() if not c.profile.locked and not self.resizing then self.dragging=true;f:StartMoving() end end)
    header:SetScript("OnDragStop",function()
        if not self.dragging then return end;self.dragging=false
        f:StopMovingOrSizing()
        local left,top=f:GetLeft(),f:GetTop();local scale=f:GetScale();local screen=UIParent:GetWidth()/scale
        self:SavePlacement(c);c.profile.dock=left<24 and "left" or (left+c.profile.width>screen-24 and "right" or "none")
        c.tucked=c.profile.dock~="none"
        self:Layout(c)
    end)
    local eagle=header:CreateTexture(nil,"ARTWORK");self.eagle=eagle;eagle:SetTexture(MEDIA.."eagle.tga");eagle:SetPoint("LEFT",header,"LEFT",14,0);eagle:SetSize(24,24);eagle:SetVertexColor(.88,.66,.16)
    self.title=self:Text(header,"AS THE CROW FLIES",11,46,0,184,24);self.title:ClearAllPoints();self.title:SetPoint("LEFT",header,"LEFT",46,0)
    self.title.atcfFixedFont=true;self:Font(self.title,11)
    self.settings=self:Button(f,"...",c.profile.width-68,-9,26,26,function() self.menu:SetShown(not self.menu:IsShown()) end)
    self:Icon(self.settings,"cog")
    self.settings:SetFrameLevel(header:GetFrameLevel()+3);self:Tip(self.settings,"Navigation menu")
    self.tuck=self:Button(f,"",c.profile.width-38,-9,24,26,function() c:Back() end);self:Icon(self.tuck,"back")
    self.tuck:SetFrameLevel(header:GetFrameLevel()+3);self:Tip(self.tuck,"Back to the previous view")
    self.editor=CreateFrame("Frame",nil,f);self.editor:SetPoint("TOPLEFT",0,-45);self.editor:SetPoint("TOPRIGHT",0,-45);self.editor:SetHeight(76)
    self.from=self:Edit(self.editor,"From",0,true);self.to=self:Edit(self.editor,"To",-40,false)
    self.current=self:Button(self.editor,"",c.profile.width-38,-2,24,28,function() c:Edit(true);c.origin=nil;self.from:SetText("Current location");c:Refresh() end);self:Icon(self.current,"location")
    self:Tip(self.current,"Reset origin to your current location")
    self:FilterMenu(self.editor,c)
    self.bodyScroll=CreateFrame("ScrollFrame",nil,f);self.bodyScroll:SetPoint("TOPLEFT",14,-125);self.bodyScroll:SetWidth(c.profile.width-28)
    self.body=CreateFrame("Frame",nil,self.bodyScroll);self.body:SetPoint("TOPLEFT");self.body:SetWidth(c.profile.width-28);self.bodyScroll:SetScrollChild(self.body)
    self.scrollRail=f:CreateTexture(nil,"ARTWORK");self.scrollRail:SetPoint("TOPLEFT",self.bodyScroll,"TOPRIGHT",4,0);self.scrollRail:SetWidth(2);self.scrollRail:SetColorTexture(.2,.21,.24,1);self.scrollRail:Hide()
    self.scrollThumb=f:CreateTexture(nil,"OVERLAY");self.scrollThumb:SetWidth(2);self.scrollThumb:SetColorTexture(.7,.7,.72,1);self.scrollThumb:Hide()
    self.bodyScroll:SetScript("OnVerticalScroll",function(_,offset) self:ScrollIndicator(offset) end)
    self.routeHeading=CreateFrame("Frame",nil,f)
    self.destinationName=self:Text(self.routeHeading,"",13,0,0,c.profile.width-28,20)
    self.destinationName.atcfEmphasis=true;self.destinationName.atcfSoftShadow=true;self:Font(self.destinationName,13)
    self.destinationDetail=self:Text(self.routeHeading,"",12,0,-20,c.profile.width-28,20)
    self.destinationDetail.atcfEmphasis=true;self.destinationDetail.atcfSoftShadow=true;self:Font(self.destinationDetail,12)
    for _,text in ipairs({self.destinationName,self.destinationDetail}) do text:SetWordWrap(true);text:SetNonSpaceWrap(true);text:SetJustifyV("TOP") end
    self.sortLabel=self:Text(self.routeHeading,"Sort",11,0,0,36,24)
    self.routeOrder=self:Menu(self.routeHeading,38,0,c.profile.width-66,"Distance",function() return {{label="Distance",value="distance"},{label="Estimated time",value="time"}} end,function(value) c:SetRouteOrder(value) end)
    self.routeOrder:SetHeight(24)
    if self.routeOrder.Text then self.routeOrder.Text.atcfFixedFont=true;self:Font(self.routeOrder.Text,12);self.routeOrder.Text:SetHeight(24) end
    self.resultsBoundary=f:CreateTexture(nil,"ARTWORK");self.resultsBoundary:SetColorTexture(.26,.28,.32,1);self.resultsBoundary:SetHeight(1);self.resultsBoundary:Hide()
    self.rows={}
    for i=1,40 do
        local b=self:Button(self.body,"",0,-(i-1)*83,c.profile.width-28,77,function()
            if c.matches then self.from:ClearFocus();self.to:ClearFocus();c:Choose(c.matches[i],c.searchOrigin)
            else c.selected=i;c:Refresh() end
        end)
        b.text:Hide();b.name=self:Text(b,"",13,10,-6,c.profile.width-50,21);b.name:SetWordWrap(true);b.name:SetNonSpaceWrap(true);b.name:SetJustifyV("TOP")
        b.detail=self:Text(b,"",11,10,-27,c.profile.width-50,41);b.detail:SetWordWrap(true);b.detail:SetNonSpaceWrap(true);b.detail:SetJustifyV("TOP")
        b.distance=self:Text(b,"",11,10,-44,c.profile.width-50,16);b.distance:SetWordWrap(true);b.distance:SetJustifyV("TOP")
        b.itinerary=self:Text(b,"",11,10,-62,c.profile.width-50,16);b.itinerary:SetWordWrap(true);b.itinerary:SetNonSpaceWrap(true);b.itinerary:SetJustifyV("TOP");b.itinerary:Hide()
        for _,text in ipairs({b.name,b.detail,b.distance,b.itinerary}) do text.atcfSoftShadow=true;text:SetShadowOffset(0,0);text:SetShadowColor(0,0,0,.35) end
        b.name.atcfEmphasis=true;self:Font(b.name,13);b.name:SetTextColor(1,.82,0)
        b.detail.atcfEmphasis=true;self:Font(b.detail,12)
        b.go=self:Button(b,"Go",c.profile.width-80,-23,44,30,function()
            if not c.matches and c.results[i] and not c.results[i].unavailable then c.selected=i;c:Go() end
        end);b.go:Hide()
        self:ButtonColor(b.go,{.29,.34,.21,1},{.40,.46,.28,1})
        b.locked=CreateFrame("Frame",nil,b);b.locked:SetAllPoints(b);b.locked:SetFrameLevel(b:GetFrameLevel()+4)
        local shade=b.locked:CreateTexture(nil,"BACKGROUND");shade:SetAllPoints();shade:SetColorTexture(0,0,0,.68)
        b.lockedText=self:Text(b.locked,"Undiscovered flight points",11,6,0,c.profile.width-40,22);b.lockedText:ClearAllPoints();b.lockedText:SetPoint("CENTER");b.lockedText:SetTextColor(.95,.25,.25)
        b.locked:Hide()
        self.rows[i]=b
    end
    local function scroll(_,delta)
        local old=self.bodyScroll:GetVerticalScroll();local range=self.bodyScrollRange or 0
        local next=math.max(0,math.min(range,old-delta*40))
        if next~=old then self.bodyScroll:SetVerticalScroll(next);self:ScrollIndicator(next) end
    end
    self.body:EnableMouseWheel(true);self.body:SetScript("OnMouseWheel",scroll);self.bodyScroll:EnableMouseWheel(true);self.bodyScroll:SetScript("OnMouseWheel",scroll)
    self.note=self:Text(f,"",11,14,-200,c.profile.width-28,44);self.note:SetWordWrap(true);self.note:SetJustifyH("CENTER");self.note:SetTextColor(.68,.71,.76)
    self.go=self:Button(f,"Find routes",14,-246,c.profile.width-88,30,function() self.from:ClearFocus();self.to:ClearFocus();c:PrimaryAction() end)
    self.stop=self:Button(f,"",c.profile.width-42,-246,28,28,function() c:Stop() end);self:Icon(self.stop,"close");self:ButtonColor(self.stop,{.52,.12,.14,1},{.70,.18,.20,1});self:Tip(self.stop,"Stop navigation")
    self.guidance=CreateFrame("Frame",nil,f);self.guidance:SetPoint("TOPLEFT",14,-48);self.guidance:SetSize(c.profile.width-28,94)
    self.arrow=self.guidance:CreateTexture(nil,"ARTWORK");self.arrow:SetTexture(MEDIA.."arrow.tga");self.arrow:SetPoint("TOPLEFT",0,-4);self.arrow:SetSize(32,32);self.arrow:SetVertexColor(unpack(accent))
    self.next=self:Text(self.guidance,"",13,44,0,c.profile.width-72,25);self.next.atcfEmphasis=true;self.next.atcfFontScale=1.1;self:Font(self.next,13);self.next:SetTextColor(1,.82,0)
    self.next:SetWordWrap(true);self.next:SetNonSpaceWrap(true);self.next:SetJustifyV("TOP")
    self.cardinal=self:Text(self.guidance,"",11,0,-39,32,16);self.cardinal:SetJustifyH("CENTER")
    self.remaining=self:Text(self.guidance,"",11,44,-25,c.profile.width-72,20);self.remaining.atcfFontScale=1.1;self:Font(self.remaining,11)
    self.remaining:SetWordWrap(true);self.remaining:SetJustifyV("TOP")
    self.directionNote=self:Text(self.guidance,"",11,0,-61,c.profile.width-28,38);self.directionNote.atcfFontScale=1.1;self:Font(self.directionNote,11);self.directionNote:SetWordWrap(true)
    self.expand=self:Button(f,"Edit / routes",14,-147,c.profile.width-154,28,function() c.compact=false;c:Refresh() end)
    self.expand.text.atcfFontScale=1.1;self:Font(self.expand.text,12)
    self.pause=self:Button(f,"",c.profile.width-76,-147,28,28,function()
        if c.nav.state=="nearby" then c.nav.state="arrived";c.nav.message="Arrival confirmed";c.character.intent=nil
        else c.manualPause=not c.manualPause;c.nav.measure=nil;c.nav.dwell=nil;c.nav.previous=nil;c.nav.previousTime=nil end;c:Refresh()
    end)
    self:PauseIcon(c)
    self.fold=self:Button(f,"Fold",14,-125,50,30,function() c.compact=true;c:Refresh() end)
    local handle=CreateFrame("Button",nil,UIParent);self.handle=handle;handle:SetSize(24,64);handle:SetFrameStrata("MEDIUM")
    handle.bg=self:Rectangle(handle,{.13,.14,.17,1});handle.normalColor={.13,.14,.17,1};handle.hoverColor={.22,.24,.28,1}
    handle.text=self:Text(handle,">",16,0,0,24,64);handle.text:SetJustifyH("CENTER");handle:SetScript("OnClick",function() c.tucked=false;self:Layout(c) end)
    self:Tip(handle,"Expand navigation")
    local grip=CreateFrame("Button",nil,f);self.resizeGrip=grip;grip:SetSize(18,18);grip:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1);grip:SetFrameLevel(f:GetFrameLevel()+10)
    for _,length in ipairs({4,8,12}) do
        local line=grip:CreateLine(nil,"ARTWORK");line:SetThickness(1.5);line:SetColorTexture(.75,.76,.8,1)
        line:SetStartPoint("BOTTOMRIGHT",grip,-length,3);line:SetEndPoint("BOTTOMRIGHT",grip,-3,length)
    end
    self:Tip(grip,"Drag to resize results")
    grip:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton" or c.profile.locked or self.dragging or not grip:IsShown() then return end
        self.resizeChrome=f:GetHeight()-self.bodyScroll:GetHeight();self.resizing=true
        self:SavePlacement(c);c.profile.dock="none";f:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp",function(_,button) if button=="LeftButton" and self.resizing then self:FinishResize(c);c:Refresh() end end)
    grip:SetScript("OnHide",function() self:FinishResize(c) end)
    f:SetScript("OnSizeChanged",function(_,width,height)
        if not self.resizing or self.resizeLayout then return end
        c.profile.width=math.max(280,math.min(640,width));c.profile.resultsHeight=math.max(100,math.min(560,height-self.resizeChrome))
        self.resizeLayout=true;self:Refresh(c);self.resizeLayout=false
    end)
    f:SetScript("OnHide",function()
        self:FinishResize(c)
        if self.dragging then f:StopMovingOrSizing();self:SavePlacement(c);self.dragging=false end
    end)
    self.from:SetText("Current location");self:Layout(c)
    local menu=CreateFrame("Frame","AsTheCrowFliesMenu",f);self.menu=menu;menu:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-40);menu:SetSize(196,172);menu:SetFrameStrata("DIALOG");menu:SetFrameLevel(f:GetFrameLevel()+20);menu:EnableMouse(true);self:Surface(menu)
    local function action(label,y,fn)
        local b=self:Button(menu,label,8,y,180,26,function() menu:Hide();fn() end);b.text.atcfFixedFont=true;self:Font(b.text,12);return b
    end
    self.menuOptions=action("Settings",-8,function() N.Options:Open() end)
    self.menuSave=action("Save current location",-40,function() SlashCmdList.ASTHECROWFLIES("remember") end)
    self.menuLock=action("Lock / unlock panel",-72,function() c.profile.locked=not c.profile.locked;c:Refresh() end)
    self.menuTuck=action("Tuck to screen edge",-104,function() self:SetDock(c,c.profile.dock=="none" and "right" or c.profile.dock,true) end)
    self.menuClose=action("Close menu",-136,function() end);menu:Hide()
    UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"AsTheCrowFliesMenu")
end
function U:Layout(c)
    -- Native dragging owns the frame anchor until release. Refreshes during
    -- guidance, indexing or font registration must not snap it back.
    if self.dragging then return end
    local f,p=self.frame,c.profile;local scale=self.resizing and f:GetScale() or math.min(p.scale,UIParent:GetHeight()/660,UIParent:GetWidth()/(p.width+16))
    if not self.resizing then f:SetScale(scale);f:SetWidth(p.width);f:ClearAllPoints() end
    local function move(control,x,y) control:ClearAllPoints();control:SetPoint("TOPLEFT",x,y) end
    self.header:SetWidth(p.width-78);self.title:SetWidth(p.width-124)
    move(self.settings,p.width-68,-9);move(self.tuck,p.width-38,-9);move(self.current,p.width-38,-2)
    self.from:SetWidth(p.width-104);self.to:SetWidth(p.width-104);self.body:SetWidth(p.width-28);self.bodyScroll:SetWidth(p.width-28)
    move(self.filterButton,p.width-38,-42);self.note:SetWidth(p.width-28)
    local goWidth=p.width-(c.nav.route and 124 or 88);self.go:SetWidth(goWidth);self.go.text:SetWidth(goWidth-16)
    self.guidance:SetWidth(p.width-28);self.next:SetWidth(p.width-72);self.remaining:SetWidth(p.width-72);self.directionNote:SetWidth(p.width-28)
    self.expand:SetWidth(p.width-96);self.expand.text:SetWidth(p.width-112)
    for _,row in ipairs(self.rows) do row:SetWidth(p.width-28);row.lockedText:SetWidth(p.width-40) end
    local sw,sh=UIParent:GetWidth()/scale,UIParent:GetHeight()/scale
    local x=p.dock=="right" and sw-p.width-8 or p.dock=="left" and 8 or p.x
    local y=math.max(-(sh-math.min(f:GetHeight(),sh)),math.min(0,p.y))
    if not self.resizing then
        f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",math.max(0,math.min(sw-p.width,x)),y)
    end
    if self.resizeGrip:IsShown() then
        local chrome=math.max(0,f:GetHeight()-self.bodyScroll:GetHeight())
        f:SetResizeBounds(280,chrome+100,math.min(640,sw-16),math.max(chrome+100,math.min(chrome+560,sh-16)))
    end
    self.handle:SetScale(scale);self.handle:ClearAllPoints()
    self.handle:SetPoint(p.dock=="right" and "RIGHT" or "LEFT",UIParent,p.dock=="right" and "RIGHT" or "LEFT",0,0)
    self:Icon(self.handle,p.dock=="right" and "left" or "right");self.handle:SetShown(not c.hidden and c.tucked==true);f:SetShown(not c.hidden and not c.tucked)
end
function U:LayoutGuidance(c)
    self.next:SetWidth(c.profile.width-72);self.remaining:SetWidth(c.profile.width-72);self.directionNote:SetWidth(c.profile.width-28)
    local nameHeight=self:WrappedHeight(self.next,21)
    self.remaining:ClearAllPoints();self.remaining:SetPoint("TOPLEFT",44,-nameHeight-5)
    local body=math.max(self.cardinal:IsShown() and 57 or 40,nameHeight+5+self:WrappedHeight(self.remaining,18))
    local message=self.directionNote:GetText() or "";self.directionNote:SetShown(message~="")
    self.directionNote:ClearAllPoints();self.directionNote:SetPoint("TOPLEFT",0,-body-6)
    if message~="" then body=body+6+self:WrappedHeight(self.directionNote,16) end
    self.guidance:SetHeight(body)
    local footer=48+body+10
    for _,entry in ipairs({{self.expand,14},{self.pause,c.profile.width-76},{self.stop,c.profile.width-42}}) do
        entry[1]:ClearAllPoints();entry[1]:SetPoint("TOPLEFT",entry[2],-footer)
    end
    local height=footer+40;local changed=self.frame:GetHeight()~=height;self.frame:SetHeight(height);return changed
end
function U:Refresh(c)
    if not self.dragging and not self.resizing then self.frame:SetScale(math.min(c.profile.scale,UIParent:GetHeight()/660,UIParent:GetWidth()/(c.profile.width+16))) end
    if self.menuLock then self.menuLock.text:SetText(c.profile.locked and "Unlock panel" or "Lock panel") end
    local compact=c.compact and c.nav.route~=nil
    local expanded=c.searching or c.matches~=nil or c.destination~=nil or #c.results>0 or c.nav.route~=nil or c.planned
    self.resizeGrip:SetShown(not c.profile.locked and not compact and expanded and ((c.matches and #c.matches>0) or #c.results>0))
    self.editor:SetShown(not compact);self.body:SetShown(not compact and expanded);self.bodyScroll:SetShown(not compact and expanded);self.guidance:SetShown(compact);self.expand:SetShown(compact);self.go:SetShown(not compact and expanded and (c.matches~=nil or #c.results==0));self.note:SetShown(not compact and expanded)
    self:ScrollIndicator(self.bodyScroll:GetVerticalScroll())
    self.stop:SetShown(c.nav.route~=nil);self.fold:SetShown(not compact and c.nav.route~=nil)
    local tint=M.HasFilter(c.filter) and c.profile.colors.accent or {.65,.68,.73}
    for _,line in ipairs(self.filterLines) do line:SetColorTexture(tint[1],tint[2],tint[3],1) end
    self.pause:SetShown(compact);self:PauseIcon(c)
    self.routeHeading:Hide();self.resultsBoundary:Hide()
    if not self.from:HasFocus() then self.from:SetText(c.origin and c.origin.name or "Current location") end
    if not self.to:HasFocus() then self.to:SetText(c.destination and c.destination.name or c.query or "") end
    if compact then self:Guidance(c,N.Adapter.Position(),c:Context(),GetTime());self:LayoutGuidance(c)
    else
        local bodyHeight=0;local origin=c:SearchPosition(c.searchOrigin);local bodyTop=125
        local comparing=not c.matches and #c.results>0
        local shared=comparing and self:SharedDestination(c.results)
        if comparing then
            local heading=self.routeHeading;heading:Show();heading:ClearAllPoints();heading:SetPoint("TOPLEFT",14,-125);heading:SetWidth(c.profile.width-28)
            self.destinationName:SetShown(shared~=nil);self.destinationDetail:SetShown(shared~=nil)
            local y=0
            if shared then
                self.destinationName:SetWidth(c.profile.width-28);self.destinationName:SetText(shared.name);self.destinationName:SetTextColor(1,.82,0)
                y=self:WrappedHeight(self.destinationName)+1
                self.destinationDetail:SetWidth(c.profile.width-28);self.destinationDetail:SetText(self:DestinationDetail(shared));self.destinationDetail:ClearAllPoints();self.destinationDetail:SetPoint("TOPLEFT",0,-y)
                y=y+self:WrappedHeight(self.destinationDetail)+6
            end
            self.sortLabel:ClearAllPoints();self.sortLabel:SetPoint("TOPLEFT",0,-y)
            self.routeOrder:ClearAllPoints();self.routeOrder:SetPoint("TOPLEFT",38,-y);self.routeOrder:SetWidth(c.profile.width-66)
            if self.routeOrder.Text then self.routeOrder.Text:SetWidth(c.profile.width-102) end
            self.routeOrder.value=c.profile.routeOrder;self.routeOrder:SetDefaultText(c.profile.routeOrder=="time" and "Estimated time" or "Distance");self:SyncMenus()
            heading:SetHeight(y+30);bodyTop=bodyTop+y+30
        end
        self.bodyTop=bodyTop;self.bodyScroll:ClearAllPoints();self.bodyScroll:SetPoint("TOPLEFT",14,-bodyTop)
        local textColor=c.profile.colors.text;local secondary={textColor[1]*.82,textColor[2]*.82,textColor[3]*.82}
        for i,b in ipairs(self.rows) do
            local item=c.matches and c.matches[i] or c.results[i];b:SetShown(item~=nil)
            b.go:SetShown(item~=nil and not c.matches)
            b.go:SetEnabled(item~=nil and not c.matches and not item.unavailable)
            b.locked:SetShown(item~=nil and not c.matches and item.unavailable=="undiscovered")
            b.lockedText:SetTextColor(.95,.25,.25)
            local width=c.profile.width-(c.matches and 50 or 100)
            b.name:SetWidth(width);b.detail:SetWidth(width);b.distance:SetWidth(width);b.itinerary:SetWidth(c.profile.width-48)
            b.detail:SetShown(item~=nil);b.distance:SetShown(item~=nil and not shared)
            local hasLegs=item and not c.matches and M.RouteMode(item)=="Walk + fly"
            b.itinerary:SetShown(hasLegs)
            if item then
                local destination=c.matches and item or item.destination
                b.name:SetText(shared and M.RouteMode(item) or destination.name)
                if shared then b.name:SetTextColor(unpack(textColor)) else b.name:SetTextColor(1,.82,0) end
                b.detail.atcfEmphasis=not shared;self:Font(b.detail,shared and 11 or 12)
                b.detail:SetText(shared and self:RouteTotal(item) or self:DestinationDetail(destination));b.detail:SetTextColor(unpack(textColor))
                b.distance:SetTextColor(unpack(secondary));b.itinerary:SetTextColor(unpack(secondary))
                if c.matches then
                    local distance=M.Distance(origin,item)
                    b.distance:SetText(origin and item.map and origin.map~=item.map and "Other continent" or self:ListingDistance(distance,M.GroundSeconds(distance,c.ctx.speed,"bearing")))
                else
                    b.distance:SetText(M.RouteMode(item).." • "..self:RouteTotal(item));b.itinerary:SetText(M.RouteLegs(item,c.ctx.speed))
                end
                b.name:ClearAllPoints();b.name:SetPoint("TOPLEFT",10,-4)
                local y=4+self:WrappedHeight(b.name)+1
                b.detail:ClearAllPoints();b.detail:SetPoint("TOPLEFT",10,-y);y=y+self:WrappedHeight(b.detail)
                if not shared then b.distance:ClearAllPoints();b.distance:SetPoint("TOPLEFT",10,-y-3);y=y+3+self:WrappedHeight(b.distance) end
                if not c.matches then y=math.max(y,36) end
                if hasLegs then b.itinerary:ClearAllPoints();b.itinerary:SetPoint("TOPLEFT",10,-y-4);y=y+4+self:WrappedHeight(b.itinerary) end
                local rowHeight=y+4
                b:SetHeight(rowHeight);b:ClearAllPoints();b:SetPoint("TOPLEFT",0,-bodyHeight);b.bodyOffset=bodyHeight
                b.go:ClearAllPoints();b.go:SetPoint("TOPRIGHT",b,"TOPRIGHT",-8,-6);bodyHeight=bodyHeight+rowHeight+5
                b.normalColor=(c.matches and i==c.highlight or not c.matches and i==c.selected) and {.22,.27,.18,1} or {.10,.11,.14,1};b.bg:SetVertexColor(unpack(b.normalColor))
                local tip
                if c.matches then
                    tip=item.name.."\n"..(item.source or "Flight point").."\nDistance from "..(not c.searchOrigin and c.origin and c.origin.name or "current location")..". Ground ETA includes 35% for detours; bearings only."
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
        bodyHeight=math.max(0,bodyHeight-5)
        self.body:SetHeight(math.max(1,bodyHeight))
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
        local messageHeight=message and (self:WrappedHeight(self.note,32)+10) or 0
        local hasFooter=self.go:IsShown() or self.stop:IsShown() or self.fold:IsShown()
        local scale=self.resizing and self.frame:GetScale() or math.min(c.profile.scale,UIParent:GetHeight()/660,UIParent:GetWidth()/(c.profile.width+16))
        local limit=(UIParent:GetHeight()-16)/scale-bodyTop-messageHeight-(hasFooter and 50 or 20)
        local requested=c.profile.resultsHeight
        if self.resizing then
            -- Width changes can wrap fixed headings/status text while native
            -- sizing owns the outer frame. Rebudget the viewport immediately.
            self.resizeChrome=bodyTop+messageHeight+(bodyHeight>0 and 8 or 0)+(hasFooter and 42 or 12)
            requested=math.max(1,math.min(560,self.frame:GetHeight()-self.resizeChrome))
            c.profile.resultsHeight=math.max(100,requested)
        end
        local visible=math.max(0,math.min(self.resizing and requested or bodyHeight,requested,math.max(1,limit)))
        self.bodyScroll:SetHeight(math.max(1,visible));self.bodyScrollRange=math.max(0,bodyHeight-visible)
        local key=c.matches or c.results;local selected=c.matches and (c.highlight or 1) or (c.selected or 1)
        local scroll=self.scrollResults~=key and 0 or self.bodyScroll:GetVerticalScroll()
        local row=self.rows[selected]
        local reflow=row and (self.scrollRowOffset~=row.bodyOffset or self.scrollRowHeight~=row:GetHeight() or self.scrollViewport~=visible or self.scrollWidth~=c.profile.width)
        if self.scrollResults~=key or self.scrollHighlight~=(c.matches and c.highlight or c.selected) or reflow then
            if row and row:IsShown() then
                if row:GetHeight()>=visible or row.bodyOffset<scroll then scroll=row.bodyOffset
                elseif row.bodyOffset+row:GetHeight()>scroll+visible then scroll=row.bodyOffset+row:GetHeight()-visible end
            end
        end
        self.scrollRowOffset=row and row.bodyOffset;self.scrollRowHeight=row and row:GetHeight();self.scrollViewport=visible;self.scrollWidth=c.profile.width
        self.scrollResults=key;self.scrollHighlight=c.matches and c.highlight or c.selected
        self.bodyScroll:SetVerticalScroll(math.max(0,math.min(scroll,self.bodyScrollRange)));self:ScrollIndicator(self.bodyScroll:GetVerticalScroll())
        local y=bodyTop+visible
        if bodyHeight>0 then
            self.resultsBoundary:SetShown(self.bodyScrollRange>0);self.resultsBoundary:ClearAllPoints();self.resultsBoundary:SetPoint("TOPLEFT",14,-y-4);self.resultsBoundary:SetWidth(c.profile.width-28)
            y=y+8
        end
        self.note:ClearAllPoints();self.note:SetPoint("TOPLEFT",14,-y)
        local footer=y+messageHeight
        self.go:ClearAllPoints();self.go:SetPoint("TOPLEFT",c.nav.route and 74 or 44,-footer);self.stop:ClearAllPoints();self.stop:SetPoint("TOPLEFT",c.profile.width-42,-footer)
        self.fold:ClearAllPoints();self.fold:SetPoint("TOPLEFT",14,-footer)
        self.go.text:SetText(c:PrimaryActionLabel());self.go:SetEnabled(not c.searching and not (c.matches and #c.matches==0))
        if not self.resizing then self.frame:SetHeight(expanded and (footer+(hasFooter and 42 or 12)) or 129) end
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
    self:PauseIcon(c)
    local east,north=M.Vector(p,target,ctx.facing)
    self.arrow:SetShown(not c.manualPause and east~=nil and c.nav.state~="flying" and c.nav.state~="paused" and c.nav.state~="unavailable" and c.nav.state~="arrived")
    local cardinal=M.Cardinal(p,target);self.cardinal:SetText(cardinal or "");self.cardinal:SetShown(self.arrow:IsShown() and cardinal~=nil)
    if east then self.arrow:SetRotation(-math.atan2(east,north));if not ctx.facing and not c.manualPause and not c.nav.message and c.nav.state~="arrived" then self.directionNote:SetText("Bearing from north") end end
    if c.compact and self:LayoutGuidance(c) then self:Layout(c) end
end
function U:Toggle(c)
    if c.hidden then c.hidden=false;c.tucked=false elseif c.tucked then c.tucked=false elseif c.nav.route then c.compact=not c.compact else c.tucked=true end
    self:Refresh(c)
end
_G.BINDING_HEADER_ASTHECROWFLIES="As The Crow Flies"
_G.BINDING_NAME_ASTHECROWFLIES_TOGGLE="Expand / collapse navigation"
