--- Migration: Add instance + garage fields to vehicles table
return {
    up = function()
        Schema.table('vehicles', function(table)
            table:string('plate', 12):unique()
            table:string('display_name', 100):nullable()
            table:float('fuel_level'):default(100)
            table:boolean('stored'):default(1)
            table:foreignId('garage_id'):constrained('garages'):onDelete('SET NULL')
            table:boolean('favorite'):default(0)
        end)

        print('[Migration] Added instance and garage fields to vehicles table')
    end,

    down = function()
        Schema.table('vehicles', function(table)
            table:dropColumn('plate')
            table:dropColumn('display_name')
            table:dropColumn('fuel_level')
            table:dropColumn('stored')
            table:dropColumn('garage_id')
            table:dropColumn('favorite')
        end)

        print('[Migration] Dropped instance and garage fields from vehicles table')
    end
}
