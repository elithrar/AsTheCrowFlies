local _,N=...;local M=N.Model;local R={};N.Routes=R
local function edgeOK(e,ctx,conditional)
    if not M.Number(e.distance) or e.distance<0 or not M.Allowed(e,ctx) or e.disabled then return false end
    if e.mode=="flight" then
        if ctx.taxiFrom==e.from and not e.offered then return false end
        local a,b=ctx.known[e.from],ctx.known[e.to]
        if not e.offered and (not a or a.state~="known" or not b or b.state~="known") then return false end
        if (a and a.state=="undiscovered") or (b and b.state=="undiscovered") then return false end
        if not conditional and not e.offered then return false end
    end
    return true
end
function R.Seconds(e,ctx)
    if e.mode=="flight" then
        local measured=N.Settings.Timing(ctx.timings or {},e.timingKey or tostring(e.id))
        return measured or e.distance/(ctx.flightPrior or 32)+(e.delay or 0),not measured
    end
    return e.distance/(ctx.speed or 7),false
end
-- Nonnegative directed Dijkstra; ties prefer current offered flight evidence.
function R.Shortest(nodes,edges,from,to,ctx,banned,conditional,requireFlight,metric)
    local adj={};for _,e in ipairs(edges) do
        if nodes[e.from] and nodes[e.to] and not (banned and banned[e.id]) and edgeOK(e,ctx,conditional) then
            adj[e.from]=adj[e.from] or {};table.insert(adj[e.from],e)
        end
    end
    local start="0:"..tostring(from)
    local dist,prev,done,uncertain={[start]=0},{},{},{[start]=0}
    local states={[start]={node=from,flown=false}};local finish
    while true do
        local u,best
        for id,d in pairs(dist) do if not done[id] and (not best or d<best or (d==best and (uncertain[id]<uncertain[u] or (uncertain[id]==uncertain[u] and tostring(id)<tostring(u))))) then u,best=id,d end end
        if not u then return nil end
        local state=states[u]
        if state.node==to and (not requireFlight or state.flown) then finish=u;break end;done[u]=true
        for _,e in ipairs(adj[state.node] or {}) do
            if not state.terminal or e.mode~="flight" then
            local d=best+(metric=="time" and R.Seconds(e,ctx) or e.distance)
            local risk=uncertain[u]+(e.mode=="flight" and not e.offered and 1 or 0)
            local flown=state.flown or e.mode=="flight"
            local terminal=state.terminal or (e.mode=="flight" and e.offered and ctx.taxiFrom==e.from)
            local key=(terminal and "2:" or flown and "1:" or "0:")..tostring(e.to)
            if not done[key] and (not dist[key] or d<dist[key] or (d==dist[key] and risk<uncertain[key])) then
                dist[key]=d;uncertain[key]=risk;prev[key]={edge=e,previous=u};states[key]={node=e.to,flown=flown,terminal=terminal}
            end
            end
        end
    end
    local out,u={},finish
    while u~=start do local p=prev[u];if not p or #out>#edges then return nil end;table.insert(out,1,p.edge);u=p.previous end
    return out,dist[finish]
end
function R.Summary(legs,destination,ctx)
    local r={legs=legs,destination=destination,distance=0,walk=0,flight=0,eta=0,quality="verified",conditional=false,hops={},signature=tostring(destination.id)}
    r.legs={}
    for _,original in ipairs(legs) do
        local e=M.Copy(original);r.legs[#r.legs+1]=e
        r.distance=r.distance+e.distance
        if e.mode=="flight" then
            r.signature=r.signature.."/"..tostring(e.timingKey or e.id):gsub(",","/")
            r.flight=r.flight+e.distance;r.hops[#r.hops+1]=e.to
            r.conditional=r.conditional or not e.offered
            local prior;e.seconds,prior=R.Seconds(e,ctx)
            r.eta=r.eta+e.seconds
            r.prior=r.prior or prior
        else
            r.walk=r.walk+e.distance;r.eta=r.eta+e.distance/(ctx.speed or 7)
            if e.quality=="bearing" then r.quality="bearing" elseif e.quality=="approximate" and r.quality~="bearing" then r.quality="approximate" end
        end
    end
    if r.flight==0 then r.signature=r.signature.."/walk" end
    return r
end
local function connector(id,from,to,a,b)
    local d=M.Distance(a,b);if not d then return nil end
    return {id=id,from=from,to=to,start=a,finish=b,distance=d,mode="walk",quality="bearing"}
end
-- A bounded NPC shortlist: nearby records plus records near cheap reachable exits.
-- One multi-source shortest-time pass supplies heuristic arrival costs at masters.
function R.Candidates(origin,candidates,data,ctx,limit)
    limit=limit or 12;ctx.known=ctx.known or {}
    local ordered={};for _,p in ipairs(candidates) do if M.Allowed(p,ctx) and M.Distance(origin,p) then ordered[#ordered+1]=p end end
    local function direct(p) return M.Distance(origin,p) or math.huge end
    table.sort(ordered,function(a,b) local da,db=direct(a),direct(b);return da==db and tostring(a.id)<tostring(b.id) or da<db end)
    if #ordered<=limit then return ordered,false end
    local out,seen={},{}
    local function add(p) if not seen[p.id] then seen[p.id]=true;out[#out+1]=p end end
    for i=1,limit do add(ordered[i]) end
    if ctx.routeOrder=="time" then
        local times,done,adj={},{},{}
        for id,p in pairs(data.nodes or {}) do
            local known=ctx.known[id];local distance=M.Distance(origin,p)
            if known and known.state=="known" and M.Allowed(p,ctx) and distance then times[id]=distance/(ctx.speed or 7) end
        end
        for _,e in ipairs(data.edges or {}) do if times[e.from] and times[e.to] and edgeOK(e,ctx,true) then
            adj[e.from]=adj[e.from] or {};adj[e.from][#adj[e.from]+1]=e
        end end
        while true do
            local u,best;for id,value in pairs(times) do if not done[id] and (not best or value<best) then u,best=id,value end end
            if not u then break end;done[u]=true
            for _,e in ipairs(adj[u] or {}) do local value=best+R.Seconds(e,ctx);if value<times[e.to] then times[e.to]=value end end
        end
        local estimate={}
        for _,p in ipairs(ordered) do
            local best=direct(p)/(ctx.speed or 7)
            for id,value in pairs(times) do local distance=M.Distance(data.nodes[id],p);if distance then best=math.min(best,value+distance/(ctx.speed or 7)) end end
            estimate[p.id]=best
        end
        table.sort(ordered,function(a,b) return estimate[a.id]==estimate[b.id] and tostring(a.id)<tostring(b.id) or estimate[a.id]<estimate[b.id] end)
        for i=1,limit do add(ordered[i]) end
    end
    return out,#out<#ordered
end
function R.Plan(origin,destinations,data,ctx)
    if not M.Position(origin) then return {},"Current location unavailable" end
    ctx.known=ctx.known or {};local results,seen={},{}
    local nodes={origin=origin};for id,p in pairs(data.nodes or {}) do if p.map==origin.map and M.Allowed(p,ctx) and (not ctx.requireObserved or ctx.known[id]) then nodes[id]=p end end
    for _,dest in ipairs(destinations) do
        if M.Allowed(dest,ctx) and M.Distance(origin,dest) then
            local walk=connector("bearing","origin","destination",origin,dest)
            results[#results+1]=R.Summary({walk},dest,ctx)
            local edges={};nodes.destination=dest
            for _,e in ipairs(data.edges or {}) do
                if nodes[e.from] and nodes[e.to] then edges[#edges+1]=e end
            end
            for id,p in pairs(nodes) do if type(id)=="number" then
                edges[#edges+1]=connector("depart:"..id,"origin",id,origin,p)
                edges[#edges+1]=connector("arrive:"..id,id,"destination",p,dest)
            end end
            -- Require at least one flight: omit direct origin->destination here.
            local metric=ctx.routeOrder or "distance"
            local best=R.Shortest(nodes,edges,"origin","destination",ctx,nil,true,true,metric)
            local candidates={best}
            local other=R.Shortest(nodes,edges,"origin","destination",ctx,nil,true,true,metric=="time" and "distance" or "time")
            if other then candidates[#candidates+1]=other end
            if best then for _,e in ipairs(best) do if e.mode=="flight" then
                candidates[#candidates+1]=R.Shortest(nodes,edges,"origin","destination",ctx,{[e.id]=true},true,true,metric)
                if #candidates>=5 then break end
            end end end
            for _,legs in ipairs(candidates) do if legs then
                local r=R.Summary(legs,dest,ctx)
                if r.flight>0 then
                    local index=seen[r.signature]
                    if not index then results[#results+1]=r;seen[r.signature]=#results
                    elseif results[index].conditional and not r.conditional then results[index]=r end
                end
            end end
        end
    end
    local quality={verified=1,approximate=2,bearing=3}
    table.sort(results,function(a,b)
        if a.quality~=b.quality then return quality[a.quality]<quality[b.quality] end
        if ctx.routeOrder=="time" and a.eta~=b.eta then return a.eta<b.eta end
        if a.distance==b.distance then return a.signature<b.signature end;return a.distance<b.distance
    end)
    while #results>3 do results[#results]=nil end
    return results,#results==0 and "No connected route on this continent" or nil
end
