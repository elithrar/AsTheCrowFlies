local _,N=...;local M,A=N.Model,N.Adapter;local P={};N.Providers=P
local classes={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local professions={"Alchemy","Blacksmithing","Enchanting","Engineering","Herbalism","Leatherworking","Mining","Skinning","Tailoring","Cooking","First Aid","Fishing"}
local aliases={Alchemy={"alchemist","alchemy"},Blacksmithing={"blacksmith","armorsmith","weaponsmith","armor crafter","weapon crafter"},Enchanting={"enchant"},Engineering={"engineer"},Herbalism={"herbal"},Leatherworking={"leatherwork"},Mining={"mining","miner"},Skinning={"skinning","skinner"},Tailoring={"tailor"},Cooking={"cooking","cook"},["First Aid"]={"first aid","physician","trauma surgeon"},Fishing={"fishing","fisher"}}
P.classes=classes;P.professions=professions
local function has(flags,mask) return M.Number(flags) and math.floor(flags/mask)%2==1 end
-- QuestieDB's support contract carries this numeric map as serialized text.
-- Parse only [integer]=integer pairs; never evaluate provider data as Lua.
function P.MapRegistry(value)
    if type(value)=="table" then
        local out={};for k,v in pairs(value) do if not M.Number(k) or not M.Number(v) then return nil end;out[k]=v end;return out
    end
    if type(value)~="string" or #value>200000 then return nil end
    local body=value:gsub("%-%-[^\r\n]*",""):match("^%s*return%s*{(.*)}%s*$")
    if not body then return nil end
    local out={}
    while body:find("%S") do
        local k,v,finish=body:match("^%s*%[(%d+)%]%s*=%s*(%d+)%s*,?()")
        if not finish then return nil end
        out[tonumber(k)]=tonumber(v);body=body:sub(finish)
    end
    return out
end
function P.Connect()
    local lib=LibQuestieDB
    if type(lib)~="table" or type(lib.RequireContract)~="function" or not lib.flavor or lib.flavor.name~="Forever" then return nil,"Forever QuestieDB not available" end
    local ok,result=pcall(lib.RequireContract,3)
    if not ok or result==false or not lib.Npc or not lib.Support then return nil,"QuestieDB contract 3 unavailable" end
    local zone=A.Call(lib.Support.Get,"ZoneDB")
    local registry=zone and zone.private and P.MapRegistry(zone.private.areaIdToUiMapId)
    if not registry then return nil,"QuestieDB map registry unavailable" end
    local override=zone.private.areaIdToUiMapIdOverride and P.MapRegistry(zone.private.areaIdToUiMapIdOverride)
    if zone.private.areaIdToUiMapIdOverride and not override then return nil,"QuestieDB map overrides unsupported" end
    for area,map in pairs(override or {}) do registry[area]=map end
    return {lib=lib,zone=registry,ids=A.Call(lib.Npc.GetAllIds),cursor=1,items={},counts={npcs=0,spawns=0,unmapped=0,unknownTrainers=0,phase=0},classMap={}}
end
function P.Classify(title,flags,starts,ends)
    local lower=M.Fold(title);local category,role,class,profession
    if has(flags,4096) then category="auction";role="Auction house"
    elseif has(flags,16) then
        category="trainer";role=title or "Trainer (specialization unknown)"
        for _,c in ipairs(classes) do if lower:find(c:lower(),1,true) then category="class";class=c;break end end
        if not class then for _,p in ipairs(professions) do for _,alias in ipairs(aliases[p]) do if lower:find(alias,1,true) then category="profession";profession=p;break end end;if profession then break end end end
    elseif (type(starts)=="table" and next(starts)) or (type(ends)=="table" and next(ends)) then category="quest";role="Quest NPC" end
    if not class and not profession then
        for _,p in ipairs(professions) do for _,alias in ipairs(aliases[p]) do if lower:find(alias,1,true) then category="profession";profession=p;role=title;break end end;if profession then break end end
    end
    return category,role,class,profession
end
-- Called in bounded batches by Core; no provider scan in OnUpdate or per keystroke.
function P.Step(s,budget)
    if type(s.ids)~="table" then return true end
    for _=1,budget or 30 do
        local id=s.ids[s.cursor];if not id then return true end;s.cursor=s.cursor+1
        local npc=s.lib.Npc;local flags=A.Call(npc.Get,id,"npcFlags")
        local starts,ends=A.Call(npc.Get,id,"questStarts"),A.Call(npc.Get,id,"questEnds")
        local title=A.Call(npc.Get,id,"subName");local raw=A.Call(npc.GetRaw,id,"subName")
        local category,role,class,profession=P.Classify(title,flags,starts,ends)
        if not class and not profession and raw then
            local rc,rr,rclass,rprofession=P.Classify(raw,flags,starts,ends)
            if rclass or rprofession then category,role,class,profession=rc,rr,rclass,rprofession end
        end
        if category then
            local name=A.Call(npc.Get,id,"name");local spawns=A.Call(npc.Get,id,"spawns")
            local friendly=A.Call(npc.Get,id,"friendlyToFaction")
            local faction=friendly=="A" and "Alliance" or friendly=="H" and "Horde" or friendly=="AH" and "Neutral" or nil
            local mobile=next(A.Call(npc.Get,id,"waypoints") or {})~=nil
            s.counts.npcs=s.counts.npcs+1
            if category=="trainer" then s.counts.unknownTrainers=s.counts.unknownTrainers+1 end
            for area,positions in pairs(type(spawns)=="table" and spawns or {}) do
                local map=s.zone[area]
                for index,xyz in ipairs(type(positions)=="table" and positions or {}) do
                    local p=map and type(xyz)=="table" and M.Number(xyz[1]) and M.Number(xyz[2]) and A.FromMap(map,xyz[1]/100,xyz[2]/100)
                    if p then
                        p.id="qdb:"..id..":"..area..":"..index;p.npcID=id;p.name=name or tostring(id)
                        p.category=category;p.class=class;p.profession=profession;p.role=title or role;p.faction=faction;p.available=faction~=nil
                        p.categories={};p.categories[category]=true
                        if type(starts)=="table" and next(starts) or type(ends)=="table" and next(ends) then p.categories.quest=true end
                        p.questStarts=type(starts)=="table" and #starts or 0;p.questEnds=type(ends)=="table" and #ends or 0
                        p.phase=xyz[3];p.mobile=mobile;p.confidence="provider";p.source="QuestieDB Forever"
                        local info=A.Call(C_Map and C_Map.GetMapInfo,map);p.zone=info and info.name or ("Map "..map)
                        if p.phase then s.counts.phase=s.counts.phase+1 end
                        s.items[#s.items+1]=p;s.counts.spawns=s.counts.spawns+1
                    else s.counts.unmapped=s.counts.unmapped+1 end
                end
            end
        end
    end
    return false
end
function P.Remember(character,p,name,category,class,profession)
    if not M.Position(p) or type(name)~="string" or name=="" then return nil end
    local point=M.Copy(p);point.name=name:sub(1,100);point.category=category or "place";point.class=class;point.profession=profession
    point.id=string.format("local:%d:%.0f:%.0f",p.map,p.x,p.y);point.confidence="observed";point.source="Player-recorded location";point.zone=GetZoneText and GetZoneText() or ""
    for i,old in ipairs(character.places) do if old.id==point.id then character.places[i]=point;return point end end
    if #character.places>=500 then table.remove(character.places,1) end
    character.places[#character.places+1]=point;return point
end
