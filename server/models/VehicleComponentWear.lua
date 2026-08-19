VehicleComponentWear = BaseModel:extend('vehicle_component_wear')

VehicleComponentWear.primaryKey = 'id'
VehicleComponentWear.timestamps = true
VehicleComponentWear.fillable = { 'vehicle_id', 'key', 'value' }

function VehicleComponentWear.relations:vehicle()
    return self:belongsTo(Vehicle, 'vehicle_id', 'id')
end

return VehicleComponentWear
