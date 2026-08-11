--- Migration: Add instance + garage fields to vehicles table
---
--- `garage_id` is a plain nullable integer here, NOT a foreign key: the
--- `garages` table is owned by the `oblsk_garage` plugin, and bootstrap.lua
--- runs every module's migrations before any plugin's, so `garages` does not
--- exist yet at this point. `oblsk_garage` adds the FK constraint itself in
--- its own migration (2026_08_12_060200_add_garage_fk_to_vehicles_table),
--- which keeps this core module fully standalone.
return {
    up = function()
        Schema.table('vehicles', function(table)
            table:string('plate', 12):unique()
            table:string('display_name', 100):nullable()
            table:float('fuel_level'):default(100)
            table:boolean('stored'):default(1)
            table:integer('garage_id'):nullable()
            table:boolean('favorite'):default(0)
        end)

        print('[Migration] Added instance and garage fields to vehicles table')
    end,

    down = function()
        -- Blueprint has no instance-level dropColumn; the API is the static
        -- Schema.dropColumn(table, column), one call per column.
        Schema.dropColumn('vehicles', 'plate')
        Schema.dropColumn('vehicles', 'display_name')
        Schema.dropColumn('vehicles', 'fuel_level')
        Schema.dropColumn('vehicles', 'stored')
        Schema.dropColumn('vehicles', 'garage_id')
        Schema.dropColumn('vehicles', 'favorite')

        print('[Migration] Dropped instance and garage fields from vehicles table')
    end
}
