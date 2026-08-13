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
        SetVehicleMod(entity, 0, value, false)
    end
})

VehicleTuningService.register('secondaryColor', {
    apply = function(entity, value)
        SetVehicleCustomSecondaryColour(entity, value.r, value.g, value.b)
    end
})

VehicleTuningService.register('pearlescent', {
    apply = function(entity, value)
        SetVehicleExtraColours(entity, value.pearlescentId, value.wheelId)
    end
})

VehicleTuningService.register('bumperF', {
    apply = function(entity, value) SetVehicleMod(entity, 1, value, false) end
})

VehicleTuningService.register('bumperR', {
    apply = function(entity, value) SetVehicleMod(entity, 2, value, false) end
})

VehicleTuningService.register('skirt', {
    apply = function(entity, value) SetVehicleMod(entity, 3, value, false) end
})

VehicleTuningService.register('exhaust', {
    apply = function(entity, value) SetVehicleMod(entity, 4, value, false) end
})

VehicleTuningService.register('hood', {
    apply = function(entity, value) SetVehicleMod(entity, 7, value, false) end
})

VehicleTuningService.register('roof', {
    apply = function(entity, value) SetVehicleMod(entity, 10, value, false) end
})

VehicleTuningService.register('engine', {
    apply = function(entity, value) SetVehicleMod(entity, 11, value, false) end
})

VehicleTuningService.register('brakes', {
    apply = function(entity, value) SetVehicleMod(entity, 12, value, false) end
})

VehicleTuningService.register('suspension', {
    apply = function(entity, value) SetVehicleMod(entity, 15, value, false) end
})

VehicleTuningService.register('horn', {
    apply = function(entity, value) SetVehicleMod(entity, 14, value, false) end
})

VehicleTuningService.register('wheels', {
    apply = function(entity, value)
        SetVehicleWheelType(entity, value.wheelType)
        SetVehicleMod(entity, 23, value.index, false)
    end
})

VehicleTuningService.register('window', {
    apply = function(entity, value)
        SetVehicleWindowTint(entity, value)
    end
})

VehicleTuningService.register('neon', {
    apply = function(entity, value)
        SetVehicleNeonLightsColour(entity, value.r, value.g, value.b)
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(entity, i, true)
        end
    end
})

VehicleTuningService.register('livery', {
    apply = function(entity, value)
        SetVehicleLivery(entity, value)
    end
})

return VehicleTuningService
