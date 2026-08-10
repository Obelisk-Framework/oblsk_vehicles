--- Migration: Create vehicles table
return {
    up = function()
        Schema.create('vehicles', function(table)
            table:id()
            table:integer('base_vehicle_id'):notNullable()
            table:string('key', 36)
            table:string('owner_type', 50):notNullable()
            table:integer('owner_id'):notNullable()
            table:boolean('engine_on'):default(0)
            table:boolean('backdoor_locked'):default(0)
            table:boolean('alldoors_locked'):default(0)
            table:float('engine_health'):default(1000)
            table:float('body_health'):default(1000)
            table:json('body_damage')
            table:timestamps()

            table:index({'owner_type', 'owner_id'})
            table:foreign('base_vehicle_id'):references('id'):on('base_vehicles'):onDelete('RESTRICT')
        end)

        print('[Migration] Created vehicles table')
    end,

    down = function()
        Schema.drop('vehicles')
        print('[Migration] Dropped vehicles table')
    end
}
