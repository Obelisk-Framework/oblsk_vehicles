--- Migration: Create fuel_types table
return {
    up = function()
        Schema.create('fuel_types', function(table)
            table:id()
            table:string('name', 100):unique()
            table:timestamps()
        end)

        print('[Migration] Created fuel_types table')
    end,

    down = function()
        Schema.drop('fuel_types')
        print('[Migration] Dropped fuel_types table')
    end
}
