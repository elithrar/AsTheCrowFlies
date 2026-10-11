local _,N=...;local O={};N.Options=O
function O:Create(c)
    self.owner=c;local U=N.UI
    local f=CreateFrame("Frame","AsTheCrowFliesOptions",UIParent,"BackdropTemplate");self.frame=f
    f:SetSize(620,462);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=8,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    f:SetBackdropColor(.045,.045,.05,.97);f:SetBackdropBorderColor(.55,.56,.60,1)
    local drag=CreateFrame("Frame",nil,f);drag:SetPoint("TOPLEFT");drag:SetSize(580,38);drag:EnableMouse(true);drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart",function() f:StartMoving() end);drag:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
    U:Text(drag,"As The Crow Flies",16,20,-12,300,26)
    self.close=U:Button(f,"x",580,-12,24,24,function() f:Hide();self:CloseColor() end);self.close:SetFrameLevel(drag:GetFrameLevel()+2)
    self.optionsTab=U:Button(f,"Options",20,-44,86,26,function() self:Page(false) end)
    self.profilesTab=U:Button(f,"Profiles",112,-44,86,26,function() self:Page(true) end)
    for _,tab in ipairs({self.optionsTab,self.profilesTab}) do
        tab.activeLine=tab:CreateTexture(nil,"OVERLAY");tab.activeLine:SetHeight(2)
        tab.activeLine:SetPoint("BOTTOMLEFT",tab,"BOTTOMLEFT",8,0);tab.activeLine:SetPoint("BOTTOMRIGHT",tab,"BOTTOMRIGHT",-8,0)
    end
    self.appearance=CreateFrame("Frame",nil,f);self.appearance:SetAllPoints()
    self.profilePage=CreateFrame("Frame",nil,f);self.profilePage:SetAllPoints()
    local function section(parent,label,x,y,w,h)
        local p=CreateFrame("Frame",nil,parent);p:SetPoint("TOPLEFT",x,y);p:SetSize(w,h);U:Surface(p,{.075,.077,.085,1});U:Text(p,label,12,12,-8,w-24,24);return p
    end
    local appearance=section(self.appearance,"Appearance",16,-84,288,330)
    local behavior=section(self.appearance,"Navigation",316,-84,288,186)
    local position=section(self.appearance,"Position",316,-284,288,130)
    U:Text(appearance,"Font",12,12,-40,250,22)
    self.font=U:Menu(appearance,12,-66,264,"Expressway",function()
        local names={Expressway=true,["Game font"]=true,Arial=true};local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
        if lsm then for _,name in ipairs(lsm:List("font")) do names[name]=true end end
        local values={};for name in pairs(names) do values[#values+1]={label=name,value=name} end;table.sort(values,function(a,b) return a.label<b.label end);return values
    end,function(value) c.profile.font=value;c:ApplyProfile() end)
    U:Text(appearance,"Scale",12,12,-108,130,26)
    self.scaleText=U:Text(appearance,"",12,132,-108,70,26)
    self.scaleDown=U:Button(appearance,"-",12,-142,54,26,function() c.profile.scale=math.max(.65,c.profile.scale-.05);c:ApplyProfile() end)
    self.scaleUp=U:Button(appearance,"+",72,-142,54,26,function() c.profile.scale=math.min(1.6,c.profile.scale+.05);c:ApplyProfile() end)
    self.colors={}
    for i,entry in ipairs({{"Background","background"},{"Accent","accent"},{"Text","text"}}) do
        local key=entry[2];local b=U:Button(appearance,entry[1],12,-184-(i-1)*40,264,28,function() self:Color(key) end)
        b.swatch=b:CreateTexture(nil,"OVERLAY");b.swatch:SetPoint("LEFT",b,"LEFT",10,0);b.swatch:SetSize(12,12);self.colors[key]=b
    end
    U:Text(behavior,"Route order",12,12,-40,260,22)
    self.order=U:Menu(behavior,12,-66,264,"Distance",function() return {{label="Distance",value="distance"},{label="Estimated time",value="time"}} end,function(value)
        c.profile.routeOrder=value;if #c.results>0 then c:Plan() end;c:ApplyProfile()
    end)
    local function check(parent,label,key,y)
        local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate");b:SetPoint("TOPLEFT",8,y);b:SetSize(28,28);U:Text(parent,label,12,42,y,230,28)
        b:SetScript("OnClick",function() c.profile[key]=b:GetChecked();c:ApplyProfile() end);return b
    end
    self.overlays=check(behavior,"Map markers","overlays",-108)
    self.locked=check(behavior,"Lock panel","locked",-142)
    self.resetPlacement=U:Button(position,"Reset placement",12,-40,264,28,function() c.profile.x=24;c.profile.y=-180;c.profile.dock="none";c.tucked=false;c:ApplyProfile() end)
    self.showPanel=U:Button(position,"Show panel",12,-80,126,28,function() c:ShowPanel(true) end)
    self.hidePanel=U:Button(position,"Hide panel",150,-80,126,28,function() c:ShowPanel(false) end)
    local profiles=section(self.profilePage,"Profiles",16,-84,588,330)
    U:Text(profiles,"Active profile",12,12,-40,264,22)
    self.active=U:Menu(profiles,12,-66,264,"Default",function() return self:ProfileEntries() end,function(name) self:ProfileAction("SwitchProfile",name) end)
    U:Text(profiles,"New profile name",12,12,-112,264,22)
    local name=CreateFrame("EditBox",nil,profiles);self.name=name;name:SetPoint("TOPLEFT",12,-138);name:SetSize(264,28);name:SetAutoFocus(false);name:SetMaxLetters(48);name:SetTextInsets(8,8,0,0);U:Surface(name,{.12,.13,.15,1});U:Font(name,12)
    name:SetScript("OnEscapePressed",function() name:ClearFocus() end)
    self.duplicate=U:Button(profiles,"Duplicate and use",300,-138,264,28,function() if self:ProfileAction("DuplicateProfile",name:GetText()) then name:SetText("");name:ClearFocus() end end)
    name:SetScript("OnEnterPressed",function() self.duplicate:GetScript("OnClick")() end)
    U:Text(profiles,"Copy settings from",12,12,-188,264,22)
    self.copySource=U:Menu(profiles,12,-214,264,"Choose profile",function() return self:ProfileEntries() end,function(value) self.copyName=value;self.confirm=nil;self:Refresh() end)
    self.copy=U:Button(profiles,"Copy settings",300,-214,264,28,function()
        if not self.copyName then self.status:SetText("Choose a profile.");return end
        if self.confirm~="copy" then self.confirm="copy";self:Refresh();return end
        self:ProfileAction("CopyProfile",self.copyName)
    end)
    self.reset=U:Button(profiles,"Reset active profile",12,-272,264,28,function()
        if self.confirm~="reset" then self.confirm="reset";self:Refresh();return end
        self:ProfileAction("ResetProfile")
    end)
    self.cancel=U:Button(profiles,"Cancel",300,-272,264,28,function() self.confirm=nil;self:Refresh() end)
    self.status=U:Text(f,"",11,20,-428,580,22)
    f:SetScript("OnHide",function() self:CloseColor();self.confirm=nil;self.name:ClearFocus();for _,d in ipairs(U.dropdowns or {}) do d:CloseMenu() end end)
    f:RegisterEvent("UI_SCALE_CHANGED");f:RegisterEvent("DISPLAY_SIZE_CHANGED")
    f:SetScript("OnEvent",function() self:Layout() end)
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
function O:Refresh()
    if not self.frame then return end
    local c=self.owner;local p=c.profile;self.font.value=p.font;self.font:SetDefaultText(p.font);self.scaleText:SetText(string.format("%.0f%%",p.scale*100))
    for _,tab in ipairs({self.optionsTab,self.profilesTab}) do tab.activeLine:SetColorTexture(unpack(p.colors.accent)) end
    self.optionsTab.activeLine:SetShown(not self.profilesSelected);self.profilesTab.activeLine:SetShown(self.profilesSelected==true)
    self.order.value=p.routeOrder;self.order:SetDefaultText(p.routeOrder=="time" and "Estimated time" or "Distance")
    self.overlays:SetChecked(p.overlays);self.locked:SetChecked(p.locked);self.active.value=c.profiles.active;self.active:SetDefaultText(c.profiles.active)
    self.copy.text:SetText(self.confirm=="copy" and "Confirm copy" or "Copy settings");self.reset.text:SetText(self.confirm=="reset" and "Confirm reset" or "Reset active profile");self.cancel:SetShown(self.confirm~=nil)
    for key,button in pairs(self.colors) do button.swatch:SetColorTexture(unpack(p.colors[key])) end
end
function O:Page(profiles)
    self.confirm=nil;self.profilesSelected=profiles==true;self.appearance:SetShown(not profiles);self.profilePage:SetShown(profiles);self:Refresh()
end
function O:Open()
    if N.UI.menu then N.UI.menu:Hide() end
    self:Layout();self:Refresh();self.frame:Show()
end
function O:Layout() self.frame:SetScale(math.min(1,UIParent:GetHeight()/486,UIParent:GetWidth()/644)) end
function O:Toggle() if self.frame:IsShown() then self.frame:Hide() else self:Open() end end
