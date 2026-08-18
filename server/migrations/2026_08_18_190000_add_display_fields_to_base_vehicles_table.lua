--- Migration: Add make/class/image_url display fields to base_vehicles
---
--- Previously denormalized per-plugin (e.g. oblsk_cardealer's
--- cardealer_listings.make/class), duplicated per listing. Centralized here
--- so any plugin (garage, cardealer, ...) can read the same catalog-level
--- display data off the shared base_vehicles row.
return {
    up = function()
        Schema.table('base_vehicles', function(table)
            table:string('make', 60):nullable()
            table:string('class', 30):nullable()
            table:string('image_url', 255):nullable()
        end)

        print('[Migration] Added make/class/image_url to base_vehicles table')
    end,

    down = function()
        Schema.dropColumn('base_vehicles', 'make')
        Schema.dropColumn('base_vehicles', 'class')
        Schema.dropColumn('base_vehicles', 'image_url')

        print('[Migration] Dropped make/class/image_url from base_vehicles table')
    end
}
