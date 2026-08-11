--- Vehicle Model - a single owned instance of a BaseVehicle. Ownership is
--- polymorphic: owner_type is an open string ('character', more later),
--- owner_id points at whatever that type's table primary key is. No FK
--- constraint on owner_id since the target table varies (same convention
--- as the Item module's items.owner_type/owner_id).
Vehicle = BaseModel:extend('vehicles')

Vehicle.primaryKey = 'id'
Vehicle.timestamps = true

Vehicle.fillable = {
    'base_vehicle_id', 'key', 'owner_type', 'owner_id',
    'engine_on', 'backdoor_locked', 'alldoors_locked',
    'engine_health', 'body_health', 'body_damage',
    'plate', 'display_name', 'fuel_level', 'stored', 'garage_id', 'favorite',
}

Vehicle.hidden = {}

Vehicle.casts = {
    body_damage = 'json',
}

function Vehicle:baseVehicleRelation()
    return self:belongsTo(BaseVehicle, 'base_vehicle_id', 'id')
end

return Vehicle
