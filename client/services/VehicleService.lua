--- VehicleService (client) - receives the server's fully-resolved "apply
--- state" broadcast for a freshly-spawned vehicle and applies it to the
--- local entity once it has actually streamed in for this client. Contains
--- no ORM references (Vehicle/BaseVehicle/QueryBuilder do not exist in the
--- client Lua VM); all data needed is already resolved server-side.
VehicleService = {}

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

Obelisk.onClient('vehicles:server:apply-state', function(netId, state, mergedHandling, tunings)
    waitForEntity(netId, function(entity)
        SetVehicleEngineOn(entity, state.engineOn, true, false)
        SetVehicleDoorsLocked(entity, state.allDoorsLocked and 2 or 1)
        SetVehicleEngineHealth(entity, state.engineHealth)
        SetVehicleBodyHealth(entity, state.bodyHealth)

        VehicleHandling.applyMerged(entity, mergedHandling)

        for _, tuning in ipairs(tunings) do
            if tuning.value ~= nil then
                VehicleTuningService.apply(entity, tuning.key, tuning.value)
            else
                print('[VehicleService] WARNING: skipping tuning "' .. tostring(tuning.key) .. '" with unparseable/nil value')
            end
        end
    end)
end)

return VehicleService
