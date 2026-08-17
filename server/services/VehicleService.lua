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
    local vehicle = Vehicle:find(vehicleId)
    if not vehicle then
        print('[VehicleService] Error: vehicle #' .. vehicleId .. ' not found')
        return
    end

    local baseVehicle = BaseVehicle:find(vehicle.attributes.base_vehicle_id)
    if not baseVehicle then
        print('[VehicleService] Error: base_vehicle #' .. vehicle.attributes.base_vehicle_id .. ' not found')
        return
    end

    local baseRows = VehicleHandling
        :where('owner_type', 'base_vehicle'):where('owner_id', baseVehicle.attributes.id):get()
    local overrideRows = VehicleHandling
        :where('owner_type', 'vehicle'):where('owner_id', vehicleId):get()
    local mergedHandling = VehicleHandlingService.mergeRows(baseRows, overrideRows)

    local tunings = {}
    for _, row in ipairs(QueryBuilder.new('vehicle_tunings'):where('vehicle_id', vehicleId):get()) do
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
        fuelContaminated = isTruthyFlag(vehicle.attributes.fuel_contaminated),
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
    local vehicles = QueryBuilder.new('vehicles'):get()
    local baseById = {}
    for _, base in ipairs(QueryBuilder.new('base_vehicles'):get()) do
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

--- Persists the fuel-contaminated flag (set when the wrong fuel type is
--- pumped in, cleared once a mechanic drains the tank -- see
--- oblsk_gasstation/GasStationService.pump and oblsk_mechanic/MechanicService.drainTank)
--- and, if the vehicle is currently spawned, pushes the change live to
--- every client so the stall loop can start/stop immediately instead of
--- waiting for a respawn.
--- @param vehicleId number
--- @param contaminated boolean
function VehicleService.setFuelContaminated(vehicleId, contaminated)
    QueryBuilder.new('vehicles'):where('id', vehicleId):update({ fuel_contaminated = contaminated and 1 or 0 })

    local netId = VehicleService.activeNetIds[vehicleId]
    if netId then
        Obelisk.emitClient('vehicles:server:setContaminated', -1, netId, contaminated)
    end
end

--------------------------------------------------------------------------------
-- base_vehicles catalog admin CRUD (admin panel "Vehicles" tab, catalog view)
--------------------------------------------------------------------------------

--- @return table[] every base_vehicles row, with fuel_type_name resolved from
---   fuel_types (nil when fuel_type_id is null, same as ItemService's
---   base_items/item_bindings join pattern).
function VehicleService.listBaseVehicles()
    local baseVehicles = QueryBuilder.new('base_vehicles'):get()

    local fuelTypesById = {}
    for _, fuelType in ipairs(QueryBuilder.new('fuel_types'):get()) do
        fuelTypesById[fuelType.id] = fuelType
    end

    for _, baseVehicle in ipairs(baseVehicles) do
        local fuelType = baseVehicle.fuel_type_id and fuelTypesById[baseVehicle.fuel_type_id]
        baseVehicle.fuel_type_name = fuelType and fuelType.name or nil
    end

    return baseVehicles
end

--- @param attributes table see BaseVehicle.fillable for accepted keys; `model` is required and must be unique
--- @return number|nil id, string|nil reason
function VehicleService.createBaseVehicle(attributes)
    if not attributes.model or attributes.model == '' then
        return nil, 'Model is required'
    end

    local ok, result = pcall(function() return BaseVehicle:create(attributes) end)
    if not ok then
        return nil, 'Model already in use'
    end

    return result.attributes.id, nil
end

--- Whitelist-updates an existing base vehicle. Unlike ItemService's
--- updateBaseItem, `model` has no lookup-key concern here (nothing keys off
--- of it the way ItemService.binding()/Config.Requires keys off base_items.name),
--- so every fillable field is editable -- kept as an explicit whitelist
--- constant anyway, for consistency with that established convention.
--- @param baseVehicleId number
--- @param attributes table any of BaseVehicle.fillable
--- @return boolean
local EDITABLE_BASE_VEHICLE_FIELDS = {
    'model', 'name',
    'has_trunk', 'trunk_size', 'trunk_slots',
    'has_glove_compartment', 'glove_compartment_size', 'glove_compartment_slots',
    'fuel_type_id', 'tank_size', 'fuel_consumption_rate',
    'seats',
}
function VehicleService.updateBaseVehicle(baseVehicleId, attributes)
    local update = {}
    for _, field in ipairs(EDITABLE_BASE_VEHICLE_FIELDS) do
        if attributes[field] ~= nil then
            update[field] = attributes[field]
        end
    end
    QueryBuilder.new('base_vehicles'):where('id', baseVehicleId):update(update)

    return true
end

--- Refuses to delete a base_vehicle still referenced by an owned `vehicles`
--- row, mirroring ItemService's "refuse if still in use" pattern.
--- @param baseVehicleId number
--- @return boolean, string|nil reason
function VehicleService.deleteBaseVehicle(baseVehicleId)
    local inUse = QueryBuilder.new('vehicles'):where('base_vehicle_id', baseVehicleId):first()
    if inUse then
        return false, 'Vehicle model is still in use by owned vehicles'
    end

    QueryBuilder.new('base_vehicles'):where('id', baseVehicleId):delete()
    return true
end

--- @return table[] every fuel_types row, for the admin UI's fuel-type dropdown.
function VehicleService.listFuelTypesForAdmin()
    return QueryBuilder.new('fuel_types'):get()
end

return VehicleService
