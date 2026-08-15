-- core/modules/oblsk_vehicles/tests/vehicle_service_admin_spec.lua
-- Run from the repository root:  lua5.4 modules/oblsk_vehicles/tests/vehicle_service_admin_spec.lua
local scriptDir = arg[0]:match('(.*/)') or './'
local CORE_ROOT = scriptDir .. '../../..'

dofile(CORE_ROOT .. '/tests/support/fivem_stubs.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Dialects/Init.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Dialects/MySQL.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Dialects/Postgres.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Database.lua')
dofile(CORE_ROOT .. '/core/server/ORM/QueryBuilder.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Schema.lua')
dofile(CORE_ROOT .. '/core/server/ORM/BaseModel.lua')
dofile(scriptDir .. '../server/models/Vehicle.lua')
dofile(scriptDir .. '../server/models/BaseVehicle.lua')
dofile(scriptDir .. '../server/services/VehicleService.lua')

local makeFakeQueryBuilderModule = dofile(scriptDir .. 'support/fake_query_builder.lua')

local tests, failures, passed = {}, {}, 0
local function test(name, fn) tests[#tests + 1] = {name = name, fn = fn} end
local function eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format('%s\n     expected: %s\n     actual:   %s', msg or 'assertion failed', tostring(expected), tostring(actual)), 2)
    end
end
local function truthy(v, msg) if not v then error(msg or 'expected truthy', 2) end end

local function withFakeDb(fn)
    local tables = {}
    local original = QueryBuilder
    QueryBuilder = makeFakeQueryBuilderModule(tables)
    local ok, err = pcall(fn, tables)
    QueryBuilder = original
    if not ok then error(err, 2) end
end

-- FXServer network natives, stubbed for the deleteById/teleportToCoords paths.
local deletedEntities, movedEntities = {}, {}
function NetworkGetEntityFromNetworkId(netId) return 'entity:' .. netId end
function DeleteEntity(entity) deletedEntities[#deletedEntities + 1] = entity end
function SetEntityCoords(entity, x, y, z) movedEntities[#movedEntities + 1] = { entity = entity, x = x, y = y, z = z } end
function DoesEntityExist(entity) return true end

--------------------------------------------------------------------------------
-- listAll
--------------------------------------------------------------------------------

test('listAll: joins base_vehicles for model/name and flags spawned vehicles', function()
    withFakeDb(function(tables)
        tables.base_vehicles = { { id = 5, model = 'sultan', name = 'Sultan' } }
        tables.vehicles = { { id = 1, base_vehicle_id = 5, plate = 'ABC123', display_name = nil, owner_type = 'character', owner_id = 10, stored = 1, garage_id = 2, fuel_level = 80 } }
        VehicleService.activeNetIds = { [1] = 999 }

        local rows = VehicleService.listAll()
        eq(#rows, 1)
        eq(rows[1].model, 'sultan')
        eq(rows[1].name, 'Sultan')
        eq(rows[1].net_id, 999)
    end)
end)

test('listAll: net_id is nil for a vehicle not currently spawned', function()
    withFakeDb(function(tables)
        tables.base_vehicles = { { id = 5, model = 'sultan', name = 'Sultan' } }
        tables.vehicles = { { id = 2, base_vehicle_id = 5, owner_type = 'character', owner_id = 10 } }
        VehicleService.activeNetIds = {}

        local rows = VehicleService.listAll()
        eq(rows[1].net_id, nil)
    end)
end)

--------------------------------------------------------------------------------
-- deleteById
--------------------------------------------------------------------------------

test('deleteById: despawns then deletes the row when spawned', function()
    withFakeDb(function(tables)
        tables.vehicles = { { id = 1 } }
        VehicleService.activeNetIds = { [1] = 999 }
        deletedEntities = {}

        local ok = VehicleService.deleteById(1)
        truthy(ok)
        eq(#deletedEntities, 1)
        eq(#tables.vehicles, 0)
    end)
end)

test('deleteById: deletes the row without despawning when not spawned', function()
    withFakeDb(function(tables)
        tables.vehicles = { { id = 3 } }
        VehicleService.activeNetIds = {}
        deletedEntities = {}

        local ok = VehicleService.deleteById(3)
        truthy(ok)
        eq(#deletedEntities, 0)
        eq(#tables.vehicles, 0)
    end)
end)

--------------------------------------------------------------------------------
-- teleportToCoords
--------------------------------------------------------------------------------

test('teleportToCoords: moves a spawned vehicle', function()
    VehicleService.activeNetIds = { [1] = 999 }
    movedEntities = {}

    local ok = VehicleService.teleportToCoords(1, { x = 1, y = 2, z = 3 })
    truthy(ok)
    eq(#movedEntities, 1)
end)

test('teleportToCoords: fails with a reason when the vehicle is not spawned', function()
    VehicleService.activeNetIds = {}
    local ok, reason = VehicleService.teleportToCoords(5, { x = 1, y = 2, z = 3 })
    eq(ok, false)
    truthy(reason ~= nil)
end)

print('Running VehicleService admin unit tests\n')
for _, t in ipairs(tests) do
    local ok, err = pcall(t.fn)
    if ok then passed = passed + 1; print('  ok   - ' .. t.name)
    else failures[#failures + 1] = t.name; print('  FAIL - ' .. t.name); print('         ' .. tostring(err):gsub('\n', '\n         ')) end
end
print(string.format('\n%d passed, %d failed', passed, #failures))
os.exit(#failures == 0 and 0 or 1)
