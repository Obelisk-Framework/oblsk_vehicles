--- VehicleHandlingService (shared) - pure handling-map merge logic and the
--- int/float field-type lookup. No DB access, no natives: the server calls
--- mergeRows() with rows it already queried itself; the client calls
--- applyMerged() with the map the server sent over the network. Neither
--- function touches anything that only exists in one Lua VM.
VehicleHandlingService = {}

--- Which handling.meta fields are natively integers vs floats. Not
--- exhaustive (GTA's handling.meta has ~90 fields); representative subset.
VehicleHandlingService.INT_FIELDS = {
    nInitialDriveGears = true,
    nMonetaryValue = true,
}

--- Merges base_vehicle-level default rows with vehicle-level override rows
--- (override wins). Pure data in, pure data out; no DB access.
--- @param baseRows table[] rows with .field and .value
--- @param overrideRows table[] rows with .field and .value
--- @return table field -> value
function VehicleHandlingService.mergeRows(baseRows, overrideRows)
    local merged = {}
    for _, row in ipairs(baseRows) do
        merged[row.field] = row.value
    end
    for _, row in ipairs(overrideRows) do
        merged[row.field] = row.value
    end
    return merged
end

--- Applies an already-merged field->value map to a live entity via
--- SetVehicleHandlingFloat/Int.
--- @param entity number
--- @param merged table field -> value
function VehicleHandlingService.applyMerged(entity, merged)
    for field, value in pairs(merged) do
        if VehicleHandlingService.INT_FIELDS[field] then
            SetVehicleHandlingInt(entity, 'CHandlingData', field, math.floor(value))
        else
            SetVehicleHandlingFloat(entity, 'CHandlingData', field, value)
        end
    end
end

return VehicleHandlingService
