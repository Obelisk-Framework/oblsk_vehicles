--- Migration: Create base_vehicles table
return {
    up = function()
        Schema.create('base_vehicles', function(table)
            table:id()
            table:string('model', 100):unique()
            table:string('name', 255)
            table:boolean('has_trunk'):default(0):nullable()
            table:float('trunk_size'):nullable()
            table:integer('trunk_slots'):nullable()
            table:boolean('has_glove_compartment'):default(0):nullable()
            table:float('glove_compartment_size'):nullable()
            table:integer('glove_compartment_slots'):nullable()
            table:integer('fuel_type_id'):nullable()
            table:float('tank_size'):nullable()
            table:float('fuel_consumption_rate'):nullable()
            table:integer('seats'):default(4)
            table:timestamps()

            table:foreign('fuel_type_id'):references('id'):on('fuel_types'):onDelete('RESTRICT')
        end)

        print('[Migration] Created base_vehicles table')
    end,

    down = function()
        Schema.drop('base_vehicles')
        print('[Migration] Dropped base_vehicles table')
    end
}
