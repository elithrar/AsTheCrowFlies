local _,N=...;local M=N.Model;local A={};N.Adapter=A
-- Check secrecy before comparisons, indexing, formatting or arithmetic.
function A.Ordinary(v) return not (issecretvalue and issecretvalue(v)) end
function A.Number(v) return A.Ordinary(v) and M.Number(v) end
function A.Call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a,b,c,d=pcall(fn,...);if ok then return a,b,c,d end
end
function A.XY(v)
    if not v or not A.Ordinary(v) then return nil end
    local x,y=A.Call(v.GetXY,v)
    if A.Number(x) and A.Number(y) then return x,y end
end
function A.FromMap(id,x,y)
    if not C_Map or not CreateVector2D or not A.Number(id) or not A.Number(x) or not A.Number(y) or x<0 or x>1 or y<0 or y>1 then return nil end
    local map,world=A.Call(C_Map.GetWorldPosFromMapPos,id,CreateVector2D(x,y))
    local wx,wy=A.XY(world)
    if not A.Number(map) or not wx or (map~=0 and map~=1) then return nil end
    return {map=map,x=wx,y=wy,uiMapID=id,mx=x,my=y}
end
function A.Position()
    local id=A.Call(C_Map and C_Map.GetBestMapForUnit,"player")
    if not A.Number(id) then return nil end
    local x,y=A.XY(A.Call(C_Map.GetPlayerMapPosition,id,"player"))
    if not x or (x==0 and y==0) then return nil end
    return A.FromMap(id,x,y)
end
function A.Project(p,id,allowOutside)
    if not M.Position(p) or not A.Number(id) or not C_Map or not CreateVector2D then return nil end
    local map,v=A.Call(C_Map.GetMapPosFromWorldPos,p.map,CreateVector2D(p.x,p.y),id)
    local x,y=A.XY(v);if map==id and x and (allowOutside or (x>=0 and x<=1 and y>=0 and y<=1)) then return x,y end
end
function A.Context(previous)
    local _,class=A.Call(UnitClass,"player");local faction=A.Call(UnitFactionGroup,"player")
    local taxi=A.Call(UnitOnTaxi,"player");taxi=A.Ordinary(taxi) and taxi==true
    local current,run=A.Call(GetUnitSpeed,"player")
    if not A.Number(current) then current=nil end;if not A.Number(run) then run=nil end
    local speed,source=M.Speed(current,run,previous,taxi)
    local facing=A.Call(GetPlayerFacing);if not A.Number(facing) then facing=nil end
    local dead=A.Call(UnitIsDeadOrGhost,"player");dead=A.Ordinary(dead) and dead==true
    return {class=A.Ordinary(class) and class or nil,faction=A.Ordinary(faction) and faction or nil,speed=speed,speedSource=source,onTaxi=taxi,facing=facing,dead=dead}
end
function A.Build()
    local version,build=A.Call(GetBuildInfo)
    return tostring(version).."."..tostring(build)
end
function A.ObserveMap(id,character,nodes)
    local list=A.Call(C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap,id)
    if type(list)~="table" then return end
    for _,v in ipairs(list) do
        if A.Number(v.nodeID) and A.Ordinary(v.isUndiscovered) and type(v.isUndiscovered)=="boolean" and A.Number(v.faction) and v.faction>=0 and v.faction<=2 then
            character.known[v.nodeID]={state=v.isUndiscovered and "undiscovered" or "known",faction=({[0]="Neutral",[1]="Horde",[2]="Alliance"})[v.faction]}
            local p=nodes[v.nodeID]
            if p then p.faction=character.known[v.nodeID].faction end
        end
    end
end
function A.Taxi(id,character,data)
    local list=A.Call(C_TaxiMap and C_TaxiMap.GetAllTaxiNodes,id)
    if type(list)~="table" then return nil end
    local slots,current={},nil
    for _,v in ipairs(list) do if A.Number(v.slotIndex) and A.Number(v.nodeID) and A.Number(v.state) then
        slots[v.slotIndex]=v;if v.state==0 then current=v end
    end end
    if not current then return nil end
    local offers={};local byPair={}
    for _,e in ipairs(data.edges) do if not e.live then local key=tostring(e.from)..":"..tostring(e.to);if byPair[key]~=nil then byPair[key]=false else byPair[key]=e end end end
    for _,v in pairs(slots) do if v.state==1 then
        local count=A.Call(GetNumRoutes,v.slotIndex)
        if A.Number(count) and count>0 and count<100 then
            local legs,valid={},true;local previous=current.nodeID
            for i=1,count do
                local src=A.Call(TaxiGetNodeSlot,v.slotIndex,i,true);local dst=A.Call(TaxiGetNodeSlot,v.slotIndex,i,false)
                local s,d=A.Number(src) and slots[src],A.Number(dst) and slots[dst]
                local edge=s and d and byPair[tostring(s.nodeID)..":"..tostring(d.nodeID)]
                if not edge or s.nodeID~=previous then valid=false;break end
                legs[#legs+1]=edge;previous=d.nodeID
            end
            if valid and previous==v.nodeID then
                local ids={};local distance=0;for _,e in ipairs(legs) do ids[#ids+1]=e.id;distance=distance+e.distance end
                local key=table.concat(ids,",");local geometry={}
                for _,edge in ipairs(legs) do if edge.points then geometry[#geometry+1]={map=data.nodes[edge.from].map,points=edge.points} end end
                local cost=A.Call(TaxiNodeCost,v.slotIndex);if not A.Number(cost) then cost=nil end
                offers[v.nodeID]={from=current.nodeID,to=v.nodeID,legs=legs,geometry=geometry,key=key,distance=distance,cost=cost,slot=v.slotIndex}
            end
        end
    end end
    return {from=current.nodeID,offers=offers}
end
