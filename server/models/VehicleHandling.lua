--- VehicleHandling Model - polymorphic override rows (owner_type/owner_id)
--- for a base_vehicle's or vehicle's handling fields. See
--- shared/services/VehicleHandlingService.lua for the merge/apply logic that
--- consumes rows fetched through this model.
VehicleHandling = BaseModel:extend('vehicle_handling')

VehicleHandling.primaryKey = 'id'
VehicleHandling.timestamps = true

VehicleHandling.fillable = {
    'owner_type', 'owner_id', 'field', 'value',
}

VehicleHandling.hidden = {}

return VehicleHandling
