local _,N=...;local M=N.Model;local U={texts={}};N.UI=U
local MEDIA="Interface\\AddOns\\AsTheCrowFlies\\Media\\"
local gold={1,.82,0};local ink={.93,.94,.97}
-- A native refusal should be visible without repeating a warning on every layout.
local appearanceFailures=setmetatable({}, {__mode='k'})
local function checkAppearance(object,operation,ok,err)
    local failures=appearanceFailures[object]
    if ok then if failures then failures[operation]=nil end;return end
    if not failures then failures={};appearanceFailures[object]=failures end
    if failures[operation]~=err.code then
        failures[operation]=err.code
        N.App.log:Warn('Appearance unavailable',{operation=operation,code=err.code,reason=err.message})
    end
end
-- Framework chrome follows the selected theme; ATCF retains selection feedback.
local buttonStyle={fill={.06,.06,.065,.8},border={.45,.45,.45,.65},hover={.9,.8,.5,.9}}
local cardStyle={selected={.16,.14,.075,.96},fill={.045,.045,.05,.96},border={.5,.5,.5,.8},hover={.9,.8,.5,.9}}
function U:Dialog(frame,profileBackground)
    checkAppearance(frame,'style',N.App.ui:Style(frame,'dialog'))
    if profileBackground then self.profileDialogs=self.profileDialogs or {};self.profileDialogs[#self.profileDialogs+1]=frame end
end
function U:RefreshButton(button)
    local style=button.atcfStyle
    local theme=self.theme
    if theme then style={fill=theme.colors.surface,border=theme.colors.border,hover=theme.colors.accent,selected={theme.colors.accent[1]*.22,theme.colors.accent[2]*.22,theme.colors.accent[3]*.22,.96}} end
    local enabled=button:IsEnabled()
    local active=enabled and (button.atcfHovered or button.atcfSelected or button.IsMenuOpen and button:IsMenuOpen())
    button:SetBackdropColor(unpack(enabled and button.atcfSelected and style.selected or style.fill))
    button:SetBackdropBorderColor(unpack(active and style.hover or style.border))
    button:SetAlpha(enabled and 1 or .5)
end
function U:StyleButton(button,card)
    button.atcfStyle=card and cardStyle or buttonStyle;checkAppearance(button,'style',N.App.ui:Style(button,'button'))
    self.buttons=self.buttons or {};self.buttons[#self.buttons+1]=button
    button:HookScript("OnEnter",function() button.atcfHovered=true;self:RefreshButton(button) end)
    button:HookScript("OnLeave",function() button.atcfHovered=nil;self:RefreshButton(button) end)
    button:HookScript("OnHide",function() button.atcfHovered=nil;self:RefreshButton(button) end)
    button:HookScript("OnEnable",function() self:RefreshButton(button) end)
    button:HookScript("OnDisable",function() self:RefreshButton(button) end)
    self:RefreshButton(button)
end
function U:ControlArt(frame)
    -- FAU's search inputs and dropdowns align the native border to the control,
    -- replacing the dropdown template's padded background without its scripts.
    if frame.Background then frame.Background:Hide() end
    for _,key in ipairs({"Left","Middle","Right"}) do
        local region=frame[key] or frame:CreateTexture(nil,"BACKGROUND");frame[key]=region
        region:SetAtlas("common-search-border-"..key:lower());region:ClearAllPoints()
        if key~="Middle" then region:SetWidth(8) end
    end
    frame.Left:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0);frame.Left:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,0)
    frame.Right:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0);frame.Right:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
    frame.Middle:SetPoint("TOPLEFT",frame.Left,"TOPRIGHT",0,0);frame.Middle:SetPoint("BOTTOMRIGHT",frame.Right,"BOTTOMLEFT",0,0)
end
-- Typography resolution, fallback and late media notifications belong to SND.
function U:Font(object,baseSize)
    self.fontObjects=self.fontObjects or {}
    local entry=self.fontObjects[object]
    if not entry then entry={object,baseSize};self.texts[#self.texts+1]=entry;self.fontObjects[object]=entry else entry[2]=baseSize end
    local size=(object.atcfFixedFont and baseSize or math.max(9,baseSize+((self.owner and self.owner.profile.fontSize) or 13)-13))*(object.atcfFontScale or 1)
    checkAppearance(object,'font',N.App.fonts:Apply(object,object.atcfEmphasis and 'emphasis' or 'body',{size=size}))
    if object.atcfSoftShadow then object:SetShadowColor(0,0,0,.35);object:SetShadowOffset(0,0) end
    return object
end
function U:RefreshFonts() for _,entry in ipairs(self.texts) do self:Font(entry[1],entry[2]) end end
function U:SyncMenus()
    if not self.menuFont then return end
    local path,size,flags=self.menuFont:GetFont();local key=tostring(path)..":"..tostring(size)..":"..tostring(flags)
    for _,d in ipairs(self.dropdowns or {}) do
        if d.atcfMenuFont~=key or d.atcfSelectionValue~=d.value then d:GenerateMenu();d.atcfMenuFont=key;d.atcfSelectionValue=d.value end
    end
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
function U:ApplyAppearance()
    self:HideRowTip()
    local colors=M.Copy(self.owner.profile.colors)
    if self.theme then
        local function defaultColor(key) for i=1,3 do if colors[key][i]~=N.Settings.defaults.colors[key][i] then return false end end;return true end
        if defaultColor('background') then colors.background=self.theme.colors.surface end
        if defaultColor('text') then colors.text=self.theme.colors.text end
    end
    for key,value in pairs(self.previewColors or {}) do colors[key]=value end
    for _,button in ipairs(self.buttons or {}) do self:RefreshButton(button) end
    if not colors then return end
    for _,frame in ipairs(self.profileDialogs or {}) do frame:SetBackdropColor(colors.background[1],colors.background[2],colors.background[3],.94) end
    for _,entry in ipairs(self.texts) do if not entry[1].atcfOptions and not entry[1].atcfTooltip then entry[1]:SetTextColor(unpack(colors.text)) end end
    for _,row in ipairs(self.rows or {}) do row.name:SetTextColor(1,.82,0);row.lockedText:SetTextColor(.95,.25,.25) end
    if self.destinationName then self.destinationName:SetTextColor(1,.82,0) end
    if self.next then self.next:SetTextColor(1,.82,0) end
    if self.eagle then self.eagle:SetVertexColor(.88,.66,.16) end
    if self.arrow then self.arrow:SetVertexColor(unpack(gold)) end
end
function U:Button(parent,label,x,y,w,h,callback,card)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,h or 28)
    local inset=w<40 and 2 or 8
    self:StyleButton(b,card);b.text=self:Text(b,label,12,inset,0,w-inset*2,h or 28);b.text:SetJustifyH("CENTER")
    b:SetScript("OnClick",callback)
    return b
end
function U:Tip(frame,text)
    frame.atcfTip=text
    if frame.atcfTipHooked then return end;frame.atcfTipHooked=true
    frame:HookScript("OnEnter",function() GameTooltip:SetOwner(frame,"ANCHOR_RIGHT");GameTooltip:SetText(frame.atcfTip,nil,nil,nil,nil,true);GameTooltip:Show() end)
    local function hide() if GameTooltip:GetOwner()==frame then GameTooltip:Hide() end end
    frame:HookScript("OnLeave",hide);frame:HookScript("OnHide",hide)
end
function U:HideRowTip(frame)
    if self.rowTooltip and (not frame or self.rowTooltipOwner==frame) then
        self.rowTooltip:Hide();self.rowTooltipOwner=nil
    end
end
function U:ShowRowTip(frame)
    if not self.rowTooltip then
        local tip=CreateFrame("GameTooltip","AsTheCrowFliesRowTooltip",UIParent,"SharedTooltipTemplate")
        self.rowTooltip=tip;tip:SetScale(1)
        tip.TextLeft1.atcfFixedFont=true;tip.TextLeft1.atcfTooltip=true
    end
    local tip=self.rowTooltip;self.rowTooltipOwner=frame
    tip:SetOwner(frame,"ANCHOR_RIGHT")
    -- Set the owned line's font before native SetText measures its content.
    self:Font(tip.TextLeft1,11)
    tip:SetText("Travel time may vary based on terrain.",.76,.78,.82,1,true);tip:Show()
end
function U:RowTip(frame)
    frame:HookScript("OnEnter",function() self:ShowRowTip(frame) end)
    frame:HookScript("OnLeave",function() self:HideRowTip(frame) end)
    frame:HookScript("OnHide",function() self:HideRowTip(frame) end)
    frame:HookScript("OnMouseDown",function() self:HideRowTip(frame) end)
end
-- Use the client's control artwork, independent of the selected font. Atlas
-- dimensions describe the glyph; the 20px holder remains the alignment box.
local nativeIcons={
    cog={{file="Interface\\WorldMap\\GEAR_64GREY",width=64,height=64,size=20},{atlas="OptionsIcon-Brown",size=18}},
    back={{atlas="common-icon-rotateleft",size=18},{atlas="common-icon-backarrow",size=18},{file="Interface\\ChatFrame\\ChatFrameExpandArrow",width=16,height=16,size=20,flip=true}},
    location={{file="Interface\\Minimap\\UI-Minimap-Ping-Center",width=16,height=16,size=18}},
    filter={{atlas="gamepad-hud-icon-filter",size=18}},
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
function U:NavigationArrow(texture)
    texture:SetTexture(nil);texture:SetRotation(0);texture:SetDesaturated(true);texture:SetVertexColor(unpack(gold))
    local atlas="ui-worldmaparrow-2x"
    local info=N.Adapter.Call(C_Texture and C_Texture.GetAtlasInfo,atlas)
    local applied=false
    if info and M.Number(info.width) and info.width>0 and M.Number(info.height) and info.height>0 and texture.SetAtlas then
        applied=pcall(texture.SetAtlas,texture,atlas,false,nil,true,"CLAMP","CLAMP")
        if applied and texture.GetAtlas then applied=texture:GetAtlas()==atlas end
    end
    if applied then texture.atcfArrowAsset=atlas;return end
    -- The same up-facing player arrow in the supported client's native sheet.
    -- Keep its UV crop when the atlas lookup is unavailable.
    local ok,result=pcall(texture.SetTexture,texture,6152823,"CLAMP","CLAMP")
    if ok and result==true then
        texture:SetTexCoord(1/128,65/128,1/128,65/128);texture.atcfArrowAsset=6152823
    else
        texture:SetTexture(MEDIA.."arrow.tga");texture:SetTexCoord(0,1,0,1);texture.atcfArrowAsset="fallback"
    end
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
        b.text:SetText(({cog="S",back="<",location="+",filter="F",left="<",right=">"})[kind]);b.text:Show()
    end
    b.iconKind=kind
end
function U:PauseIcon(c)
    self:Icon(self.pause,c.nav.state=="nearby" and "done" or c.manualPause and "play" or "pause")
    self:Tip(self.pause,c.nav.state=="nearby" and "Confirm arrival" or c.manualPause and "Resume navigation" or "Pause navigation")
end
function U:SetDock(c,side,tuck)
    self:FinishMove(c,false);self:FinishResize(c,false)
    self:FinishHandleDrag()
    if not c:SetPreferences({dock=(side=="left" or side=="right") and side or "none"}) then return end;c.tucked=tuck and c.profile.dock~="none" or false
    N.Options:RefreshPlacement()
    self:Layout(c)
end
function U:HandleTravel()
    return math.max(0,UIParent:GetHeight()*UIParent:GetEffectiveScale()-self.handle:GetHeight()*self.handle:GetEffectiveScale())
end
function U:PlaceHandle(c)
    local side=c.profile.dock=="right" and "TOPRIGHT" or "TOPLEFT"
    local travel=math.max(0,UIParent:GetHeight()/self.handle:GetScale()-self.handle:GetHeight())
    self.handle:ClearAllPoints();self.handle:SetPoint(side,UIParent,side,0,-c.profile.dockPosition*travel)
end
function U:FinishHandleDrag()
    self.handleDrag=nil
    if self.handle then self.handle:SetScript("OnUpdate",nil) end
end
function U:UpdateHandleDrag(c)
    if c.gestureWrite then return end -- Settings notification can synchronously relayout the handle.
    local drag=self.handleDrag;if not drag then return end
    if drag.profile~=c.profileGeneration or drag.side~=c.profile.dock or c.profile.locked or c.hidden or not c.tucked or drag.travel~=self:HandleTravel() then
        self:FinishHandleDrag();return
    end
    local _,y=N.Adapter.Call(GetCursorPosition)
    if N.Adapter.Number(y) and drag.travel>0 then
        c:SetPreferences({dockPosition=math.max(0,math.min(1,drag.position+(drag.cursorY-y)/drag.travel))},true)
        self:PlaceHandle(c)
    end
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
    local categories={class="Class trainer",profession="Profession trainer",trainer="Trainer",auction="Auction house",transmog="Transmogrifier",quest="Quest NPC",flight="Flight point",place="Saved place"}
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
    if left and top then c:SetPreferences({x=math.max(-20000,math.min(20000,left)),y=math.max(-20000,math.min(20000,top-UIParent:GetHeight()/self.frame:GetScale()))},true) end
end
function U:GestureGeometry(c)
    return {width=UIParent:GetWidth(),height=UIParent:GetHeight(),scale=UIParent:GetEffectiveScale(),profileScale=c.profile.scale}
end
function U:GeometryChanged(c,geometry)
    return not geometry or geometry.width~=UIParent:GetWidth() or geometry.height~=UIParent:GetHeight()
        or geometry.scale~=UIParent:GetEffectiveScale() or geometry.profileScale~=c.profile.scale
end
function U:FinishMove(c,save)
    if not self.dragging then return end
    self.dragging=false;self.frame:StopMovingOrSizing()
    if save and self.moveProfile==c.profileGeneration then self:SavePlacement(c) end
    self.moveProfile=nil;self.moveGeometry=nil;self.moveWidth=nil
end
function U:FinishResize(c,save)
    if not self.resizing then return end
    self.resizing=false;self.frame:StopMovingOrSizing()
    if save~=false and self.resizeProfile==c.profileGeneration then
        if self.pendingResultsHeight then c:SetPreferences({resultsHeight=self.pendingResultsHeight},true) end
        self:SavePlacement(c)
    end
    self.pendingResultsHeight=nil
    self.resizeProfile=nil;self.resizeMode=nil;self.resizeGeometry=nil
    N.Options:RefreshPlacement()
end
function U:CancelStaleGestures(c)
    -- A native gesture belongs to its starting profile and coordinate system.
    -- Cancel before layout so a hide, profile switch or display change can apply.
    local unavailable=c.hidden or c.tucked or c.profile.locked
    if self.dragging and (unavailable or self.moveProfile~=c.profileGeneration or self.moveWidth~=c.profile.width
        or self:GeometryChanged(c,self.moveGeometry)) then self:FinishMove(c,false) end
    if self.resizing and (unavailable or self.resizeProfile~=c.profileGeneration or self.resizeMode~=self:ResizeMode(c)
        or self:GeometryChanged(c,self.resizeGeometry)) then self:FinishResize(c,false) end
end
function U:ResizeMode(c)
    local results=not (c.compact and c.nav.route) and (c.matches and #c.matches>0 or not c.matches and #c.results>0)
    return results and "results" or "width"
end
function U:FitAction(button,width,minimum)
    button:SetWidth(width);button.text:ClearAllPoints();button.text:SetPoint("TOPLEFT",8,0)
    button.text:SetWidth(math.max(1,width-16));button.text:SetWordWrap(true);button.text:SetNonSpaceWrap(true)
    local height=math.max(minimum or 28,self:WrappedHeight(button.text)+12)
    button:SetHeight(height);button.text:SetHeight(height);return height
end
function U:ScrollIndicator(offset)
    local range=self.bodyScrollRange or 0;local visible=self.bodyScroll:GetHeight()
    self.scrollRail:SetShown(range>0 and self.bodyScroll:IsShown());self.scrollThumb:SetShown(range>0 and self.bodyScroll:IsShown())
    if range<=0 then return end
    local height=math.max(12,visible*visible/(visible+range));self.scrollRail:SetHeight(visible);self.scrollThumb:SetHeight(height)
    self.scrollThumb:ClearAllPoints();self.scrollThumb:SetPoint("TOPLEFT",self.scrollRail,"TOPLEFT",0,-math.min(range,math.max(0,offset or 0))/range*(visible-height))
end
function U:Menu(parent,x,y,w,label,entries,choose)
    local d=CreateFrame("DropdownButton",nil,parent,"WowStyle1DropdownTemplate");d:SetPoint("TOPLEFT",x,y);d:SetSize(w,24);d:SetDefaultText(label)
    if not self.menuFont then self.menuFont=CreateFont("AsTheCrowFliesMenuFont");self.menuFont.atcfFixedFont=true;self.menuFont.atcfOptions=true;self:Font(self.menuFont,12);checkAppearance(self.menuFont,'color',N.App.ui:Color(self.menuFont,'text')) end
    if d.Text then self:Font(d.Text,12);d.Text:ClearAllPoints();d.Text:SetPoint("LEFT",d,"LEFT",9,0);d.Text:SetSize(w-31,24);d.Text:SetJustifyH("LEFT");d.Text:SetJustifyV("MIDDLE");d.Text:SetWordWrap(false) end
    d:SetupMenu(function(_,root)
        root:SetScrollMode(220)
        for _,entry in ipairs(entries()) do
            local row=root:CreateRadio(entry.label,function() return d.value==entry.value end,function() d.value=entry.value;d:SetDefaultText(entry.label);choose(entry.value) end)
            row:AddInitializer(function(button) button.fontString:SetFontObject(self.menuFont) end)
        end
    end)
    self.dropdowns=self.dropdowns or {};self.dropdowns[#self.dropdowns+1]=d;return d
end
function U:RefreshFilter(c)
    local d=self.filterButton;local tint=M.HasFilter(c.filter) and {1,.82,0} or {.75,.75,.75}
    d.icons.filter.texture:SetVertexColor(tint[1],tint[2],tint[3],1);d.text:SetTextColor(unpack(tint))
    self:RefreshButton(d)
end
function U:FilterMenu(parent,c)
    -- The intrinsic DropdownButton owns mouse dismissal, Escape and menu input.
    local d=CreateFrame("DropdownButton",nil,parent,"BackdropTemplate");self.filterButton=d
    d:SetPoint("TOPLEFT",c.profile.width-38,-42);d:SetSize(24,28)
    self:StyleButton(d)
    d.text=self:Text(d,"F",12,0,0,24,28);d.text:SetJustifyH("CENTER");self:Icon(d,"filter")
    if not self.menuFont then self.menuFont=CreateFont("AsTheCrowFliesMenuFont");self.menuFont.atcfFixedFont=true;self.menuFont.atcfOptions=true;self:Font(self.menuFont,12);checkAppearance(self.menuFont,'color',N.App.ui:Color(self.menuFont,'text')) end
    d:SetupMenu(function(_,root)
        root:SetScrollMode(280)
        local function checkbox(container,label,selected,group,key)
            local row=container:CreateCheckbox(label,selected,function() c:Filter(group,key) end)
            row:AddInitializer(function(button) button.fontString:SetFontObject(self.menuFont) end)
            return row
        end
        checkbox(root,"All",function() return not M.HasFilter(c.filter) end,"all")
        for _,entry in ipairs({{"Auction houses","auction"},{"Class trainers","class"},{"Profession trainers","profession"},{"Other trainers","trainer"},{"Transmogrifiers","transmog"},{"Quest NPCs","quest"},{"Flight points","flight"},{"Saved places","place"}}) do
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
    d:RegisterCallback("OnMenuOpen",function() self:RefreshFilter(c) end,self)
    d:RegisterCallback("OnMenuClose",function() self:RefreshFilter(c) end,self)
    self.dropdowns=self.dropdowns or {};self.dropdowns[#self.dropdowns+1]=d
    return d
end
function U:Edit(parent,label,y,origin)
    local caption=self:Text(parent,label,12,14,y,44,32);caption:SetTextColor(.65,.68,.73)
    self.fieldLabels=self.fieldLabels or {};self.fieldLabels[#self.fieldLabels+1]=caption
    local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate");e:SetPoint("TOPLEFT",62,y);e:SetSize(self.owner.profile.width-104,32);e:SetAutoFocus(false);e:SetMaxLetters(100)
    self:ControlArt(e);self:Font(e,13);e:SetTextInsets(8,8,0,0);e:SetJustifyV("MIDDLE")
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
    self.owner=c;local f=CreateFrame("Frame","AsTheCrowFliesPanel",UIParent,"BackdropTemplate");self.frame=f;f:Hide()
    f:SetMovable(true);f:SetResizable(true);f:EnableMouse(true);f:SetClampedToScreen(true);f:SetFrameStrata(c.profile.strata);f:SetFrameLevel(100)
    self:Dialog(f,true)
    local header=CreateFrame("Frame",nil,f);self.header=header;header:SetPoint("TOPLEFT");header:SetSize(c.profile.width-78,44);header:EnableMouse(true);header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function()
        if c.profile.locked or c.hidden or c.tucked or self.resizing then return end
        self.moveProfile=c.profileGeneration;self.moveGeometry=self:GestureGeometry(c);self.moveWidth=c.profile.width;self.dragging=true;f:StartMoving()
    end)
    header:SetScript("OnDragStop",function()
        self:CancelStaleGestures(c)
        if not self.dragging then self:Layout(c);return end
        self:FinishMove(c,true)
        local left=f:GetLeft();local screen=UIParent:GetWidth()/f:GetScale()
        self:SetDock(c,left<24 and "left" or (left+c.profile.width>screen-24 and "right" or "none"),true)
    end)
    local eagle=header:CreateTexture(nil,"ARTWORK");self.eagle=eagle;eagle:SetTexture(MEDIA.."eagle.tga");eagle:SetPoint("LEFT",header,"LEFT",14,0);eagle:SetSize(24,24);eagle:SetVertexColor(.88,.66,.16)
    self.title=self:Text(header,"AS THE CROW FLIES",11,46,0,184,24);self.title:ClearAllPoints();self.title:SetPoint("LEFT",header,"LEFT",46,0)
    self.title.atcfFixedFont=true;self:Font(self.title,11);self.title:SetWordWrap(true);self.title:SetHeight(32)
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
    self.bodyScroll:SetScript("OnVerticalScroll",function(_,offset) self:HideRowTip();self:ScrollIndicator(offset) end)
    self.bodyScroll:SetScript("OnHide",function() self:HideRowTip() end)
    self.routeHeading=CreateFrame("Frame",nil,f)
    self.destinationName=self:Text(self.routeHeading,"",13,0,0,c.profile.width-28,20)
    self.destinationName.atcfEmphasis=true;self.destinationName.atcfSoftShadow=true;self:Font(self.destinationName,13)
    self.destinationDetail=self:Text(self.routeHeading,"",12,0,-20,c.profile.width-28,20)
    self.destinationDetail.atcfEmphasis=true;self.destinationDetail.atcfSoftShadow=true;self:Font(self.destinationDetail,12)
    for _,text in ipairs({self.destinationName,self.destinationDetail}) do text:SetWordWrap(true);text:SetNonSpaceWrap(true);text:SetJustifyV("TOP") end
    self.sortLabel=self:Text(self.routeHeading,"Sort",11,0,0,36,24)
    self.routeOrder=self:Menu(self.routeHeading,38,0,c.profile.width-66,"Distance",function() return {{label="Distance",value="distance"},{label="Estimated time",value="time"}} end,function(value) c:SetRouteOrder(value) end)
    self.routeOrder:SetHeight(24)
    self:ControlArt(self.routeOrder)
    if self.routeOrder.Text then self.routeOrder.Text.atcfFixedFont=true;self:Font(self.routeOrder.Text,12);self.routeOrder.Text:SetHeight(24) end
    self.resultsBoundary=f:CreateTexture(nil,"ARTWORK");self.resultsBoundary:SetColorTexture(.26,.28,.32,1);self.resultsBoundary:SetHeight(1);self.resultsBoundary:Hide()
    self.rows={}
    for i=1,40 do
        local b=self:Button(self.body,"",0,-(i-1)*83,c.profile.width-28,77,function()
            if c.matches then self.from:ClearFocus();self.to:ClearFocus();c:Choose(c.matches[i],c.searchOrigin)
            else c.selected=i;c:Refresh() end
        end,true)
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
        b.locked=CreateFrame("Frame",nil,b);b.locked:SetAllPoints(b);b.locked:SetFrameLevel(b:GetFrameLevel()+4)
        local shade=b.locked:CreateTexture(nil,"BACKGROUND");shade:SetAllPoints();shade:SetColorTexture(0,0,0,.68)
        b.lockedText=self:Text(b.locked,"Undiscovered flight points",11,6,0,c.profile.width-40,22);b.lockedText:ClearAllPoints();b.lockedText:SetPoint("CENTER");b.lockedText:SetTextColor(.95,.25,.25)
        b.locked:Hide()
        self:RowTip(b);self.rows[i]=b
    end
    local function scroll(_,delta)
        local old=self.bodyScroll:GetVerticalScroll();local range=self.bodyScrollRange or 0
        local next=math.max(0,math.min(range,old-delta*40))
        if next~=old then self.bodyScroll:SetVerticalScroll(next);self:ScrollIndicator(next) end
    end
    self.body:EnableMouseWheel(true);self.body:SetScript("OnMouseWheel",scroll);self.bodyScroll:EnableMouseWheel(true);self.bodyScroll:SetScript("OnMouseWheel",scroll)
    self.note=self:Text(f,"",11,14,-200,c.profile.width-28,44);self.note:SetWordWrap(true);self.note:SetJustifyH("CENTER");self.note:SetTextColor(.68,.71,.76)
    self.go=self:Button(f,"Find routes",14,-246,c.profile.width-88,30,function() self.from:ClearFocus();self.to:ClearFocus();c:PrimaryAction() end)
    self.stop=self:Button(f,"",c.profile.width-42,-246,28,28,function() c:Stop() end);self:Icon(self.stop,"close");self:Tip(self.stop,"Stop navigation")
    self.guidance=CreateFrame("Frame",nil,f);self.guidance:SetPoint("TOPLEFT",14,-48);self.guidance:SetSize(c.profile.width-28,94)
    self.arrow=self.guidance:CreateTexture(nil,"ARTWORK");self:NavigationArrow(self.arrow);self.arrow:SetPoint("TOPLEFT",0,-4);self.arrow:SetSize(32,32)
    self.next=self:Text(self.guidance,"",13,44,0,c.profile.width-72,25);self.next.atcfEmphasis=true;self.next.atcfFontScale=1.1;self:Font(self.next,13);self.next:SetTextColor(1,.82,0)
    self.next:SetWordWrap(true);self.next:SetNonSpaceWrap(true);self.next:SetJustifyV("TOP")
    self.cardinal=self:Text(self.guidance,"",11,0,-39,32,16);self.cardinal:SetJustifyH("CENTER")
    self.remaining=self:Text(self.guidance,"",11,44,-25,c.profile.width-72,20);self.remaining.atcfFontScale=1.1;self:Font(self.remaining,11)
    self.remaining:SetWordWrap(true);self.remaining:SetJustifyV("TOP")
    self.directionNote=self:Text(self.guidance,"",11,0,-61,c.profile.width-28,38);self.directionNote.atcfFontScale=1.1;self:Font(self.directionNote,11);self.directionNote:SetWordWrap(true)
    self.expand=self:Button(f,"Edit / routes",14,-147,c.profile.width-154,28,function() c.compact=false;c:Refresh() end)
    self.expand.text.atcfFontScale=1.1;self:Font(self.expand.text,12)
    self.pause=self:Button(f,"",c.profile.width-76,-147,28,28,function()
        if c.nav.state=="nearby" then c:Arrive()
        else c.manualPause=not c.manualPause;c.nav.measure=nil;c.nav.dwell=nil;c.nav.previous=nil;c.nav.previousTime=nil;c:Refresh() end
    end)
    self:PauseIcon(c)
    self.fold=self:Button(f,"Fold",14,-125,50,30,function() c.compact=true;c:Refresh() end)
    local handle=CreateFrame("Button",nil,UIParent,"BackdropTemplate");self.handle=handle;handle:Hide();handle:SetSize(24,64);handle:SetFrameStrata(c.profile.strata);handle:SetFrameLevel(100);handle:RegisterForDrag("LeftButton")
    self:StyleButton(handle)
    handle.text=self:Text(handle,">",16,0,0,24,64);handle.text:SetJustifyH("CENTER")
    handle:SetScript("OnMouseDown",function(_,button) if button=="LeftButton" then self.handleSuppressClick=false end end)
    handle:SetScript("OnDragStart",function()
        if c.profile.locked or c.hidden or not c.tucked then return end
        self.handleSuppressClick=true
        local _,y=N.Adapter.Call(GetCursorPosition)
        if not N.Adapter.Number(y) then return end
        self.handleDrag={profile=c.profileGeneration,side=c.profile.dock,cursorY=y,position=c.profile.dockPosition,travel=self:HandleTravel()}
        handle:SetScript("OnUpdate",function() self:UpdateHandleDrag(c) end)
    end)
    local function finishHandle() self:UpdateHandleDrag(c);self:FinishHandleDrag() end
    handle:SetScript("OnDragStop",finishHandle)
    handle:SetScript("OnMouseUp",function(_,button) if button=="LeftButton" then finishHandle() end end)
    handle:HookScript("OnHide",function() self:FinishHandleDrag() end)
    handle:SetScript("OnClick",function() if not self.handleSuppressClick then c.tucked=false;self:Layout(c) end end)
    self:Tip(handle,"Click to expand. Drag up or down to move.")
    local grip=CreateFrame("Button",nil,f);self.resizeGrip=grip;grip:SetSize(18,18);grip:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1);grip:SetFrameLevel(f:GetFrameLevel()+10)
    grip.texture=grip:CreateTexture(nil,"ARTWORK");grip.texture:SetAllPoints();grip.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    self:Tip(grip,"Drag to resize")
    grip:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton" or c.profile.locked or self.dragging or not grip:IsShown() then return end
        self.resizeMode=self:ResizeMode(c);self.resizeProfile=c.profileGeneration;self.resizeGeometry=self:GestureGeometry(c)
        self.resizeChrome=f:GetHeight()-self.bodyScroll:GetHeight();self.resizing=true
        self:SavePlacement(c);c:SetPreferences({dock="none"});f:StartSizing(self.resizeMode=="results" and "BOTTOMRIGHT" or "RIGHT")
    end)
    grip:SetScript("OnMouseUp",function(_,button) if button=="LeftButton" and self.resizing then self:FinishResize(c);c:Refresh() end end)
    grip:SetScript("OnHide",function() self:FinishResize(c,false) end)
    -- BackdropTemplate owns border tiling when the panel's dimensions change.
    f:HookScript("OnSizeChanged",function(_,width,height)
        if not self.resizing or self.resizeLayout then return end
        self:CancelStaleGestures(c);if not self.resizing then return end
        local changes={width=math.max(N.Settings.minWidth,math.min(N.Settings.maxWidth,width))}
        if self.resizeMode=="results" then changes.resultsHeight=math.max(100,math.min(560,height-self.resizeChrome)) end
        self.resizeLayout=true;c:SetPreferences(changes,true);self:Refresh(c);self.resizeLayout=false
    end)
    f:SetScript("OnHide",function()
        self:HideRowTip()
        self:FinishResize(c,false);self:FinishMove(c,false)
    end)
    self.from:SetText("Current location");self:Layout(c)
    local menu=CreateFrame("Frame","AsTheCrowFliesMenu",f,"BackdropTemplate");self.menu=menu;menu:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-40);menu:SetSize(196,172);menu:SetFrameStrata("DIALOG");menu:SetFrameLevel(f:GetFrameLevel()+20);menu:EnableMouse(true);menu:SetClampedToScreen(true);self:Dialog(menu,true)
    menu:SetScript("OnShow",function() self:PlaceMenu() end)
    local function action(label,y,fn)
        local b=self:Button(menu,label,8,y,180,26,function() menu:Hide();fn() end);b.text.atcfFixedFont=true;self:Font(b.text,12);return b
    end
    self.menuOptions=action("Settings",-8,function() N.Options:Open() end)
    self.menuSave=action("Save current location",-40,function() SlashCmdList.ASTHECROWFLIES("remember") end)
    self.menuLock=action("Lock / unlock panel",-72,function() c:SetPreferences({locked=not c.profile.locked}) end)
    self.menuTuck=action("Tuck to screen edge",-104,function() self:SetDock(c,c.profile.dock=="none" and "right" or c.profile.dock,true) end)
    self.menuClose=action("Close menu",-136,function() end);menu:Hide()
    UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"AsTheCrowFliesMenu")
end
function U:PlaceMenu()
    local menu=self.menu
    if not menu or not menu:IsShown() then return end
    local top=self.frame:GetTop();if not top then return end
    local scale=menu:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local height=UIParent:GetHeight()/scale
    local menuTop=math.max(menu:GetHeight(),math.min(height,top-40))
    menu:ClearAllPoints();menu:SetPoint("TOPRIGHT",self.frame,"TOPRIGHT",-8,menuTop-top)
end
function U:Layout(c)
    self:CancelStaleGestures(c)
    local f,p=self.frame,c.profile
    f:SetFrameStrata(p.strata);self.handle:SetFrameStrata(p.strata)
    -- Native dragging owns the frame anchor until release. Refreshes during
    -- guidance, indexing or font registration must not snap it back.
    if self.dragging then return end
    local scale=self.resizing and f:GetScale() or math.min(p.scale,UIParent:GetHeight()/660,UIParent:GetWidth()/(p.width+16))
    if not self.resizing then f:SetScale(scale);f:SetWidth(p.width);f:ClearAllPoints() end
    local function move(control,x,y) control:ClearAllPoints();control:SetPoint("TOPLEFT",x,y) end
    self.header:SetWidth(p.width-78);self.title:SetWidth(p.width-124)
    move(self.settings,p.width-68,-9);move(self.tuck,p.width-38,-9);move(self.current,p.width-38,-2)
    local labelWidth=0
    for _,label in ipairs(self.fieldLabels) do labelWidth=math.max(labelWidth,label:GetUnboundedStringWidth()) end
    labelWidth=math.min(math.ceil(labelWidth)+2/math.max(.1,f:GetEffectiveScale()),p.width-164)
    local fieldLeft=14+labelWidth+8
    for _,label in ipairs(self.fieldLabels) do label:SetWidth(labelWidth) end
    move(self.from,fieldLeft,0);move(self.to,fieldLeft,-40)
    self.from:SetWidth(p.width-fieldLeft-42);self.to:SetWidth(p.width-fieldLeft-42);self.body:SetWidth(p.width-28);self.bodyScroll:SetWidth(p.width-28)
    move(self.filterButton,p.width-38,-42);self.note:SetWidth(p.width-28)
    self.guidance:SetWidth(p.width-28);self.next:SetWidth(p.width-72);self.remaining:SetWidth(p.width-72);self.directionNote:SetWidth(p.width-28)
    for _,row in ipairs(self.rows) do row:SetWidth(p.width-28);row.lockedText:SetWidth(p.width-40) end
    local sw,sh=UIParent:GetWidth()/scale,UIParent:GetHeight()/scale
    local x=p.dock=="right" and sw-p.width-8 or p.dock=="left" and 8 or p.x
    local top=p.dock~="none" and -p.dockPosition*math.max(0,sh-self.handle:GetHeight()) or p.y
    local y=math.max(-(sh-math.min(f:GetHeight(),sh)),math.min(0,top))
    if not self.resizing then
        f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",math.max(0,math.min(sw-p.width,x)),y)
    end
    if self.resizeGrip:IsShown() then
        local results=self:ResizeMode(c)=="results"
        local chrome=math.max(0,f:GetHeight()-self.bodyScroll:GetHeight())
        local minimum=results and chrome+100 or 1
        f:SetResizeBounds(N.Settings.minWidth,minimum,math.max(N.Settings.minWidth,math.min(N.Settings.maxWidth,sw-16)),math.max(minimum,results and math.min(chrome+560,sh-16) or sh-16))
    end
    self.handle:SetScale(scale);self:UpdateHandleDrag(c);self:PlaceHandle(c)
    self:PlaceMenu()
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
    local actionHeight=self:FitAction(self.expand,c.profile.width-96,28)
    for _,entry in ipairs({{self.expand,14},{self.pause,c.profile.width-76},{self.stop,c.profile.width-42}}) do
        local offset=entry[1]==self.expand and 0 or (actionHeight-entry[1]:GetHeight())/2
        entry[1]:ClearAllPoints();entry[1]:SetPoint("TOPLEFT",entry[2],-footer-offset)
    end
    local height=footer+actionHeight+22;local changed=self.frame:GetHeight()~=height;self.frame:SetHeight(height);return changed
end
function U:Refresh(c)
    self:CancelStaleGestures(c)
    if not self.dragging and not self.resizing then self.frame:SetScale(math.min(c.profile.scale,UIParent:GetHeight()/660,UIParent:GetWidth()/(c.profile.width+16))) end
    if self.menuLock then self.menuLock.text:SetText(c.profile.locked and "Unlock panel" or "Lock panel") end
    local compact=c.compact and c.nav.route~=nil
    local expanded=c.searching or c.matches~=nil or c.destination~=nil or #c.results>0 or c.nav.route~=nil or c.planned
    local arrival=not expanded and c.arrivalUntil and c.arrivalUntil>GetTime()
    self.resizeGrip:SetShown(not c.profile.locked)
    self.editor:SetShown(not compact);self.body:SetShown(not compact and expanded);self.bodyScroll:SetShown(not compact and expanded);self.guidance:SetShown(compact);self.expand:SetShown(compact);self.go:SetShown(not compact and expanded and (c.matches~=nil or #c.results==0));self.note:SetShown(not compact and expanded)
    self:ScrollIndicator(self.bodyScroll:GetVerticalScroll())
    self.stop:SetShown(c.nav.route~=nil);self.fold:SetShown(not compact and c.nav.route~=nil)
    self:RefreshFilter(c)
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
            if self.routeOrder.Text then self.routeOrder.Text:SetWidth(self.routeOrder:GetWidth()-31) end
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
                b.atcfSelected=c.matches and i==c.highlight or not c.matches and i==c.selected;self:RefreshButton(b)
            end
        end
        bodyHeight=math.max(0,bodyHeight-5)
        self.body:SetHeight(math.max(1,bodyHeight))
        local message=arrival and "Arrived!" or expanded and c.status or nil
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
        self.note:SetTextColor(unpack(arrival and gold or c.profile.colors and c.profile.colors.text or ink))
        local messageHeight=message and (self:WrappedHeight(self.note,arrival and 16 or 32)+10) or 0
        self.go.text:SetText(c:PrimaryActionLabel());self.go:SetEnabled(not c.searching and not (c.matches and #c.matches==0))
        local foldWidth=math.max(50,math.ceil(self.fold.text:GetUnboundedStringWidth())+16)
        local foldHeight=self:FitAction(self.fold,foldWidth,30)
        local available=c.profile.width-(c.nav.route and foldWidth+74 or 28)
        local goWidth=math.min(available,math.ceil(self.go.text:GetUnboundedStringWidth())+32)
        local goHeight=self:FitAction(self.go,goWidth,30)
        local footerHeight=math.max(self.go:IsShown() and goHeight or 0,self.fold:IsShown() and foldHeight or 0,self.stop:IsShown() and 28 or 0)+22
        local bodyGap=bodyHeight>0 and ((self.go:IsShown() or self.fold:IsShown() or self.stop:IsShown()) and 16 or 8) or 0
        local scale=self.resizing and self.frame:GetScale() or math.min(c.profile.scale,UIParent:GetHeight()/660,UIParent:GetWidth()/(c.profile.width+16))
        local limit=(UIParent:GetHeight()-16)/scale-bodyTop-messageHeight-footerHeight-bodyGap
        local requested=c.profile.resultsHeight
        local resizingResults=self.resizing and self.resizeMode=="results"
        if resizingResults then
            -- Width changes can wrap fixed headings/status text while native
            -- sizing owns the outer frame. Rebudget the viewport immediately.
            self.resizeChrome=bodyTop+messageHeight+bodyGap+footerHeight
            requested=math.max(1,math.min(560,self.frame:GetHeight()-self.resizeChrome))
            self.pendingResultsHeight=math.max(100,requested)
        end
        local visible=math.max(0,math.min(resizingResults and requested or bodyHeight,requested,math.max(1,limit)))
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
            y=y+bodyGap
        end
        self.note:ClearAllPoints();self.note:SetPoint("TOPLEFT",14,-y)
        local footer=y+messageHeight
        self.go:ClearAllPoints();self.go:SetPoint("TOPLEFT",(c.nav.route and foldWidth+24 or 14)+(available-goWidth)/2,-footer)
        self.stop:ClearAllPoints();self.stop:SetPoint("TOPLEFT",c.profile.width-42,-footer)
        self.fold:ClearAllPoints();self.fold:SetPoint("TOPLEFT",14,-footer)
        if not resizingResults then self.frame:SetHeight((expanded or arrival) and (footer+footerHeight) or 139) end
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
    if c.hidden then c:ShowPanel(true);return elseif c.tucked then c.tucked=false elseif c.nav.route then c.compact=not c.compact else c.tucked=true end
    self:Refresh(c)
end
_G.BINDING_HEADER_ASTHECROWFLIES="As The Crow Flies"
_G.BINDING_NAME_ASTHECROWFLIES_TOGGLE="Expand / collapse navigation"
