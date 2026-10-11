local _,N=...;local M,A=N.Model,N.Adapter;local O={};N.Overlay=O
function O:Create()
    if Minimap then
        self.mini=CreateFrame("Frame",nil,Minimap);self.mini:SetSize(18,18);self.mini:SetFrameLevel(Minimap:GetFrameLevel()+8)
        self.icon=self.mini:CreateTexture(nil,"OVERLAY");self.icon:SetAllPoints();self.icon:SetTexture("Interface\\AddOns\\AsTheCrowFlies\\Media\\arrow.tga");self.icon:SetVertexColor(.78,.85,.61);self.mini:Hide()
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
function O:MapPin(field,canvas)
    if not self[field] then
        local f=CreateFrame("Frame",nil,canvas);f:SetSize(18,18);f:SetFrameLevel(canvas:GetFrameLevel()+20);f:EnableMouse(true)
        local t=f:CreateTexture(nil,"OVERLAY");t:SetAllPoints();t:SetTexture("Interface\\AddOns\\AsTheCrowFlies\\Media\\"..(field=="map" and "arrow.tga" or "eagle.tga"))
        if field=="map" then t:SetVertexColor(.78,.85,.61) else t:SetVertexColor(.88,.66,.16) end;self[field]=f
        f:SetScript("OnEnter",function() GameTooltip:SetOwner(f,"ANCHOR_RIGHT");GameTooltip:SetText(f.caption or "Destination");GameTooltip:Show() end);f:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
    return self[field]
end
function O:Update(c,p,ctx)
    self:Clear();local target=N.Navigation.Target(c.nav)
    if not c.profile.overlays or c.manualPause or not target or not p or c.nav.state=="arrived" or c.nav.state=="paused" or c.nav.state=="unavailable" then return end
    if self.mini then
        local rotate=A.Call(C_CVar and C_CVar.GetCVarBool or GetCVarBool,"rotateMinimap");local ignored=A.Call(C_Minimap and C_Minimap.IsRotateMinimapIgnored)
        local facing=rotate and not ignored and ctx.facing or nil
        -- Do not draw a false north-up direction on a rotating map without facing.
        if not rotate or ignored or facing then
            local east,north=M.Vector(p,target,facing);local radius=A.Call(C_Minimap and C_Minimap.GetViewRadius)
            local shape=A.Call(GetMinimapShape) or "ROUND"
            if east then
                local x,y=M.Minimap(east,north,radius,Minimap:GetWidth(),Minimap:GetHeight(),shape)
                if x then self.mini:ClearAllPoints();self.mini:SetPoint("CENTER",Minimap,"CENTER",x,y);self.icon:SetRotation(-math.atan2(east,north));self.mini:Show() end
            end
        end
    end
    local map=WorldMapFrame
    if map and map:IsShown() and map.GetCanvas and map.GetMapID then
        local canvas=map:GetCanvas();local id=map:GetMapID()
        self:FlightPaths(c.nav.route,canvas,id)
        for _,entry in ipairs({{field="map",point=target},{field="destination",point=c.nav.route.destination}}) do
            local x,y=A.Project(entry.point,id)
            if x then local pin=self:MapPin(entry.field,canvas);pin:ClearAllPoints();pin:SetPoint("CENTER",canvas,"TOPLEFT",x*canvas:GetWidth(),-y*canvas:GetHeight());pin.caption=(entry.field=="map" and "Next: " or "Destination: ")..(entry.point.name or "Flight point");pin:Show() end
        end
    end
end
