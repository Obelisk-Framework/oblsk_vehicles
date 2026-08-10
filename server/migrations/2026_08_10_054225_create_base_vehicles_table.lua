--- Migration: Create base_vehicles table
return {
    up = function()
        Schema.create('base_vehicles', function(table)
            table:id()
            table:string('model', 100):notNullable():unique()
            table:string('name', 255):notNullable()
            table:boolean('has_trunk'):default(0)
            table:float('trunk_size')
            table:integer('trunk_slots')
            table:boolean('has_glove_compartment'):default(0)
            table:float('glove_compartment_size')
            table:integer('glove_compartment_slots')
            table:integer('fuel_type_id')
            table:float('tank_size')
            table:float('fuel_consumption_rate')
            table:integer('seats'):notNullable():default(4)
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
