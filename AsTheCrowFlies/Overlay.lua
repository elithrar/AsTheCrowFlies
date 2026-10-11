local _,N=...;local M,A=N.Model,N.Adapter;local O={};N.Overlay=O
function O:MarkerIcon(texture,arrow)
    if arrow then N.UI:NavigationArrow(texture)
    else
        texture:SetTexture("Interface\\AddOns\\AsTheCrowFlies\\Media\\eagle.tga");texture:SetTexCoord(0,1,0,1)
        texture:SetDesaturated(false);texture:SetRotation(0);texture:SetVertexColor(.88,.66,.16);texture.atcfArrowAsset=nil
    end
end
function O:Create()
    if Minimap then
        self.mini=CreateFrame("Frame",nil,Minimap);self.mini:SetSize(18,18);self.mini:SetFrameLevel(Minimap:GetFrameLevel()+8);self.mini:EnableMouse(true)
        self.icon=self.mini:CreateTexture(nil,"OVERLAY");self.icon:SetAllPoints();self:MarkerIcon(self.icon,true);self.miniMode="arrow";self.mini:Hide()
        self.mini:SetScript("OnEnter",function() GameTooltip:SetOwner(self.mini,"ANCHOR_RIGHT");GameTooltip:SetText(self.mini.caption or "Destination");GameTooltip:Show() end)
        self.mini:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
end
function O:Clear()
    if self.mini then self.mini:Hide() end;if self.map then self.map:Hide() end;if self.destination then self.destination:Hide() end
    if self.paths then self.paths:Hide() end
end
function O:FlightPaths(route,canvas,mapID)
    if not canvas.CreateLine then return end
    if not self.paths then
        self.paths=CreateFrame("Frame",nil,canvas);self.paths:SetAllPoints(canvas);self.lines={}
    end
    self.paths:Show()
    local key=tostring(route)..":"..mapID..":"..canvas:GetWidth()..":"..canvas:GetHeight()
    if self.pathKey==key then return end
    self.pathKey=key
    for _,line in ipairs(self.lines) do line:Hide() end
    local used=0
    for _,leg in ipairs(route.legs) do if leg.mode=="flight" then
        local geometry=leg.geometry or {{map=leg.start.map,points=leg.points or {}}}
        for _,path in ipairs(geometry) do
            local previous
            for _,point in ipairs(path.points) do
                local x,y=A.Project({map=path.map,x=point[1],y=point[2]},mapID,true)
                if x and previous then
                    local x1,y1,x2,y2=M.ClipSegment(previous[1],previous[2],x,y)
                    if x1 and (x1~=x2 or y1~=y2) and used<2048 then
                        used=used+1
                        local line=self.lines[used]
                        if not line then line=self.paths:CreateLine(nil,"ARTWORK");line:SetThickness(2);self.lines[used]=line end
                        line:SetColorTexture(.43,.68,.90,.8)
                        line:SetStartPoint("TOPLEFT",self.paths,x1*canvas:GetWidth(),-y1*canvas:GetHeight())
                        line:SetEndPoint("TOPLEFT",self.paths,x2*canvas:GetWidth(),-y2*canvas:GetHeight());line:Show()
                    end
                end
                previous=x and {x,y} or nil
            end
        end
    end end
    self.visibleSegments=used
end
function O:MapPin(field,canvas,arrow)
    if not self[field] then
        local f=CreateFrame("Frame",nil,canvas);f:SetSize(18,18);f:SetFrameLevel(canvas:GetFrameLevel()+20);f:EnableMouse(true)
        f.icon=f:CreateTexture(nil,"OVERLAY");f.icon:SetAllPoints();self[field]=f
        f:SetScript("OnEnter",function() GameTooltip:SetOwner(f,"ANCHOR_RIGHT");GameTooltip:SetText(f.caption or "Destination");GameTooltip:Show() end);f:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
    local pin=self[field]
    if pin.arrow~=arrow then self:MarkerIcon(pin.icon,arrow);pin.arrow=arrow end
    pin:SetFrameLevel(canvas:GetFrameLevel()+20)
    return pin
end
function O:Update(c,p,ctx)
    ctx=ctx or {};local visible={}
    local active=c.nav.route
    local selected=c.results and c.results[c.selected or 1]
    local destination=selected and selected.destination or c.destination or active and active.destination
    local target=active and N.Navigation.Target(c.nav) or destination
    local direction=M.Position(p) and not c.manualPause and not ctx.dead and (not active or (c.nav.state~="arrived" and c.nav.state~="paused" and c.nav.state~="unavailable"))
    -- A selected destination is useful before Go. An active route always owns
    -- the minimap bearing, even while another destination is being inspected.
    if c.profile.minimapMarkers and direction and target and p and self.mini then
        local rotate=A.Call(C_CVar and C_CVar.GetCVarBool or GetCVarBool,"rotateMinimap");local ignored=A.Call(C_Minimap and C_Minimap.IsRotateMinimapIgnored)
        local facing=rotate and not ignored and ctx.facing or nil
        -- Do not draw a false north-up direction on a rotating map without facing.
        if not rotate or ignored or facing then
            local east,north=M.Vector(p,target,facing);local radius=A.Call(C_Minimap and C_Minimap.GetViewRadius)
            local shape=A.Call(GetMinimapShape) or "ROUND"
            if east then
                local x,y=M.Minimap(east,north,radius,Minimap:GetWidth(),Minimap:GetHeight(),shape)
                if x then
                    local mode=active and "arrow" or "eagle"
                    if self.miniMode~=mode then self:MarkerIcon(self.icon,active~=nil);self.miniMode=mode end
                    self.mini:ClearAllPoints();self.mini:SetPoint("CENTER",Minimap,"CENTER",x,y);self.icon:SetRotation(active and -math.atan2(east,north) or 0)
                    self.mini.caption=(active and "Next: " or "Destination: ")..(target.name or "Flight point");self.mini:Show();visible.mini=true
                end
            end
        end
    end
    local map=WorldMapFrame
    -- World/zone pins describe known coordinates, so they remain meaningful
    -- while location is unavailable, navigation is paused, or the player dies.
    if c.profile.mapMarkers and destination and map and map:IsShown() and map.GetCanvas and map.GetMapID then
        local canvas=map:GetCanvas();local id=map:GetMapID()
        if canvas then
            local zoom=A.Call(map.GetCanvasScale,map)
            if not A.Number(zoom) or zoom<=0 then zoom=A.Call(canvas.GetScale,canvas) end
            if not A.Number(zoom) or zoom<=0 then zoom=1 end
            local route=selected or (active and destination==active.destination and active)
            if route and canvas.CreateLine then self:FlightPaths(route,canvas,id);visible.paths=true end
            local entries={{field="destination",point=destination}}
            if active and direction and target and M.Distance(target,destination)~=0 then entries[#entries+1]={field="map",point=target} end
            for _,entry in ipairs(entries) do
                local x,y=A.Project(entry.point,id)
                if x then
                    local arrow=active~=nil and (entry.field=="map" or entry.point==active.destination)
                    local pin=self:MapPin(entry.field,canvas,arrow)
                    -- Native map pins compensate for canvas zoom. Keep our
                    -- marker readable without changing its normalized point.
                    pin:SetScale(1/zoom);pin:ClearAllPoints();pin:SetPoint("CENTER",canvas,"TOPLEFT",x*canvas:GetWidth()*zoom,-y*canvas:GetHeight()*zoom)
                    pin.caption=(entry.field=="map" and "Next: " or "Destination: ")..(entry.point.name or "Flight point");pin:Show();visible[entry.field]=true
                end
            end
        end
    end
    -- Retain visible pins so the quarter-second refresh cannot interrupt
    -- native mouse focus/tooltips. Clear only objects no longer needed.
    for _,field in ipairs({"mini","map","destination","paths"}) do if self[field] and not visible[field] then self[field]:Hide() end end
end
