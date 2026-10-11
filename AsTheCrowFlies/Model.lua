local _, N = ...
local M = {}; N.Model = M
function M.Number(v) return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
function M.Copy(v)
    if type(v)~="table" then return v end
    local out={}; for k,x in pairs(v) do out[k]=M.Copy(x) end; return out
end
function M.Position(p)
    return type(p)=="table" and M.Number(p.x) and M.Number(p.y) and M.Number(p.map)
end
function M.Distance(a,b)
    if not M.Position(a) or not M.Position(b) or a.map~=b.map then return nil end
    return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end
function M.SameFloor(a,b)
    return M.Position(a) and M.Position(b) and a.map==b.map and a.uiMapID==b.uiMapID
end
function M.Allowed(item,ctx)
    return item.available~=false and (not item.faction or item.faction=="Neutral" or item.faction==ctx.faction)
end
local accents={ ["á"]="a",["à"]="a",["ä"]="a",["â"]="a",["é"]="e",["è"]="e",["ê"]="e",["ë"]="e",["í"]="i",["ï"]="i",["ó"]="o",["ö"]="o",["ô"]="o",["ú"]="u",["ü"]="u",["ñ"]="n",["Á"]="a",["É"]="e",["Ö"]="o",["Ü"]="u" }
function M.Fold(s)
    s=tostring(s or "");for a,b in pairs(accents) do s=s:gsub(a,b) end
    return (s:gsub("[A-Z]",function(c) return string.char(c:byte()+32) end))
end
function M.Search(items,query,filter,ctx,limit)
    local result={}; query=M.Fold(query); filter=filter or {}; ctx=ctx or {}
    for _,p in ipairs(items) do
        local category=not filter.category or filter.category=="all" or p.category==filter.category or (p.categories and p.categories[filter.category])
        local class=filter.class or (filter.category=="class" and ctx.class)
        if category and M.Allowed(p,ctx) and (not class or p.class==class or (p.classes and p.classes[class]))
            and (not filter.profession or p.profession==filter.profession)
            and M.Fold((p.name or "").." "..(p.zone or "").." "..(p.role or "")):find(query,1,true) then
            result[#result+1]=p
        end
    end
    table.sort(result,function(a,b)
        local an,bn=M.Fold(a.name),M.Fold(b.name)
        if an==bn then return tostring(a.id)<tostring(b.id) end; return an<bn
    end)
    if limit then while #result>limit do result[#result]=nil end end
    return result
end
function M.Speed(current,run,previous,onTaxi)
    if onTaxi then return previous or 7,"recent ground speed" end
    local sample=M.Number(current) and current>0 and current<=50 and current or nil
    if sample then return previous and (previous*.65+sample*.35) or sample,"observed movement" end
    if M.Number(run) and run>0 and run<=50 then return run,"run speed" end
    return previous or 7,previous and "recent ground speed" or "typical running prior"
end
function M.Time(seconds)
    if not M.Number(seconds) then return "time unknown" end
    if seconds<60 then return "about <1 min" end
    return "about "..math.max(1,math.floor(seconds/60+.5)).." min"
end
function M.Yards(v) return M.Number(v) and (v>=1000 and string.format("%.1f k yd",v/1000) or string.format("%.0f yd",v)) or "distance unknown" end
-- World coordinates increase north (x) and west (y); screen axes are east/up.
function M.Vector(a,b,facing)
    if not M.Distance(a,b) then return nil end
    local east,north=-(b.y-a.y),b.x-a.x
    if M.Number(facing) then
        local c,s=math.cos(facing),math.sin(facing)
        return east*c+north*s,north*c-east*s
    end
    return east,north
end
function M.Minimap(east,north,radius,width,height,shape)
    if not M.Number(radius) or radius<=0 then return nil end
    local x,y=east/radius*(width/2-10),north/radius*(height/2-10)
    local rx,ry=math.max(1,width/2-10),math.max(1,height/2-10)
    local factor=shape=="SQUARE" and math.max(math.abs(x)/rx,math.abs(y)/ry) or math.sqrt((x/rx)^2+(y/ry)^2)
    local clipped=factor>1; if clipped then x,y=x/factor,y/factor end
    return x,y,clipped
end
