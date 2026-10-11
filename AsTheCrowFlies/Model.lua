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
local classTokens={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local categoryWords={class="class trainer",profession="profession trainer",trainer="trainer",auction="auction house auctioneer",quest="quest npc",flight="flight master taxi",place="saved place location"}
local function active(set)
    if type(set)=="table" then for _,value in pairs(set) do if value==true then return true end end end
    return false
end
function M.HasFilter(filter)
    if type(filter)~="table" then return false end
    if type(filter.categories)=="table" then return active(filter.categories) end
    return (filter.category~=nil and filter.category~="all") or filter.class~=nil or filter.profession~=nil
end
local function category(p,key) return p.category==key or (type(p.categories)=="table" and p.categories[key]==true) end
local function words(text,maximum)
    local out,overlong={},false;for word in text:sub(1,256):gmatch("[%w\128-\255]+") do
        if #word<=24 then out[#out+1]=word else overlong=true end
        if #out>=maximum then break end
    end;return out,overlong
end
-- Banded edit distance (including adjacent swaps), at most two edits on
-- ASCII words <=24 bytes. Short
-- prefixes stay useful, while short words never create broad fuzzy matches.
local function edits(a,b,budget)
    if math.abs(#a-#b)>budget then return false end
    local previous,older={},nil;for j=0,#b do previous[j]=j end
    for i=1,#a do
        local row={[0]=i};local best=budget+1
        for j=math.max(1,i-budget),math.min(#b,i+budget) do
            row[j]=math.min((row[j-1] or budget+1)+1,(previous[j] or budget+1)+1,(previous[j-1] or budget+1)+(a:byte(i)==b:byte(j) and 0 or 1))
            if older and j>1 and a:byte(i)==b:byte(j-1) and a:byte(i-1)==b:byte(j) then row[j]=math.min(row[j],(older[j-2] or budget+1)+1) end
            best=math.min(best,row[j])
        end
        if best>budget then return false end;older,previous=previous,row
    end
    return (previous[#b] or budget+1)<=budget
end
local function matcher()
    local cache,count={},0
    return function(token,word)
        local key=token.."/"..word;local cached=cache[key];if cached~=nil then return cached end
        local value=false
        if token==word then value=0
        elseif word:sub(1,#token)==token then value=1
        elseif #token>=4 and #word<=24 and token:match("^[a-z]+$") and word:match("^[a-z]+$") and edits(token,word,#token>=7 and 2 or 1) then value=2 end
        if count<4096 then cache[key]=value;count=count+1 end;return value
    end
end
local function matchWords(tokens,list,match)
    local worst=0
    for _,token in ipairs(tokens) do
        local best
        for _,word in ipairs(list) do local value=match(token,word);if value~=false and (not best or value<best) then best=value;if best==0 then break end end end
        if best==nil then return nil end;worst=math.max(worst,best)
    end
    return worst
end
local function allowedFilter(p,filter,ctx,inferred)
    local modern=type(filter.categories)=="table"
    local function subset(key)
        if key=="class" then
            if modern then
                if not active(filter.classes) then return true end
                for class,on in pairs(filter.classes) do if on==true and (p.class==class or (p.classes and p.classes[class])) then return true end end
                return false
            end
            local class=filter.class or (filter.category=="class" and not next(inferred) and ctx.class)
            if class then return p.class==class or (p.classes and p.classes[class]) end
            if filter.category=="class" and next(inferred) then
                for c in pairs(inferred) do if p.class==c or (p.classes and p.classes[c]) then return true end end;return false
            end
        elseif key=="profession" then
            if modern and active(filter.professions) then return filter.professions[p.profession]==true end
            if not modern and filter.profession then return p.profession==filter.profession end
        end
        return true
    end
    if modern and active(filter.categories) then
        for key,on in pairs(filter.categories) do if on==true and category(p,key) and subset(key) then return true end end;return false
    elseif modern then return true
    elseif not modern and filter.category and filter.category~="all" then
        return category(p,filter.category) and subset(filter.category)
    end
    return subset(p.category)
end
-- Exact full NPC names remain first. Otherwise semantic role matches precede
-- incidental names, then mixed name/role/zone matches. The second return is a
-- query-local tier map keyed by original records, for route candidate selection.
function M.Search(items,query,filter,ctx,limit,origin)
    local result,relevance,names,distances={},{},{},{}
    query=M.Fold(query):match("^%s*(.-)%s*$"):gsub("%s+"," ");filter=filter or {};ctx=ctx or {}
    if #query>128 then return result,relevance end
    local tokens,overlong=words(query,7);local match=matcher();local inferred={}
    if not overlong and #tokens<=6 then for _,c in ipairs(classTokens) do for _,token in ipairs(tokens) do if #token>=3 and match(token,c:lower())~=false then inferred[c]=true end end end end
    for _,p in ipairs(items) do
        if M.Allowed(p,ctx) and allowedFilter(p,filter,ctx,inferred) then
            local name=M.Fold(p.name):sub(1,256);local score
            if query=="" or name==query then score=0
            elseif not overlong and #tokens>0 and #tokens<=6 then
                local semantic=(p.role or "").." "..(p.class or "").." "..(p.profession or "").." "..(categoryWords[p.category] or "")
                for c,on in pairs(p.classes or {}) do if on then semantic=semantic.." "..c end end
                for c,on in pairs(p.categories or {}) do if on then semantic=semantic.." "..(categoryWords[c] or "") end end
                local roleWords=words(M.Fold(semantic),32);local value=matchWords(tokens,roleWords,match)
                if value then score=10+value
                else
                    local nameWords=words(name,16);value=matchWords(tokens,nameWords,match)
                    if value then score=20+value
                    else
                        local combined={};for _,word in ipairs(roleWords) do combined[#combined+1]=word end;for _,word in ipairs(nameWords) do combined[#combined+1]=word end
                        for _,word in ipairs(words(M.Fold(p.zone),16)) do combined[#combined+1]=word end
                        value=matchWords(tokens,combined,match);if value then score=30+value end
                    end
                end
            end
            if score then result[#result+1]=p;relevance[p]=score;names[p]=name;distances[p]=origin and M.Distance(origin,p) or nil end
        end
    end
    table.sort(result,function(a,b)
        if relevance[a]~=relevance[b] then return relevance[a]<relevance[b] end
        local da,db=distances[a],distances[b]
        if da and not db then return true elseif db and not da then return false end
        if da and db and da~=db then return da<db end
        if names[a]==names[b] then return tostring(a.id)<tostring(b.id) end;return names[a]<names[b]
    end)
    if limit then while #result>limit do result[#result]=nil end end
    return result,relevance
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
function M.Minutes(seconds)
    if not M.Number(seconds) then return "? min" end
    return seconds<60 and "<1 min" or math.max(1,math.floor(seconds/60+.5)).." min"
end
-- An uncalibrated allowance for bends/obstacles, not a traversable path claim.
-- Physical yards remain unchanged; verified measured corridors need no uplift.
function M.GroundSeconds(distance,speed,quality)
    if not M.Number(distance) or distance<0 then return nil end
    speed=M.Number(speed) and speed>0 and speed<=50 and speed or 7
    return distance/speed*(quality=="bearing" and 1.35 or 1)
end
function M.RouteMode(route)
    for _,leg in ipairs(route.legs) do if leg.mode=="flight" then return "Walk + fly" end end
    return "Walk"
end
function M.RouteLegs(route,speed)
    local before,after,flight=0,0,0;local first,last
    for _,leg in ipairs(route.legs) do
        if leg.mode=="flight" then first=first or leg;last=leg;flight=flight+(leg.seconds or leg.distance/32)
        else
            -- Route cards share their planned total's timing snapshot. Live
            -- remaining guidance recalculates ground time in Navigation.lua.
            local seconds=leg.seconds or M.GroundSeconds(leg.distance,speed,leg.quality)
            if first then after=after+seconds else before=before+seconds end
        end
    end
    if not first then return "Walk ~"..M.Minutes(before) end
    return "Walk ~"..M.Minutes(before).."\nFly ~"..M.Minutes(flight)..": "..(first.start.name or "Departure").." to "..(last.finish.name or "Arrival").."\nWalk ~"..M.Minutes(after)
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
local compass={"N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"}
-- World bearing stays independent of the player's facing and rotating arrow.
function M.Cardinal(a,b)
    local east,north=M.Vector(a,b,nil)
    if not east or (east==0 and north==0) then return nil end
    local sector=math.floor((math.atan2(east,north)+math.pi/16)/(math.pi/8))%16
    return compass[sector+1]
end
function M.Minimap(east,north,radius,width,height,shape)
    if not M.Number(radius) or radius<=0 then return nil end
    local x,y=east/radius*(width/2-10),north/radius*(height/2-10)
    local rx,ry=math.max(1,width/2-10),math.max(1,height/2-10)
    local factor=shape=="SQUARE" and math.max(math.abs(x)/rx,math.abs(y)/ry) or math.sqrt((x/rx)^2+(y/ry)^2)
    local clipped=factor>1; if clipped then x,y=x/factor,y/factor end
    return x,y,clipped
end
-- Liang-Barsky clipping in the viewed map's normalized coordinate rectangle.
-- Out-of-view points are clipped, not clamped individually (which bends paths).
function M.ClipSegment(x1,y1,x2,y2)
    if not M.Number(x1) or not M.Number(y1) or not M.Number(x2) or not M.Number(y2) then return nil end
    local dx,dy=x2-x1,y2-y1;local low,high=0,1
    local p,q={-dx,dx,-dy,dy},{x1,1-x1,y1,1-y1}
    for i=1,4 do
        if p[i]==0 then if q[i]<0 then return nil end
        else
            local r=q[i]/p[i]
            if p[i]<0 then low=math.max(low,r) else high=math.min(high,r) end
            if low>high then return nil end
        end
    end
    return x1+low*dx,y1+low*dy,x1+high*dx,y1+high*dy
end
