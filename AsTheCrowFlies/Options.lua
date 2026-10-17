local _,N=...;local O={};N.Options=O
-- FindAnUpgrade is the reference for native controls, sizing and chrome.
local gold={1,.82,.2}
local dialogWidth,dialogHeight=640,500
local bodyWidth,bodyHeight=608,404
function O:Label(parent,text,x,y,width,size,color)
    local t=parent:CreateFontString(nil,"OVERLAY");t.atcfFixedFont=true;t.atcfOptions=true;N.UI:Font(t,size or 12)
    t:SetPoint("TOPLEFT",x,y);t:SetSize(width or 260,(size or 12)+6);t:SetJustifyH("LEFT");t:SetJustifyV("MIDDLE");t:SetWordWrap(false)
    t:SetTextColor(unpack(color or {.93,.94,.97}));t:SetShadowColor(0,0,0,.65);t:SetShadowOffset(1,-1);t:SetText(text or "");return t
end
function O:Bound(t,width,height,point,parent,relative,x,y)
    self.bounded[#self.bounded+1]={text=t,width=width,height=height,point=point,parent=parent,relative=relative,x=x,y=y}
end
function O:Button(parent,text,x,y,width,callback)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(width,22)
    N.UI:StyleButton(b)
    b.text=self:Label(b,text,0,0,width-12);self:Bound(b.text,width-12,20,"CENTER",b,"CENTER",0,0)
    b:SetScript("OnClick",callback);return b
end
function O:Section(parent,label,x,y,w,h)
    local box=CreateFrame("Frame",nil,parent,"BackdropTemplate");box:SetFrameLevel(parent:GetFrameLevel()-1)
    box:SetPoint("TOPLEFT",x,y-9);box:SetSize(w,h);N.UI:Section(box)
    self:Label(parent,label,x+10,y,w-20,12,gold);return box
end
function O:Edit(parent,x,y,width)
    local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate");e:SetPoint("TOPLEFT",x,y);e:SetSize(width,22)
    e.atcfFixedFont=true;e.atcfOptions=true;N.UI:Font(e,12);e:SetTextInsets(6,6,0,0);e:SetAutoFocus(false);e:SetMaxLetters(48)
    e:SetScript("OnEscapePressed",function() e:ClearFocus();self:Refresh() end);return e
end
function O:Dropdown(parent,x,y,width,label,entries,choose)
    local d=N.UI:Menu(parent,x,y,width,label,entries,choose);d:SetHeight(24)
    d.Text.atcfFixedFont=true;d.Text.atcfOptions=true;N.UI:Font(d.Text,12);d.Text:SetTextColor(.93,.94,.97)
    self:Bound(d.Text,width-31,24,"LEFT",d,"LEFT",9,0);self.bounded[#self.bounded].dropdown=d
    -- Generated native selection text can replace the fallback at any time.
    hooksecurefunc(d.Text,"SetText",function(_,value) if not d.formattingCaption then self:Caption(d,value) end end)
    d:HookScript("OnEnter",function()
        if d.truncatedCaption then GameTooltip:SetOwner(d,"ANCHOR_RIGHT");GameTooltip:SetText(d.fullCaption,nil,nil,nil,nil,true);GameTooltip:Show() end
    end)
    local function hideTip() if GameTooltip:GetOwner()==d then GameTooltip:Hide() end end
    d:HookScript("OnLeave",hideTip);d:HookScript("OnHide",hideTip)
    self:Caption(d,d.Text:GetText());return d
end
function O:Caption(dropdown,value)
    local t=dropdown.Text;local label=value or ""
    dropdown.fullCaption=label;dropdown.formattingCaption=true
    t:SetScale(1);t:SetText(label)
    local scale=t:GetEffectiveScale();local available=dropdown:GetWidth()-31
    local function width() return (math.ceil(t:GetUnboundedStringWidth()*scale)+4)/scale end
    dropdown.truncatedCaption=width()>available
    if dropdown.truncatedCaption then
        repeat
            -- Remove complete UTF-8 codepoints, preserving the stored value.
            local last=#label
            while last>1 and label:byte(last)>=128 and label:byte(last)<192 do last=last-1 end
            label=label:sub(1,last-1);t:SetText(label.."...")
        until width()<=available or label==""
    end
    dropdown.formattingCaption=nil
end
function O:CloseTransient()
    for _,d in ipairs(N.UI.dropdowns or {}) do
        d:CloseMenu();if GameTooltip:GetOwner()==d then GameTooltip:Hide() end
    end
    for _,e in ipairs({self.name,self.fontSize,self.scaleEdit}) do e:ClearFocus() end
end
function O:Scroll(offset)
    offset=math.max(0,math.min(self.maximum or 0,offset))
    if offset~=(self.offset or 0) then self:CloseTransient() end
    self.offset=offset;self.scrolling=true
    self.scroll:SetVerticalScroll(offset);self.bar:SetValue(offset);self.scrolling=nil
end
function O:Check(parent,label,key,x,y)
    local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate");b:SetPoint("TOPLEFT",x-4,y);b:SetSize(24,24)
    local text=b.Text or self:Label(parent,label,x+24,y,230);b.text=text
    text.atcfFixedFont=true;text.atcfOptions=true;N.UI:Font(text,12);text:SetText(label);text:SetJustifyH("LEFT");text:SetTextColor(.93,.94,.97)
    self:Bound(text,230,24,"LEFT",b,"RIGHT",0,0);b:SetHitRectInsets(0,-230,0,0)
    b:SetScript("OnClick",function() self.owner.profile[key]=b:GetChecked();self.owner:ApplyProfile() end);return b
end
function O:Create(c)
    self.owner=c;self.bounded={};local U=N.UI
    local f=CreateFrame("Frame","AsTheCrowFliesOptions",UIParent,"BackdropTemplate");self.frame=f
    f:SetSize(dialogWidth,dialogHeight);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
    U:Dialog(f)
    f:SetScript("OnDragStart",function() f:StartMoving() end);f:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
    local content=CreateFrame("Frame",nil,f);content:SetAllPoints()
    self:Label(content,"As The Crow Flies",20,-15,350,16,gold)
    self.close=CreateFrame("Button",nil,content,"UIPanelCloseButton");self.close:SetSize(24,24);self.close:SetPoint("TOPRIGHT",-8,-8)
    self.close:SetScript("OnClick",function() f:Hide();self:CloseColor() end)
    self.optionsTab=self:Button(content,"Options",20,-42,86,function() self:Page(false) end)
    self.profilesTab=self:Button(content,"Profiles",110,-42,86,function() self:Page(true) end)
    for _,tab in ipairs({self.optionsTab,self.profilesTab}) do
        tab.activeLine=tab:CreateTexture(nil,"OVERLAY");tab.activeLine:SetHeight(1);tab.activeLine:SetColorTexture(1,.82,.2,.8)
        tab.activeLine:SetPoint("BOTTOMLEFT",tab,"BOTTOMLEFT",4,0);tab.activeLine:SetPoint("BOTTOMRIGHT",tab,"BOTTOMRIGHT",-4,0)
    end
    local scroll=CreateFrame("ScrollFrame",nil,content);self.scroll=scroll
    scroll:SetPoint("TOPLEFT",0,-72);scroll:SetSize(bodyWidth,bodyHeight);scroll:EnableMouseWheel(true)
    local body=CreateFrame("Frame",nil,scroll);self.body=body;body:SetSize(bodyWidth,bodyHeight);scroll:SetScrollChild(body)
    scroll:SetScript("OnMouseWheel",function(_,delta) self:Scroll((self.offset or 0)-delta*28) end)
    -- Vertical native assets, matching FAU; UISliderTemplate has horizontal art.
    local bar=CreateFrame("Slider",nil,content,"BackdropTemplate");self.bar=bar
    bar:SetPoint("TOPRIGHT",-14,-76);bar:SetSize(12,bodyHeight-8);bar:SetOrientation("VERTICAL");bar:EnableMouse(true)
    bar:SetBackdrop({bgFile="Interface\\Buttons\\UI-SliderBar-Background",edgeFile="Interface\\Buttons\\UI-SliderBar-Border",tile=true,tileSize=8,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
    bar:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical");bar:GetThumbTexture():SetSize(12,22);bar:SetValueStep(1)
    bar:SetScript("OnValueChanged",function(_,value) if not self.scrolling then self:Scroll(value) end end)
    self.appearance=CreateFrame("Frame",nil,body);self.appearance:SetAllPoints()
    self.profilePage=CreateFrame("Frame",nil,body);self.profilePage:SetAllPoints()
    local page=self.appearance
    self:Section(page,"Appearance",16,-8,288,250)
    self:Section(page,"Navigation",316,-8,288,168)
    self:Section(page,"Position",316,-200,288,191)
    self:Label(page,"Font",28,-33)
    self.font=self:Dropdown(page,28,-53,260,"Expressway",function()
        local names={Expressway=true,["Game font"]=true,Arial=true};local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
        if lsm then for _,name in ipairs(lsm:List("font")) do names[name]=true end end
        local values={};for name in pairs(names) do values[#values+1]={label=name,value=name} end;table.sort(values,function(a,b) return a.label<b.label end);return values
    end,function(value) c.profile.font=value;c:ApplyProfile() end)
    self:Label(page,"Font size",28,-101)
    self.fontSize=self:Edit(page,230,-97,58)
    self.fontSize:SetScript("OnEnterPressed",function(e)
        c.profile.fontSize=math.floor(math.max(10,math.min(18,tonumber(e:GetText()) or c.profile.fontSize)));e:ClearFocus();c:ApplyProfile()
    end)
    self:Label(page,"Island scale",28,-145)
    self.scale=CreateFrame("Slider",nil,page,"UISliderTemplate");self.scale:SetPoint("TOPLEFT",28,-170);self.scale:SetSize(180,16)
    self.scale:SetOrientation("HORIZONTAL");self.scale:SetMinMaxValues(50,160);self.scale:SetValueStep(1);self.scale:SetObeyStepOnDrag(true)
    self.scaleEdit=self:Edit(page,230,-165,58)
    self.scale:SetScript("OnValueChanged",function(_,value)
        if self.refreshing then return end
        c.profile.scale=math.max(50,math.min(160,math.floor(value+.5)))/100;c:ApplyProfile()
    end)
    self.scaleEdit:SetScript("OnEnterPressed",function(e)
        c.profile.scale=math.max(50,math.min(160,math.floor((tonumber(e:GetText()) or c.profile.scale*100)+.5)))/100;e:ClearFocus();c:ApplyProfile()
    end)
    self:Label(page,"50–160%",28,-192,260,11,{.65,.65,.68})
    self.colors={}
    for i,entry in ipairs({{"Background","background"},{"Text","text"}}) do
        local key=entry[2];local x=28+(i-1)*136
        local b=self:Button(page,entry[1],x,-234,124,function() self:Color(key) end)
        self.bounded[#self.bounded]=nil;self:Bound(b.text,90,20,"LEFT",b,"LEFT",27,0)
        b.swatch=b:CreateTexture(nil,"OVERLAY");b.swatch:SetPoint("LEFT",b,"LEFT",7,0);b.swatch:SetSize(12,12);self.colors[key]=b
    end
    self:Label(page,"Route order",328,-33)
    self.order=self:Dropdown(page,328,-53,260,"Distance",function() return {{label="Distance",value="distance"},{label="Estimated time",value="time"}} end,function(value)
        c:SetRouteOrder(value)
    end)
    self.overlays=self:Check(page,"World / zone map markers","mapMarkers",328,-94)
    self.mapMarkers=self.overlays
    self.minimapMarkers=self:Check(page,"Minimap markers","minimapMarkers",328,-122)
    self.locked=self:Check(page,"Lock position","locked",328,-150)
    self.placement=self:Dropdown(page,328,-224,260,"Free (dragged)",function() return {
        {label="Free (dragged)",value="none"},{label="Left screen edge",value="left"},{label="Right screen edge",value="right"}
    } end,function(value) U:SetDock(c,value,true);c:ApplyProfile() end)
    local layerLabel=self:Label(page,"Frame layer",328,-265,92)
    self:Bound(layerLabel,92,24,"LEFT",page,"TOPLEFT",328,-274)
    self.strata=self:Dropdown(page,432,-262,156,"High",function() return {
        {label="Low",value="LOW"},{label="Medium",value="MEDIUM"},{label="High",value="HIGH"}
    } end,function(value) c.profile.strata=value;c:ApplyProfile() end)
    local hint=self:Label(page,"Drag to either edge to dock and hide. Click the edge tab to reopen.",328,-300,260,11,{.7,.7,.72});hint:SetWordWrap(true);hint:SetHeight(36)
    self.resetPlacement=self:Button(page,"Reset placement",328,-342,124,function() c.profile.x=24;c.profile.y=-180;c.profile.dockPosition=.5;U:SetDock(c,"none",false);c:ApplyProfile() end)
    self.togglePanel=self:Button(page,"Expand / tuck",464,-342,124,function() U:Toggle(c) end)
    self.showPanel=self:Button(page,"Show panel",328,-370,124,function() c:ShowPanel(true) end)
    self.hidePanel=self:Button(page,"Hide panel",464,-370,124,function() c:ShowPanel(false) end)
    local fontHint=self:Label(page,"Font size changes the island text. Scale changes the whole island.",28,-286,260,11,{.7,.7,.72});fontHint:SetWordWrap(true);fontHint:SetHeight(36)
    local profiles=self.profilePage;self:Section(profiles,"Profiles",16,-8,588,340)
    self:Label(profiles,"Active profile",28,-36)
    self.active=self:Dropdown(profiles,28,-58,260,"Default",function() return self:ProfileEntries() end,function(name) self:ProfileAction("SwitchProfile",name) end)
    self:Label(profiles,"New profile name",28,-109)
    self.name=self:Edit(profiles,28,-131,260)
    self.duplicate=self:Button(profiles,"Duplicate and use",328,-131,260,function() if self:ProfileAction("DuplicateProfile",self.name:GetText()) then self.name:SetText("");self.name:ClearFocus() end end)
    self.name:SetScript("OnEnterPressed",function() self.duplicate:GetScript("OnClick")() end)
    self:Label(profiles,"Copy settings from",28,-182)
    self.copySource=self:Dropdown(profiles,28,-204,260,"Choose profile",function() return self:ProfileEntries() end,function(value) self.copyName=value;self.confirm=nil;self:Refresh() end)
    self.copy=self:Button(profiles,"Copy settings",328,-204,260,function()
        if not self.copyName then self.status:SetText("Choose a profile.");return end
        if self.confirm~="copy" then self.confirm="copy";self:Refresh();return end
        self:ProfileAction("CopyProfile",self.copyName)
    end)
    self.reset=self:Button(profiles,"Reset active profile",28,-294,260,function()
        if self.confirm~="reset" then self.confirm="reset";self:Refresh();return end;self:ProfileAction("ResetProfile")
    end)
    self.cancel=self:Button(profiles,"Cancel",328,-294,260,function() self.confirm=nil;self:Refresh() end)
    self.status=self:Label(content,"",20,0,580,11,{.8,.8,.8});self.status:ClearAllPoints();self.status:SetPoint("BOTTOMLEFT",content,"BOTTOMLEFT",20,5)
    f:SetScript("OnHide",function() self:CloseColor();self.confirm=nil;self:CloseTransient() end)
    f:SetScript("OnShow",function()
        self:Refresh()
        -- Child templates can apply inherited fonts after the parent OnShow.
        if self.fontRepairQueued then return end;self.fontRepairQueued=true
        C_Timer.After(0,function() self.fontRepairQueued=false;if f:IsShown() then self:Refresh() end end)
    end)
    f:RegisterEvent("UI_SCALE_CHANGED");f:RegisterEvent("DISPLAY_SIZE_CHANGED");f:SetScript("OnEvent",function() self:Layout() end)
    UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"AsTheCrowFliesOptions");self:Page(false);f:Hide()
end

function O:ProfileEntries()
    local values={};for name in pairs(self.owner.profiles.profiles) do values[#values+1]={label=name,value=name} end
    table.sort(values,function(a,b) return a.label<b.label end);return values
end
function O:ProfileAction(action,name)
    self:CloseColor();local c=self.owner
    if c.readOnly then self.status:SetText("Settings are read-only.");return false end
    local profile,err=N.Settings[action](c.profiles,name)
    if not profile then self.status:SetText(err or "Profile unavailable.");return false end
    self.confirm=nil;c.profile=profile;c:BindFilters(true);self.status:SetText("");c:ApplyProfile();return true
end
function O:CloseColor()
    local edit=self.colorEdit
    self.colorEdit=nil
    if edit and ColorPickerFrame and ColorPickerFrame.GetExtraInfo and ColorPickerFrame:GetExtraInfo()==edit and ColorPickerFrame:IsShown() then
        edit.profile.colors[edit.key]=edit.original;ColorPickerFrame:Hide();N.UI:ApplyAppearance();self:Refresh()
    end
end
function O:Color(key)
    if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow or not ColorPickerFrame.GetExtraInfo then self.status:SetText("Color picker unavailable.");return end
    self:CloseColor();local c=self.owner;local profile=c.profile;local original=N.Model.Copy(profile.colors[key]);local edit={profile=profile,key=key,original=original,opening=true};self.colorEdit=edit
    local picker=ColorPickerFrame
    if self.colorHook~=picker then
        -- Classic hides before invoking its Okay/Cancel callbacks. Defer cleanup
        -- until those callbacks have run, and do not clear a newer editor session.
        picker:HookScript("OnHide",function()
            local hidden=self.colorEdit
            C_Timer.After(0,function() if self.colorEdit==hidden and not picker:IsShown() then self.colorEdit=nil end end)
        end);self.colorHook=picker
    end
    local function owns() return self.colorEdit==edit and picker:GetExtraInfo()==edit end
    picker:SetupColorPickerAndShow({r=original[1],g=original[2],b=original[3],hasOpacity=false,extraInfo=edit,
        swatchFunc=function()
            if c.profile~=profile or not owns() then return end
            local r,g,b=picker:GetColorRGB();profile.colors[key]={r,g,b};c:ApplyProfile()
            if not edit.opening and not picker:IsShown() then self.colorEdit=nil end
        end,
        cancelFunc=function() if not owns() then return end;profile.colors[key]=original;self.colorEdit=nil;if c.profile==profile then c:ApplyProfile() end end})
    edit.opening=false
end
function O:RefreshPlacement()
    local d=self.placement;if not d then return end
    local dock=self.owner.profile.dock
    d.value=dock;d:SetDefaultText(dock=="right" and "Right screen edge" or dock=="left" and "Left screen edge" or "Free (dragged)")
    -- Generated selection text can override the fallback caption. Update only
    -- this control when a completed panel gesture changes its saved placement.
    if d.atcfSelectionValue~=dock then d:GenerateMenu();d.atcfSelectionValue=dock end
end
function O:Refresh(fontsReady)
    if not self.frame then return end
    if not fontsReady then self.owner:RefreshAppearance(false);return end
    local c=self.owner;local p=c.profile;self.refreshing=true;self.font.value=p.font;self.font:SetDefaultText(p.font)
    self.fontSize:SetText(tostring(p.fontSize));self.scale:SetValue(p.scale*100);self.scaleEdit:SetText(tostring(math.floor(p.scale*100+.5)))
    self:RefreshPlacement()
    self.strata.value=p.strata;self.strata:SetDefaultText(p.strata=="LOW" and "Low" or p.strata=="MEDIUM" and "Medium" or "High")
    self.optionsTab.activeLine:SetShown(not self.profilesSelected);self.profilesTab.activeLine:SetShown(self.profilesSelected==true)
    self.optionsTab.text:SetTextColor(.93,.94,.97);self.profilesTab.text:SetTextColor(.93,.94,.97)
    self.order.value=p.routeOrder;self.order:SetDefaultText(p.routeOrder=="time" and "Estimated time" or "Distance")
    self.overlays:SetChecked(p.mapMarkers);self.minimapMarkers:SetChecked(p.minimapMarkers);self.locked:SetChecked(p.locked);self.active.value=c.profiles.active;self.active:SetDefaultText(c.profiles.active)
    self.copy.text:SetText(self.confirm=="copy" and "Confirm copy" or "Copy settings");self.reset.text:SetText(self.confirm=="reset" and "Confirm reset" or "Reset active profile");self.cancel:SetShown(self.confirm~=nil)
    for key,button in pairs(self.colors) do button.swatch:SetColorTexture(unpack(p.colors[key])) end
    N.UI:SyncMenus()
    self:Layout();self.refreshing=false
end
function O:Page(profiles)
    self:CloseTransient();self:Scroll(0)
    self.confirm=nil;self.profilesSelected=profiles==true;self.appearance:SetShown(not profiles);self.profilePage:SetShown(profiles);self:Refresh()
end
function O:Open()
    if N.UI.menu then N.UI.menu:Hide() end
    self:Layout();self:Refresh();self.frame:Show()
end
function O:Layout()
    local scale=math.min(1,math.max(.1,(UIParent:GetWidth()-24)/dialogWidth))
    local height=math.max(120,math.min(dialogHeight,(UIParent:GetHeight()-24)/scale))
    local key=scale..":"..height..":"..UIParent:GetEffectiveScale()
    if self.layoutKey and self.layoutKey~=key then self:CloseTransient() end
    self.layoutKey=key;self.frame:SetScale(scale);self.frame:SetHeight(height)
    local viewport=height-96
    self.scroll:SetSize(bodyWidth,viewport);self.body:SetSize(bodyWidth,bodyHeight)
    self.bar:SetHeight(math.max(22,viewport-8));self.maximum=math.max(0,bodyHeight-viewport)
    self.scrolling=true;self.bar:SetMinMaxValues(0,self.maximum);self.bar:SetShown(self.maximum>0);self.scrolling=nil
    self:Scroll(self.offset or 0)
    for _,entry in ipairs(self.bounded) do
        local t=entry.text;t:SetScale(1);t:SetHeight(0)
        local effective=t:GetEffectiveScale()
        local natural=(math.ceil(t:GetUnboundedStringWidth()*effective)+4)/effective;local height=(math.ceil(t:GetStringHeight()*effective)+2)/effective
        local scale=entry.dropdown and 1 or math.min(1,entry.width/math.max(1,natural),entry.height/math.max(1,height))
        t:SetScale(scale);t:SetSize(entry.width/scale,entry.height/scale);t:ClearAllPoints()
        t:SetPoint(entry.point,entry.parent,entry.relative,entry.x/scale,entry.y/scale)
        if entry.dropdown then self:Caption(entry.dropdown,entry.dropdown.fullCaption) end
    end
end
function O:Toggle() if self.frame:IsShown() then self.frame:Hide() else self:Open() end end
