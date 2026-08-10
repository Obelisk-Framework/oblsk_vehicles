--- VehicleService (server) - simple spawn-on-demand vehicle creation.
VehicleService = {}
VehicleService.activeNetIds = {} -- vehicleId -> netId, runtime only, never persisted

--- @param vehicleId number
--- @param coords table { x, y, z, heading }
function VehicleService.spawn(vehicleId, coords)
    local vehicle = Vehicle:findSync(vehicleId)
    if not vehicle then
        print('[VehicleService] Error: vehicle #' .. vehicleId .. ' not found')
        return
    end

    local baseVehicle = BaseVehicle:findSync(vehicle.attributes.base_vehicle_id)
    if not baseVehicle then
        print('[VehicleService] Error: base_vehicle #' .. vehicle.attributes.base_vehicle_id .. ' not found')
        return
    end

    CreateVehicleServerSetter(baseVehicle.attributes.model, 'automobile', coords.x, coords.y, coords.z, coords.heading or 0.0, function(entity)
        local netId = NetworkGetNetworkIdFromEntity(entity)
        VehicleService.activeNetIds[vehicleId] = netId

        Obelisk.emitClient('vehicles:server:apply-state', -1, netId, vehicleId, baseVehicle.attributes.id)
    end)
end

return VehicleService
