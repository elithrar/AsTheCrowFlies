local _,N=...;local M=N.Model;local V={};N.Navigation=V
function V.New() return {state="editing",generation=0,leg=1} end
function V.Stop(s) s.generation=s.generation+1;s.state="editing";s.route=nil;s.dwell=nil;s.measure=nil;s.message=nil;s.previous=nil;s.previousTime=nil;s.flightSeen=nil;s.suspendedState=nil end
function V.Start(s,route,actual,now)
    if route and route.unavailable then s.message="Discover the required flight points first.";return false end
    V.Stop(s);if not route or not M.Position(actual) then return false end
    local first=route.legs[1]
    if not first or (M.Distance(first.start,actual) or math.huge)>40 then s.message="Recalculate from current location";return false end
    s.route=route;s.state="walking";s.started=now;s.leg=1;return true
end
function V.Target(s)
    if not s.route then return nil end
    local e=s.route.legs[s.leg]
    if e and e.mode=="flight" and s.state~="flying" then return e.start end
    return e and e.finish or s.route.destination
end
function V.Update(s,p,now,onTaxi,dead,offer)
    if not s.route or s.state=="arrived" or s.state=="unavailable" then return end
    if dead or not M.Position(p) then
        if onTaxi then
            local leg=s.route.legs[s.leg]
            if not leg or leg.mode~="flight" or (not s.flightSeen and (not offer or offer.from~=leg.from or offer.to~=leg.to)) then
                s.state="unavailable";s.message="Unconfirmed flight; recalculate after landing";s.measure=nil;return
            end
            s.flightSeen=true
        end
        if s.state~="paused" then s.suspendedState=s.state end
        s.state="paused";s.message=dead and "Paused while dead" or "Location unavailable";s.measure=nil;s.dwell=nil;return
    end
    if s.state=="paused" then s.state=s.suspendedState or "walking";s.suspendedState=nil;s.message=nil end
    local e=s.route.legs[s.leg];if not e then s.state="arrived";return end
    if e.mode=="flight" then
        if s.state~="flying" and onTaxi then
            if not s.flightSeen and (not offer or offer.from~=e.from or offer.to~=e.to) then s.state="unavailable";s.message="Unconfirmed flight; recalculate after landing";s.measure=nil;return end
            s.state="flying"
            if not s.flightSeen then s.measure={at=now,key=e.timingKey or tostring(e.id),generation=s.generation} end
            s.flightSeen=true;s.message="In flight"
        elseif (s.state=="flying" or s.flightSeen) and not onTaxi then
            if (M.Distance(p,e.finish) or math.huge)>150 then s.state="unavailable";s.message="Landed away from route; recalculate";s.measure=nil;return end
            local sample=s.measure and {key=s.measure.key,seconds=now-s.measure.at} or nil
            s.measure=nil;s.flightSeen=nil;s.leg=s.leg+1;s.state="walking";s.message=nil;s.previous=nil;return sample
        elseif not onTaxi then
            s.state="awaiting_flight";s.message=offer and "Select the shown flight in the taxi window" or "Open this flight master to check availability"
        end
        return
    end
    if onTaxi then s.state="unavailable";s.message="Unexpected flight; recalculate after landing";s.measure=nil;return end
    if p.map~=e.finish.map then s.state="unavailable";s.message="Map changed; recalculate";return end
    if s.previous and s.previousTime and now-s.previousTime<2 and (M.Distance(s.previous,p) or 0)>250 then
        s.state="unavailable";s.message="Position changed; recalculate";return
    end
    s.previous=M.Copy(p);s.previousTime=now
    local distance=M.Distance(p,e.finish)
    if distance and distance<=20 and M.SameFloor(p,e.finish) then
        s.dwell=s.dwell or now
        if now-s.dwell>=1.5 then
            s.dwell=nil
            if s.leg==#s.route.legs then
                -- Last-known, imported, or mobile NPCs require explicit confirmation.
                if s.route.destination.confidence=="observed" and not s.route.destination.mobile then s.state="arrived" else s.state="nearby";s.message="Nearby: confirm the NPC / floor" end
            else s.leg=s.leg+1;s.state="walking" end
        end
    else
        if s.state=="nearby" then s.message=nil end
        s.dwell=nil;s.state="walking"
    end
end
function V.Remaining(s,p,speed,now)
    if not s.route then return nil end
    local distance,seconds=0,0
    for i=s.leg,#s.route.legs do
        local e=s.route.legs[i];local d=e.distance
        if i==s.leg and e.mode=="walk" then d=M.Distance(p,e.finish) or d end
        distance=distance+d
        if e.mode=="flight" then
            local duration=e.seconds or d/32
            if i==s.leg and s.measure then duration=math.max(0,duration-(now-s.measure.at)) end
            seconds=seconds+duration
        else seconds=seconds+M.GroundSeconds(d,speed,e.quality) end
    end
    return distance,seconds
end
