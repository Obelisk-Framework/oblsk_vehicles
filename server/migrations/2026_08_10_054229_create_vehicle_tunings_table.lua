--- Migration: Create vehicle_tunings table
return {
    up = function()
        Schema.create('vehicle_tunings', function(table)
            table:id()
            table:integer('vehicle_id'):notNullable()
            table:string('key', 100):notNullable()
            table:json('value')
            table:timestamps()

            table:unique({'vehicle_id', 'key'})
            table:foreign('vehicle_id'):references('id'):on('vehicles'):onDelete('CASCADE')
        end)

        print('[Migration] Created vehicle_tunings table')
    end,

    down = function()
        Schema.drop('vehicle_tunings')
        print('[Migration] Dropped vehicle_tunings table')
    end
}
