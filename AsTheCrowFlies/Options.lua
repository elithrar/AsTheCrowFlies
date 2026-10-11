local _,N=...;local O={};N.Options=O
function O:Create(c)
    local U=N.UI;local f=CreateFrame("Frame","AsTheCrowFliesOptions",UIParent);self.frame=f;f:SetSize(344,352);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:EnableMouse(true);f:SetClampedToScreen(true);U:Surface(f)
    U:Text(f,"Navigation settings",16,18,-14,270,28)
    U:Button(f,"x",306,-14,24,24,function() f:Hide() end)
    U:Text(f,"Font",12,18,-55,90,28)
    local fontMenu=U:Menu(f,112,-55,212,c.profile.font,function()
        local values={{label="Expressway",value="Expressway"},{label="Game font",value="Game font"},{label="Arial",value="Arial"}}
        local lsm=LibStub and LibStub("LibSharedMedia-3.0",true)
        if lsm then for _,font in ipairs(lsm:List("font")) do if font~="Expressway" then values[#values+1]={label=font,value=font} end end end
        return values
    end,function(font)
        c.profile.font=font;local list=U.texts;U.texts={};for _,v in ipairs(list) do U:Font(v[1],v[2]) end;c:Refresh()
    end)
    fontMenu.value=c.profile.font
    U:Text(f,"Scale",12,18,-95,90,28)
    self.scaleText=U:Text(f,string.format("%.0f%%",c.profile.scale*100),12,177,-95,62,28)
    local function scale(delta) c.profile.scale=math.max(.65,math.min(1.6,c.profile.scale+delta));self.scaleText:SetText(string.format("%.0f%%",c.profile.scale*100));c:Refresh() end
    U:Button(f,"-",112,-95,44,28,function() scale(-.05) end);U:Button(f,"+",270,-95,44,28,function() scale(.05) end)
    local function check(label,key,y)
        local b=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");b:SetPoint("TOPLEFT",14,y);b:SetSize(28,28);b:SetChecked(c.profile[key]);U:Text(f,label,12,48,y,260,28)
        b:SetScript("OnClick",function() c.profile[key]=b:GetChecked();c:Refresh() end)
    end
    check("Lock panel position","locked",-138);check("Minimap and world-map markers","overlays",-172)
    U:Button(f,"Reset placement",18,-218,145,28,function() c.profile.x=24;c.profile.y=-180;c.profile.dock="none";c.profile.scale=1;self.scaleText:SetText("100%");c.tucked=false;c:Refresh() end)
    U:Button(f,"Save this location",179,-218,145,28,function() SlashCmdList.ASTHECROWFLIES("remember") end)
    local note=U:Text(f,"Expressway uses SharedMedia when installed. Ground directions are compass bearings; ETA excludes stops and detours.",11,18,-261,306,65);note:SetWordWrap(true);note:SetTextColor(.68,.71,.76)
    f:Hide()
end
