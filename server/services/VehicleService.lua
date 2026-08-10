--- VehicleService (server) - simple spawn-on-demand vehicle creation. Does
--- all database work itself and sends a fully-resolved payload to clients;
--- the client-side VehicleService never touches the ORM (see the design
--- spec's revision note on why: client_scripts/server_scripts are separate
--- Lua VMs, and QueryBuilder/BaseModel only exist server-side).
VehicleService = {}
VehicleService.activeNetIds = {} -- vehicleId -> netId, runtime only, never persisted, never cleaned up (no despawn path exists yet in this module's scope)

--- MySQL/Postgres return boolean columns as 1/0 (or sometimes real
--- true/false depending on driver), never Lua's own `true`/`false`
--- reliably. `1 == true` is `false` in Lua, and `0` is truthy in Lua, so a
--- naive `== true` or plain truthy check on a raw DB value is wrong either
--- way. Normalize explicitly.
local function isTruthyFlag(v)
    return v == true or v == 1 or v == '1'
end

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

    local baseRows = QueryBuilder.new('vehicle_handling')
        :where('owner_type', 'base_vehicle'):where('owner_id', baseVehicle.attributes.id):getSync()
    local overrideRows = QueryBuilder.new('vehicle_handling')
        :where('owner_type', 'vehicle'):where('owner_id', vehicleId):getSync()
    local mergedHandling = VehicleHandling.mergeRows(baseRows, overrideRows)

    local tunings = {}
    for _, row in ipairs(QueryBuilder.new('vehicle_tunings'):where('vehicle_id', vehicleId):getSync()) do
        local ok, decoded = pcall(json.decode, row.value or '')
        local value = nil
        if ok then value = decoded end
        table.insert(tunings, { key = row.key, value = value })
    end

    local state = {
        engineOn = isTruthyFlag(vehicle.attributes.engine_on),
        allDoorsLocked = isTruthyFlag(vehicle.attributes.alldoors_locked),
        engineHealth = vehicle.attributes.engine_health,
        bodyHealth = vehicle.attributes.body_health,
    }

    CreateVehicleServerSetter(baseVehicle.attributes.model, 'automobile', coords.x, coords.y, coords.z, coords.heading or 0.0, function(entity)
        local netId = NetworkGetNetworkIdFromEntity(entity)
        VehicleService.activeNetIds[vehicleId] = netId

        Obelisk.emitClient('vehicles:server:apply-state', -1, netId, state, mergedHandling, tunings)
    end)
end

return VehicleService
