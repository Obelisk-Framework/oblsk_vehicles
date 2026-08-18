--- BaseVehicle Model - the vehicle catalog/template. One row per vehicle
--- model (e.g. 'sultan'). See tests/vehicle_handling_spec.lua and
--- tests/vehicle_tuning_spec.lua for how base_vehicle_id-scoped rows in
--- vehicle_handling relate to this table.
BaseVehicle = BaseModel:extend('base_vehicles')

BaseVehicle.primaryKey = 'id'
BaseVehicle.timestamps = true

BaseVehicle.fillable = {
    'model', 'name', 'make', 'class', 'image_url',
    'has_trunk', 'trunk_size', 'trunk_slots',
    'has_glove_compartment', 'glove_compartment_size', 'glove_compartment_slots',
    'fuel_type_id', 'tank_size', 'fuel_consumption_rate',
    'seats',
}

BaseVehicle.hidden = {}

function BaseVehicle:fuelType()
    return self:belongsTo(FuelType, 'fuel_type_id', 'id')
end

function BaseVehicle:vehicleHandlings()
    return self:morphMany(VehicleHandling)
end

return BaseVehicle
