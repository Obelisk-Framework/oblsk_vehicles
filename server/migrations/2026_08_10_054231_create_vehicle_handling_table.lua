--- Migration: Create vehicle_handling table
return {
    up = function()
        Schema.create('vehicle_handling', function(table)
            table:id()
            table:string('owner_type', 50)
            table:integer('owner_id')
            table:string('field', 100)
            table:float('value')
            table:timestamps()

            table:unique({'owner_type', 'owner_id', 'field'})
        end)

        print('[Migration] Created vehicle_handling table')
    end,

    down = function()
        Schema.drop('vehicle_handling')
        print('[Migration] Dropped vehicle_handling table')
    end
}
