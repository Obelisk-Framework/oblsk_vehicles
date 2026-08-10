--- VehicleTuningService (client) - a registry mapping a tuning key to the
--- specific native call needed to apply it. vehicle_tunings rows only ever
--- store {key, value}; this registry is the single place that knows which
--- native each key maps to. See docs/superpowers/specs/2026-08-10-vehicle-module-design.md.
VehicleTuningService = {}
VehicleTuningService.registry = {}

--- @param key string
--- @param handlers table { apply = function(entity, value) }
function VehicleTuningService.register(key, handlers)
    VehicleTuningService.registry[key] = handlers
end

--- @param entity number Vehicle entity handle
--- @param key string
--- @param value any Already-decoded (not a JSON string)
function VehicleTuningService.apply(entity, key, value)
    local handlers = VehicleTuningService.registry[key]
    if not handlers then
        print('[VehicleTuningService] WARNING: no handler registered for tuning key "' .. key .. '", skipping')
        return
    end
    handlers.apply(entity, value)
end

VehicleTuningService.register('primaryColor', {
    apply = function(entity, value)
        SetVehicleCustomPrimaryColour(entity, value.r, value.g, value.b)
    end
})

VehicleTuningService.register('turbo', {
    apply = function(entity, value)
        ToggleVehicleMod(entity, 18, value == true)
    end
})

VehicleTuningService.register('spoiler', {
    apply = function(entity, value)
        SetVehicleMod(entity, 3, value, false)
    end
})

return VehicleTuningService
