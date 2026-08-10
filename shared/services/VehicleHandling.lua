--- VehicleHandling (shared) - handling merge/apply. Lives in shared/, not
--- server/services/, because both the server (Task 5's spawn path) and the
--- client (Task 5's apply-state handler) need to call this, and
--- client_scripts/server_scripts run in separate Lua VMs in FXServer, a
--- server-only global would be invisible to client code.
VehicleHandling = {}

--- Which handling.meta fields are natively integers vs floats. Not
--- exhaustive (GTA's handling.meta has ~90 fields); this is a
--- representative subset establishing the pattern. Extend as needed.
local HANDLING_INT_FIELDS = {
    nInitialDriveGears = true,
    nMonetaryValue = true,
}

--- Reads base_vehicle-level defaults and vehicle-level overrides, merges
--- them (instance wins), and applies the result to a live entity via
--- SetVehicleHandlingFloat/Int.
--- @param entity number
--- @param baseVehicleId number
--- @param vehicleId number
function VehicleHandling.applyHandling(entity, baseVehicleId, vehicleId)
    local merged = {}

    local baseRows = QueryBuilder.new('vehicle_handling')
        :where('owner_type', 'base_vehicle'):where('owner_id', baseVehicleId):getSync()
    for _, row in ipairs(baseRows) do
        merged[row.field] = row.value
    end

    local overrideRows = QueryBuilder.new('vehicle_handling')
        :where('owner_type', 'vehicle'):where('owner_id', vehicleId):getSync()
    for _, row in ipairs(overrideRows) do
        merged[row.field] = row.value
    end

    for field, value in pairs(merged) do
        if HANDLING_INT_FIELDS[field] then
            SetVehicleHandlingInt(entity, 'CHandlingData', field, math.floor(value))
        else
            SetVehicleHandlingFloat(entity, 'CHandlingData', field, value)
        end
    end
end

return VehicleHandling
