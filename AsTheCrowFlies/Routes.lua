local _,N=...;local M=N.Model;local R={};N.Routes=R
local function edgeOK(e,ctx,conditional)
    if not M.Number(e.distance) or e.distance<0 or not M.Allowed(e,ctx) or e.disabled then return false end
    if e.mode=="flight" then
        local a,b=ctx.known[e.from],ctx.known[e.to]
        if (a and a.state=="undiscovered") or (b and b.state=="undiscovered") then return false end
        if not conditional and not e.offered then return false end
    end
    return true
end
-- Nonnegative directed Dijkstra, stable tie handling and cycle-safe reconstruction.
function R.Shortest(nodes,edges,from,to,ctx,banned,conditional,requireFlight)
    local adj={};for _,e in ipairs(edges) do
        if nodes[e.from] and nodes[e.to] and not (banned and banned[e.id]) and edgeOK(e,ctx,conditional) then
            adj[e.from]=adj[e.from] or {};table.insert(adj[e.from],e)
        end
    end
    local start="0:"..tostring(from)
    local dist,prev,done={[start]=0},{},{}
    local states={[start]={node=from,flown=false}};local finish
    while true do
        local u,best
        for id,d in pairs(dist) do if not done[id] and (not best or d<best or (d==best and tostring(id)<tostring(u))) then u,best=id,d end end
        if not u then return nil end
        local state=states[u]
        if state.node==to and (not requireFlight or state.flown) then finish=u;break end;done[u]=true
        for _,e in ipairs(adj[state.node] or {}) do
            local d=best+e.distance
            local flown=state.flown or e.mode=="flight"
            local key=(flown and "1:" or "0:")..tostring(e.to)
            if not done[key] and (not dist[key] or d<dist[key]) then
                dist[key]=d;prev[key]={edge=e,previous=u};states[key]={node=e.to,flown=flown}
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
        r.distance=r.distance+e.distance;r.signature=r.signature.."/"..tostring(e.id)
        if e.mode=="flight" then
            r.flight=r.flight+e.distance;r.hops[#r.hops+1]=e.to
            r.conditional=r.conditional or not e.offered
            local measured=N.Settings.Timing(ctx.timings or {},e.timingKey or tostring(e.id))
            e.seconds=measured or e.distance/(ctx.flightPrior or 32)+(e.delay or 0)
            r.eta=r.eta+e.seconds
            r.prior=r.prior or not measured
        else
            r.walk=r.walk+e.distance;r.eta=r.eta+e.distance/(ctx.speed or 7)
            if e.quality=="bearing" then r.quality="bearing" elseif e.quality=="approximate" and r.quality~="bearing" then r.quality="approximate" end
        end
    end
    return r
end
local function connector(id,from,to,a,b)
    local d=M.Distance(a,b);if not d then return nil end
    return {id=id,from=from,to=to,start=a,finish=b,distance=d,mode="walk",quality="bearing"}
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
            local best=R.Shortest(nodes,edges,"origin","destination",ctx,nil,true,true)
            local candidates={best}
            if best then for _,e in ipairs(best) do if e.mode=="flight" then
                candidates[#candidates+1]=R.Shortest(nodes,edges,"origin","destination",ctx,{[e.id]=true},true,true)
                if #candidates>=5 then break end
            end end end
            for _,legs in ipairs(candidates) do if legs then
                local r=R.Summary(legs,dest,ctx)
                if r.flight>0 and not seen[r.signature] then seen[r.signature]=true;results[#results+1]=r end
            end end
        end
    end
    local quality={verified=1,approximate=2,bearing=3}
    table.sort(results,function(a,b)
        if a.quality~=b.quality then return quality[a.quality]<quality[b.quality] end
        if a.distance==b.distance then return a.signature<b.signature end;return a.distance<b.distance
    end)
    while #results>3 do results[#results]=nil end
    return results,#results==0 and "No connected route on this continent" or nil
end
