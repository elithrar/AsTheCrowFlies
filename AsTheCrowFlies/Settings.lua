local _,N=...; local M=N.Model; local S={}; N.Settings=S
S.minWidth=220;S.maxWidth=640
S.defaults={version=1,layoutVersion=2,width=240,resultsHeight=296,scale=1,font="Expressway",fontSize=13,locked=false,dock="none",dockPosition=.5,strata="HIGH",x=24,y=-180,mapMarkers=true,minimapMarkers=true,flightPrior=32,routeOrder="distance",
    colors={background={.045,.048,.062},accent={.78,.85,.61},text={.93,.94,.97}},searchFilters={categories={},classes={},professions={}}}
function S.Filters(saved)
    saved=type(saved)=="table" and saved or {};local clean={categories={},classes={},professions={}}
    local allowed={categories={"class","profession","auction","transmog","quest","trainer","flight","place"},
        classes={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"},
        professions={"Alchemy","Blacksmithing","Enchanting","Engineering","Herbalism","Leatherworking","Mining","Skinning","Tailoring","Cooking","First Aid","Fishing"}}
    for group,values in pairs(allowed) do
        local source=type(saved[group])=="table" and saved[group] or {}
        for _,value in ipairs(values) do if source[value]==true then clean[group][value]=true end end
    end
    return clean
end
function S.Load(saved,build)
    saved=type(saved)=="table" and saved or {}
    -- Future settings are left intact by the owner and used read-only via defaults.
    if type(saved.version)=="number" and saved.version>1 then return M.Copy(S.defaults),true end
    local p=M.Copy(S.defaults)
    for k,d in pairs(p) do if type(d)~="table" and type(saved[k])==type(d) then p[k]=saved[k] end end
    -- Only the former default narrows on upgrade. Once marked, a user can
    -- deliberately choose 304 again without another migration on reload.
    if (not M.Number(saved.layoutVersion) or saved.layoutVersion<2) and saved.width==304 then p.width=S.defaults.width end
    -- Split the former shared toggle without re-enabling markers a user hid.
    -- Explicit new preferences take precedence when loading mixed-version data.
    for _,key in ipairs({"mapMarkers","minimapMarkers"}) do
        if type(saved[key])~="boolean" and saved.overlays==false then p[key]=false end
    end
    for _,k in ipairs({"width","resultsHeight","scale","fontSize","x","y","flightPrior","dockPosition"}) do if not M.Number(p[k]) then p[k]=S.defaults[k] end end
    p.width=math.max(S.minWidth,math.min(S.maxWidth,p.width));p.resultsHeight=math.max(100,math.min(560,p.resultsHeight)); p.scale=math.max(.5,math.min(1.6,p.scale))
    p.dockPosition=math.max(0,math.min(1,p.dockPosition))
    p.fontSize=math.floor(math.max(10,math.min(18,p.fontSize)))
    p.flightPrior=math.max(10,math.min(60,p.flightPrior))
    p.x=math.max(-20000,math.min(20000,p.x));p.y=math.max(-20000,math.min(20000,p.y))
    if p.dock~="left" and p.dock~="right" then p.dock="none" end
    if p.strata~="LOW" and p.strata~="MEDIUM" and p.strata~="HIGH" then p.strata=S.defaults.strata end
    if p.routeOrder~="time" then p.routeOrder="distance" end
    if #p.font==0 or #p.font>128 or p.font:find("%c") then p.font="Expressway" end
    local colors=type(saved.colors)=="table" and saved.colors or {}
    for name,default in pairs(S.defaults.colors) do
        local rgb=type(colors[name])=="table" and colors[name] or {}
        for i=1,3 do p.colors[name][i]=M.Number(rgb[i]) and math.max(0,math.min(1,rgb[i])) or default[i] end
    end
    p.searchFilters=S.Filters(saved.searchFilters)
    p.version=1;p.layoutVersion=2
    return p,false
end
local function profileName(name)
    if type(name)~="string" then return nil end
    name=name:match("^%s*(.-)%s*$")
    if name=="" or #name>48 or name:find("[%c|]") then return nil end
    return name
end
local function writable(store)
    return type(store)=="table" and store.version==1 and not store.readOnly
        and type(store.profiles)=="table" and profileName(store.active)==store.active
        and type(store.profiles[store.active])=="table"
        and not (type(store.profiles[store.active].version)=="number" and store.profiles[store.active].version>1)
end
-- This store contains appearance/navigation preferences only. Character taxi
-- observations, timings, places and intent remain exclusively in Character().
function S.Profiles(saved,legacy)
    local migrated,legacyFuture=S.Load(legacy)
    local out={version=1,active="Default",profiles={Default=migrated}}
    if legacyFuture then out.readOnly=true;return out,true end
    if type(saved)~="table" or saved.version~=1 then
        local future=type(saved)=="table" and type(saved.version)=="number" and saved.version>1
        if future or legacyFuture then out.readOnly=true end
        return out,out.readOnly==true
    end
    local source=type(saved.profiles)=="table" and saved.profiles or {}
    local names={}
    for name,profile in pairs(source) do
        if profileName(name)==name and type(profile)=="table" then
            if type(profile.version)=="number" and profile.version>1 then
                -- Do not overwrite a future nested profile while saving its siblings.
                out.readOnly=true;return out,true
            end
            names[#names+1]=name
        end
    end
    table.sort(names)
    local count=1
    if type(source.Default)=="table" then out.profiles.Default=S.Load(source.Default) end
    local active=profileName(saved.active)
    if active==saved.active and type(source[active])=="table" then
        out.active=active
        if active~="Default" then out.profiles[active]=S.Load(source[active]);count=count+1 end
    end
    for _,name in ipairs(names) do
        if not out.profiles[name] and count<32 then out.profiles[name]=S.Load(source[name]);count=count+1 end
    end
    return out,false
end
function S.SwitchProfile(store,name)
    name=profileName(name)
    if not writable(store) then return nil,"Profiles are read-only or unavailable" end
    if not name or type(store.profiles[name])~="table" then return nil,"Profile not found" end
    local profile,future=S.Load(store.profiles[name]);if future then return nil,"Profile version is newer" end
    store.profiles[name]=profile;store.active=name;return profile
end
function S.DuplicateProfile(store,name)
    name=profileName(name)
    if not writable(store) then return nil,"Profiles are read-only or unavailable" end
    if not name then return nil,"Use a profile name of 1 to 48 characters" end
    if store.profiles[name]~=nil then return nil,"Profile already exists" end
    local count=0;for _ in pairs(store.profiles) do count=count+1 end
    if count>=32 then return nil,"Profile limit reached (32)" end
    local profile,future=S.Load(store.profiles[store.active]);if future then return nil,"Profile version is newer" end
    store.profiles[name]=profile;store.active=name;return profile
end
function S.CopyProfile(store,source)
    source=profileName(source)
    if not writable(store) then return nil,"Profiles are read-only or unavailable" end
    if not source or type(store.profiles[source])~="table" then return nil,"Profile not found" end
    local profile,future=S.Load(store.profiles[source]);if future then return nil,"Profile version is newer" end
    store.profiles[store.active]=profile;return profile
end
function S.ResetProfile(store)
    if not writable(store) then return nil,"Profiles are read-only or unavailable" end
    local profile=M.Copy(S.defaults);store.profiles[store.active]=profile;return profile
end
function S.Character(saved,build)
    if type(saved)~="table" or saved.version~=1 then
        return {version=1,build=build,known={},offers={},timings={},places={}}
    end
    local out={version=1,build=build,known={},offers={},timings={},places={}}
    local sameBuild=saved.build==build
    for id,v in pairs(sameBuild and type(saved.known)=="table" and saved.known or {}) do
        if type(id)=="number" and type(v)=="table" and (v.state=="known" or v.state=="undiscovered") then out.known[id]=M.Copy(v) end
    end
    -- Contextual availability must be revalidated after a reload; don't persist it.
    for key,list in pairs(sameBuild and type(saved.timings)=="table" and saved.timings or {}) do
        if type(key)=="string" and #key<512 and type(list)=="table" then
            local clean={};for _,v in ipairs(list) do if M.Number(v) and v>5 and v<3600 then clean[#clean+1]=v end end
            while #clean>9 do table.remove(clean,1) end;out.timings[key]=clean
        end
    end
    for _,p in ipairs(type(saved.places)=="table" and saved.places or {}) do
        if #out.places<500 and M.Position(p) and type(p.id)=="string" and type(p.name)=="string" then
            local place=M.Copy(p)
            if not sameBuild then place.observedBuild=place.observedBuild or saved.build;place.stale=true;place.available=false end
            out.places[#out.places+1]=place
        end
    end
    if sameBuild and type(saved.intent)=="string" then out.intent=saved.intent end
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
