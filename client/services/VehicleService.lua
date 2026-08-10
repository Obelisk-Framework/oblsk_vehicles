--- VehicleService (client) - receives the server's "apply state" broadcast
--- for a freshly-spawned vehicle and applies engine/lock/health/handling/
--- tuning state to the local entity, once it's actually streamed in for
--- this client.
VehicleService = {}

Obelisk.onClient('vehicles:server:apply-state', function(netId, vehicleId, baseVehicleId)
    if not NetworkDoesNetworkIdExist(netId) then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 then return end

    local vehicle = Vehicle:findSync(vehicleId)
    local baseVehicle = BaseVehicle:findSync(baseVehicleId)
    if not vehicle or not baseVehicle then return end

    SetVehicleEngineOn(entity, vehicle.attributes.engine_on == true, true, false)
    SetVehicleDoorsLocked(entity, vehicle.attributes.alldoors_locked and 2 or 1)
    SetVehicleEngineHealth(entity, vehicle.attributes.engine_health)
    SetVehicleBodyHealth(entity, vehicle.attributes.body_health)

    VehicleHandling.applyHandling(entity, baseVehicleId, vehicleId)

    for _, row in ipairs(QueryBuilder.new('vehicle_tunings'):where('vehicle_id', vehicleId):getSync()) do
        local ok, value = pcall(json.decode, row.value)
        VehicleTuningService.apply(entity, row.key, ok and value or nil)
    end
end)

return VehicleService
