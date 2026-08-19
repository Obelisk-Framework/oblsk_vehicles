VehicleTuning = BaseModel:extend('vehicle_tunings')

VehicleTuning.primaryKey = 'id'
VehicleTuning.timestamps = true
VehicleTuning.fillable = { 'vehicle_id', 'key', 'value' }

function VehicleTuning.relations:vehicle()
    return self:belongsTo(Vehicle, 'vehicle_id', 'id')
end

return VehicleTuning
