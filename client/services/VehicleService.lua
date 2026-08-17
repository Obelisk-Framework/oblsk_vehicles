--- VehicleService (client) - receives the server's fully-resolved "apply
--- state" broadcast for a freshly-spawned vehicle and applies it to the
--- local entity once it has actually streamed in for this client. Contains
--- no ORM references (Vehicle/BaseVehicle/QueryBuilder do not exist in the
--- client Lua VM); all data needed is already resolved server-side.
VehicleService = {}

--- netId -> true while a "fuel contaminated" stall loop is active for that
--- vehicle. Keyed by netId (not entity) since the loop is started/stopped
--- from server broadcasts that only carry netId, and an entity handle can
--- go stale across streaming; the loop itself re-resolves the entity each
--- poll and simply stops once the flag is cleared.
local stallLoops = {}

--- Simple polling stall: while `stallLoops[netId]` stays true, force the
--- engine back off shortly after any start attempt. No state machine -
--- just "can't stay running", checked every 250-500ms.
local function startStallLoop(netId)
    if stallLoops[netId] then return end -- already running, don't stack threads
    stallLoops[netId] = true

    Citizen.CreateThread(function()
        while stallLoops[netId] do
            Citizen.Wait(300)
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity ~= 0 and DoesEntityExist(entity) and GetIsVehicleEngineRunning(entity) then
                SetVehicleEngineOn(entity, false, true, true)
            end
        end
    end)
end

local function stopStallLoop(netId)
    stallLoops[netId] = nil
end

local function waitForEntity(netId, callback, attemptsLeft)
    attemptsLeft = attemptsLeft or 20
    if NetworkDoesNetworkIdExist(netId) then
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity ~= 0 then
            callback(entity)
            return
        end
    end
    if attemptsLeft <= 0 then
        print('[VehicleService] WARNING: gave up waiting for netId ' .. tostring(netId) .. ' to stream in')
        return
    end
    Citizen.SetTimeout(250, function()
        waitForEntity(netId, callback, attemptsLeft - 1)
    end)
end

Obelisk.onServer('vehicles:server:apply-state', function(netId, state, mergedHandling, tunings)
    waitForEntity(netId, function(entity)
        SetVehicleEngineOn(entity, state.engineOn, true, false)
        SetVehicleDoorsLocked(entity, state.allDoorsLocked and 2 or 1)
        SetVehicleEngineHealth(entity, state.engineHealth)
        SetVehicleBodyHealth(entity, state.bodyHealth)
        if state.fuelLevel then
            SetVehicleFuelLevel(entity, state.fuelLevel + 0.0)
        end
        if state.plate then
            SetVehicleNumberPlateText(entity, state.plate)
        end

        VehicleHandling.applyMerged(entity, mergedHandling)

        for _, tuning in ipairs(tunings) do
            if tuning.value ~= nil then
                VehicleTuningService.apply(entity, tuning.key, tuning.value)
            else
                print('[VehicleService] WARNING: skipping tuning "' .. tostring(tuning.key) .. '" with unparseable/nil value')
            end
        end

        if state.fuelContaminated then
            startStallLoop(netId)
        else
            stopStallLoop(netId)
        end
    end)
end)

--- Live push from VehicleService.setFuelContaminated (server) - starts or
--- stops the stall loop immediately without waiting for a fresh apply-state.
Obelisk.onServer('vehicles:server:setContaminated', function(netId, contaminated)
    if contaminated then
        startStallLoop(netId)
    else
        stopStallLoop(netId)
    end
end)

return VehicleService
