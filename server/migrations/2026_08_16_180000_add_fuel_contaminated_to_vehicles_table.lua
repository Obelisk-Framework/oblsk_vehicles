--- Migration: Add fuel_contaminated flag to vehicles table
---
--- Set when the wrong fuel type is pumped into a vehicle (see
--- oblsk_gasstation's GasStationService.pump). While true, the vehicle's
--- engine won't stay running (see client VehicleService.lua's stall loop)
--- until a mechanic drains the tank (oblsk_mechanic's MechanicService.drainTank
--- clears this back to false).
return {
    up = function()
        Schema.table('vehicles', function(table)
            table:boolean('fuel_contaminated'):default(0):nullable()
        end)

        print('[Migration] Added fuel_contaminated to vehicles table')
    end,

    down = function()
        Schema.dropColumn('vehicles', 'fuel_contaminated')
        print('[Migration] Dropped fuel_contaminated from vehicles table')
    end
}
