--- FuelType Model - a simple lookup table (petrol, diesel, electric, etc.)
FuelType = BaseModel:extend('fuel_types')

FuelType.primaryKey = 'id'
FuelType.timestamps = true

FuelType.fillable = { 'name' }

FuelType.hidden = {}

return FuelType
