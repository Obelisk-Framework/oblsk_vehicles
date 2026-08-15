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
        fuelLevel = vehicle.attributes.fuel_level,
        plate = vehicle.attributes.plate,
    }

    CreateVehicleServerSetter(baseVehicle.attributes.model, 'automobile', coords.x, coords.y, coords.z, coords.heading or 0.0, function(entity)
        local netId = NetworkGetNetworkIdFromEntity(entity)
        VehicleService.activeNetIds[vehicleId] = netId

        Obelisk.emitClient('vehicles:server:apply-state', -1, netId, state, mergedHandling, tunings)
    end)
end

--- Reverse lookup of activeNetIds — small map (one entry per currently
--- spawned Obelisk vehicle), a linear scan is fine.
--- @param netId number
--- @return number|nil vehicleId
function VehicleService.findVehicleIdByNetId(netId)
    for vehicleId, id in pairs(VehicleService.activeNetIds) do
        if id == netId then return vehicleId end
    end
    return nil
end

--- @return table[] every vehicle row with its base model's model/name, plus net_id if currently spawned
function VehicleService.listAll()
    local vehicles = QueryBuilder.new('vehicles'):getSync()
    local baseById = {}
    for _, base in ipairs(QueryBuilder.new('base_vehicles'):getSync()) do
        baseById[base.id] = base
    end

    for _, vehicle in ipairs(vehicles) do
        local base = baseById[vehicle.base_vehicle_id]
        vehicle.model = base and base.model or nil
        vehicle.name = base and base.name or nil
        vehicle.net_id = VehicleService.activeNetIds[vehicle.id]
    end

    return vehicles
end

--- Despawns the vehicle if currently spawned, then deletes its row.
--- @param vehicleId number
--- @return boolean
function VehicleService.deleteById(vehicleId)
    local netId = VehicleService.activeNetIds[vehicleId]
    if netId then
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        VehicleService.activeNetIds[vehicleId] = nil
    end

    QueryBuilder.new('vehicles'):where('id', vehicleId):delete()
    return true
end

--- Moves a currently-spawned vehicle to the given coords. No-ops (with a
--- reason) if the vehicle isn't spawned — spawning one just to move it is
--- Garage-tab territory, not this slice.
--- @param vehicleId number
--- @param coords table { x, y, z }
--- @return boolean, string|nil reason
function VehicleService.teleportToCoords(vehicleId, coords)
    local netId = VehicleService.activeNetIds[vehicleId]
    if not netId then
        return false, 'Vehicle is not currently spawned'
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    SetEntityCoords(entity, coords.x, coords.y, coords.z)
    return true
end

return VehicleService
