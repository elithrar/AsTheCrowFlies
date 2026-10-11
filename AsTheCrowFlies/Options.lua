local _,N=...;local O={};N.Options=O
-- Match the installed XPIsland dialog's native controls, sizing and chrome.
local backdrop={bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=10,insets={left=2,right=2,top=2,bottom=2}}
local gold={1,.82,.2}
local dialogWidth,dialogHeight=620,500
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
    b:SetBackdrop(backdrop);b:SetBackdropColor(.06,.06,.065,.8);b:SetBackdropBorderColor(.45,.45,.45,.65)
    b.text=self:Label(b,text,0,0,width-12);self:Bound(b.text,width-12,20,"CENTER",b,"CENTER",0,0)
    b:SetScript("OnEnter",function() b:SetBackdropBorderColor(.9,.8,.5,.9) end)
    b:SetScript("OnLeave",function() b:SetBackdropBorderColor(.45,.45,.45,.65) end);b:SetScript("OnClick",callback);return b
end
function O:Section(parent,label,x,y,w,h)
    local box=CreateFrame("Frame",nil,parent,"BackdropTemplate");box:SetFrameLevel(parent:GetFrameLevel()-1)
    box:SetPoint("TOPLEFT",x,y-9);box:SetSize(w,h);box:SetBackdrop(backdrop);box:SetBackdropColor(.035,.035,.04,.35);box:SetBackdropBorderColor(.35,.35,.35,.5)
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
    self:Bound(d.Text,width-31,24,"LEFT",d,"LEFT",9,0);return d
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
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=8,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    f:SetBackdropColor(.045,.045,.05,.94);f:SetBackdropBorderColor(.65,.65,.65,1)
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
    self.appearance=CreateFrame("Frame",nil,content);self.appearance:SetAllPoints()
    self.profilePage=CreateFrame("Frame",nil,content);self.profilePage:SetAllPoints()
    local page=self.appearance
    self:Section(page,"Appearance",16,-80,288,278)
    self:Section(page,"Navigation",316,-80,288,168)
    self:Section(page,"Position",316,-272,288,191)
    self:Label(page,"Font",28,-105)
    self.font=self:Dropdown(page,28,-125,260,"Expressway",function()
        local names={Expressway=true,["Game font"]=true,Arial=true};local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
        if lsm then for _,name in ipairs(lsm:List("font")) do names[name]=true end end
        local values={};for name in pairs(names) do values[#values+1]={label=name,value=name} end;table.sort(values,function(a,b) return a.label<b.label end);return values
    end,function(value) c.profile.font=value;c:ApplyProfile() end)
    self:Label(page,"Font size",28,-173)
    self.fontSize=self:Edit(page,230,-169,58)
    self.fontSize:SetScript("OnEnterPressed",function(e)
        c.profile.fontSize=math.floor(math.max(10,math.min(18,tonumber(e:GetText()) or c.profile.fontSize)));e:ClearFocus();c:ApplyProfile()
    end)
    self:Label(page,"Island scale",28,-217)
    self.scale=CreateFrame("Slider",nil,page,"UISliderTemplate");self.scale:SetPoint("TOPLEFT",28,-242);self.scale:SetSize(180,16)
    self.scale:SetOrientation("HORIZONTAL");self.scale:SetMinMaxValues(50,160);self.scale:SetValueStep(1);self.scale:SetObeyStepOnDrag(true)
    self.scaleEdit=self:Edit(page,230,-237,58)
    self.scale:SetScript("OnValueChanged",function(_,value)
        if self.refreshing then return end
        c.profile.scale=math.max(50,math.min(160,math.floor(value+.5)))/100;c:ApplyProfile()
    end)
    self.scaleEdit:SetScript("OnEnterPressed",function(e)
        c.profile.scale=math.max(50,math.min(160,math.floor((tonumber(e:GetText()) or c.profile.scale*100)+.5)))/100;e:ClearFocus();c:ApplyProfile()
    end)
    self:Label(page,"50–160%",28,-264,260,11,{.65,.65,.68})
    self.colors={}
    for i,entry in ipairs({{"Background","background"},{"Accent","accent"},{"Text","text"}}) do
        local key=entry[2];local x=28+((i-1)%2)*136;local y=i<3 and -306 or -334
        local b=self:Button(page,entry[1],x,y,124,function() self:Color(key) end)
        self.bounded[#self.bounded]=nil;self:Bound(b.text,90,20,"LEFT",b,"LEFT",27,0)
        b.swatch=b:CreateTexture(nil,"OVERLAY");b.swatch:SetPoint("LEFT",b,"LEFT",7,0);b.swatch:SetSize(12,12);self.colors[key]=b
    end
    self:Label(page,"Route order",328,-105)
    self.order=self:Dropdown(page,328,-125,260,"Distance",function() return {{label="Distance",value="distance"},{label="Estimated time",value="time"}} end,function(value)
        c:SetRouteOrder(value)
    end)
    self.overlays=self:Check(page,"World / zone map markers","mapMarkers",328,-166)
    self.mapMarkers=self.overlays
    self.minimapMarkers=self:Check(page,"Minimap markers","minimapMarkers",328,-194)
    self.locked=self:Check(page,"Lock position","locked",328,-222)
    self.placement=self:Dropdown(page,328,-296,260,"Free (dragged)",function() return {
        {label="Free (dragged)",value="none"},{label="Left screen edge",value="left"},{label="Right screen edge",value="right"}
    } end,function(value) U:SetDock(c,value,true);c:ApplyProfile() end)
    local layerLabel=self:Label(page,"Frame layer",328,-337,92)
    self:Bound(layerLabel,92,24,"LEFT",page,"TOPLEFT",328,-346)
    self.strata=self:Dropdown(page,432,-334,156,"High",function() return {
        {label="Low",value="LOW"},{label="Medium",value="MEDIUM"},{label="High",value="HIGH"}
    } end,function(value) c.profile.strata=value;c:ApplyProfile() end)
    local hint=self:Label(page,"Drag to either edge to dock and hide. Click the edge tab to reopen.",328,-372,260,11,{.7,.7,.72});hint:SetWordWrap(true);hint:SetHeight(36)
    self.resetPlacement=self:Button(page,"Reset placement",328,-414,124,function() c.profile.x=24;c.profile.y=-180;c.profile.dockPosition=.5;U:SetDock(c,"none",false);c:ApplyProfile() end)
    self.togglePanel=self:Button(page,"Expand / tuck",464,-414,124,function() U:Toggle(c) end)
    self.showPanel=self:Button(page,"Show panel",328,-442,124,function() c:ShowPanel(true) end)
    self.hidePanel=self:Button(page,"Hide panel",464,-442,124,function() c:ShowPanel(false) end)
    local fontHint=self:Label(page,"Font size changes the island text. Scale changes the whole island.",28,-386,260,11,{.7,.7,.72});fontHint:SetWordWrap(true);fontHint:SetHeight(36)
    local profiles=self.profilePage;self:Section(profiles,"Profiles",16,-80,588,340)
    self:Label(profiles,"Active profile",28,-108)
    self.active=self:Dropdown(profiles,28,-130,260,"Default",function() return self:ProfileEntries() end,function(name) self:ProfileAction("SwitchProfile",name) end)
    self:Label(profiles,"New profile name",28,-181)
    self.name=self:Edit(profiles,28,-203,260)
    self.duplicate=self:Button(profiles,"Duplicate and use",328,-203,260,function() if self:ProfileAction("DuplicateProfile",self.name:GetText()) then self.name:SetText("");self.name:ClearFocus() end end)
    self.name:SetScript("OnEnterPressed",function() self.duplicate:GetScript("OnClick")() end)
    self:Label(profiles,"Copy settings from",28,-254)
    self.copySource=self:Dropdown(profiles,28,-276,260,"Choose profile",function() return self:ProfileEntries() end,function(value) self.copyName=value;self.confirm=nil;self:Refresh() end)
    self.copy=self:Button(profiles,"Copy settings",328,-276,260,function()
        if not self.copyName then self.status:SetText("Choose a profile.");return end
        if self.confirm~="copy" then self.confirm="copy";self:Refresh();return end
        self:ProfileAction("CopyProfile",self.copyName)
    end)
    self.reset=self:Button(profiles,"Reset active profile",28,-366,260,function()
        if self.confirm~="reset" then self.confirm="reset";self:Refresh();return end;self:ProfileAction("ResetProfile")
    end)
    self.cancel=self:Button(profiles,"Cancel",328,-366,260,function() self.confirm=nil;self:Refresh() end)
    self.status=self:Label(content,"",20,-480,580,11,{.8,.8,.8})
    f:SetScript("OnHide",function() self:CloseColor();self.confirm=nil;self.name:ClearFocus();self.fontSize:ClearFocus();self.scaleEdit:ClearFocus();for _,d in ipairs(U.dropdowns or {}) do d:CloseMenu() end end)
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
function O:Refresh(fontsReady)
    if not self.frame then return end
    if not fontsReady then self.owner:RefreshAppearance(false);return end
    local c=self.owner;local p=c.profile;self.refreshing=true;self.font.value=p.font;self.font:SetDefaultText(p.font)
    self.fontSize:SetText(tostring(p.fontSize));self.scale:SetValue(p.scale*100);self.scaleEdit:SetText(tostring(math.floor(p.scale*100+.5)))
    self.placement.value=p.dock;self.placement:SetDefaultText(p.dock=="right" and "Right screen edge" or p.dock=="left" and "Left screen edge" or "Free (dragged)")
    self.strata.value=p.strata;self.strata:SetDefaultText(p.strata=="LOW" and "Low" or p.strata=="MEDIUM" and "Medium" or "High")
    self.optionsTab.activeLine:SetShown(not self.profilesSelected);self.profilesTab.activeLine:SetShown(self.profilesSelected==true)
    self.optionsTab.text:SetTextColor(unpack(not self.profilesSelected and {.93,.94,.97} or gold));self.profilesTab.text:SetTextColor(unpack(self.profilesSelected and {.93,.94,.97} or gold))
    self.order.value=p.routeOrder;self.order:SetDefaultText(p.routeOrder=="time" and "Estimated time" or "Distance")
    self.overlays:SetChecked(p.mapMarkers);self.minimapMarkers:SetChecked(p.minimapMarkers);self.locked:SetChecked(p.locked);self.active.value=c.profiles.active;self.active:SetDefaultText(c.profiles.active)
    self.copy.text:SetText(self.confirm=="copy" and "Confirm copy" or "Copy settings");self.reset.text:SetText(self.confirm=="reset" and "Confirm reset" or "Reset active profile");self.cancel:SetShown(self.confirm~=nil)
    for key,button in pairs(self.colors) do button.swatch:SetColorTexture(unpack(p.colors[key])) end
    N.UI:SyncMenus()
    self:Layout();self.refreshing=false
end
function O:Page(profiles)
    self.confirm=nil;self.profilesSelected=profiles==true;self.appearance:SetShown(not profiles);self.profilePage:SetShown(profiles);self:Refresh()
end
function O:Open()
    if N.UI.menu then N.UI.menu:Hide() end
    self:Layout();self:Refresh();self.frame:Show()
end
function O:Layout()
    self.frame:SetScale(math.min(1,(UIParent:GetHeight()-24)/dialogHeight,(UIParent:GetWidth()-24)/dialogWidth))
    for _,entry in ipairs(self.bounded) do
        local t=entry.text;t:SetScale(1);t:SetHeight(0)
        local natural=t:GetUnboundedStringWidth()+4;local height=t:GetStringHeight()+2
        local scale=math.min(1,entry.width/math.max(1,natural),entry.height/math.max(1,height))
        t:SetScale(scale);t:SetSize(entry.width/scale,entry.height/scale);t:ClearAllPoints()
        t:SetPoint(entry.point,entry.parent,entry.relative,entry.x/scale,entry.y/scale)
    end
end
function O:Toggle() if self.frame:IsShown() then self.frame:Hide() else self:Open() end end
