local _,N=...; local M=N.Model; local S={}; N.Settings=S
S.defaults={version=1,width=304,scale=1,font="Expressway",locked=false,dock="none",x=24,y=-180,overlays=true,flightPrior=32}
function S.Load(saved,build)
    saved=type(saved)=="table" and saved or {}
    -- Future settings are left intact by the owner and used read-only via defaults.
    if type(saved.version)=="number" and saved.version>1 then return M.Copy(S.defaults),true end
    local p=M.Copy(S.defaults)
    for k,d in pairs(p) do if type(saved[k])==type(d) then p[k]=saved[k] end end
    p.width=math.max(280,math.min(320,p.width)); p.scale=math.max(.65,math.min(1.6,p.scale))
    for _,k in ipairs({"width","scale","x","y","flightPrior"}) do if not M.Number(p[k]) then p[k]=S.defaults[k] end end
    p.flightPrior=math.max(10,math.min(60,p.flightPrior))
    p.x=math.max(-20000,math.min(20000,p.x));p.y=math.max(-20000,math.min(20000,p.y))
    if p.dock~="left" and p.dock~="right" then p.dock="none" end
    if #p.font>128 then p.font="Expressway" end
    p.version=1
    return p,false
end
function S.Character(saved,build)
    if type(saved)~="table" or saved.version~=1 or saved.build~=build then
        return {version=1,build=build,known={},offers={},timings={},places={}}
    end
    local out={version=1,build=build,known={},offers={},timings={},places={}}
    for id,v in pairs(type(saved.known)=="table" and saved.known or {}) do
        if type(id)=="number" and type(v)=="table" and (v.state=="known" or v.state=="undiscovered") then out.known[id]=M.Copy(v) end
    end
    -- Contextual availability must be revalidated after a reload; don't persist it.
    for key,list in pairs(type(saved.timings)=="table" and saved.timings or {}) do
        if type(key)=="string" and #key<512 and type(list)=="table" then
            local clean={};for _,v in ipairs(list) do if M.Number(v) and v>5 and v<3600 then clean[#clean+1]=v end end
            while #clean>9 do table.remove(clean,1) end;out.timings[key]=clean
        end
    end
    for _,p in ipairs(type(saved.places)=="table" and saved.places or {}) do
        if #out.places<500 and M.Position(p) and type(p.id)=="string" and type(p.name)=="string" then out.places[#out.places+1]=M.Copy(p) end
    end
    if type(saved.intent)=="string" then out.intent=saved.intent end
    return out
end
function S.Sample(store,key,seconds)
    if not M.Number(seconds) or seconds<5 or seconds>3600 then return false end
    local list=store[key] or {};local sorted=M.Copy(list);table.sort(sorted)
    local median=sorted[math.ceil(#sorted/2)]
    if median and #list>=3 and (seconds<median*.5 or seconds>median*2) then return false end
    list[#list+1]=seconds;while #list>9 do table.remove(list,1) end;store[key]=list;return true
end
function S.Timing(store,key)
    local list=store[key];if not list or #list==0 then return nil end
    local sum=0;for _,s in ipairs(list) do sum=sum+s end;return sum/#list,#list
end
