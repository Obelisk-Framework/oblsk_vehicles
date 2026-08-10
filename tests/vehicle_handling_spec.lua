--- Unit tests for VehicleHandling.applyHandling's merge logic (base_vehicle
--- defaults + vehicle overrides, override wins) and the int/float native
--- dispatch. Run from the repository root:
--- lua5.4 tests/vehicle_handling_spec.lua
---
--- Loads core's ORM (Database/QueryBuilder) standalone, the same way
--- core's own tests/orm_spec.lua does, to fake vehicle_handling query
--- results without a real database.

local scriptDir = arg[0]:match('(.*/)') or './'
local CORE_ROOT = scriptDir .. '../../..'

dofile(CORE_ROOT .. '/tests/support/fivem_stubs.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Dialects/Init.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Dialects/MySQL.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Dialects/Postgres.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Database.lua')
dofile(CORE_ROOT .. '/core/server/ORM/QueryBuilder.lua')
dofile(scriptDir .. '../shared/services/VehicleHandling.lua')

local tests, failures, passed = {}, {}, 0
local function test(name, fn) tests[#tests + 1] = {name = name, fn = fn} end

local function eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format('%s\n     expected: %s\n     actual:   %s',
            msg or 'assertion failed', tostring(expected), tostring(actual)), 2)
    end
end

--- Fakes vehicle_handling as an in-memory list, filtered the same way the
--- real WHERE clauses would filter it.
local function withFakeHandlingRows(baseRows, overrideRows, fn)
    local original = Database.executeQuery
    Database.executeQuery = function(query, params)
        -- params: [owner_type, owner_id] in that order, per QueryBuilder's
        -- :where('owner_type', ...):where('owner_id', ...) chain.
        local ownerType, ownerId = params[1], params[2]
        local rows = (ownerType == 'base_vehicle') and baseRows or overrideRows
        local matching = {}
        for _, row in ipairs(rows) do
            if row.owner_id == ownerId then
                table.insert(matching, row)
            end
        end
        return matching
    end

    local ok, err = pcall(fn)
    Database.executeQuery = original
    if not ok then error(err, 2) end
end

test('applyHandling: base_vehicle defaults apply when there is no override', function()
    local captured = {}
    _G.SetVehicleHandlingFloat = function(entity, class, field, value) captured[field] = value end
    _G.SetVehicleHandlingInt = function(entity, class, field, value) captured[field] = value end

    withFakeHandlingRows(
        { { owner_id = 5, field = 'fMass', value = 1500.0 } },
        {},
        function()
            VehicleHandling.applyHandling(1, 5, 99)
        end
    )

    eq(captured.fMass, 1500.0)
end)

test('applyHandling: a vehicle-level override wins over the base_vehicle default', function()
    local captured = {}
    _G.SetVehicleHandlingFloat = function(entity, class, field, value) captured[field] = value end
    _G.SetVehicleHandlingInt = function(entity, class, field, value) captured[field] = value end

    withFakeHandlingRows(
        { { owner_id = 5, field = 'fMass', value = 1500.0 } },
        { { owner_id = 99, field = 'fMass', value = 2000.0 } },
        function()
            VehicleHandling.applyHandling(1, 5, 99)
        end
    )

    eq(captured.fMass, 2000.0)
end)

test('applyHandling: an int-typed field calls SetVehicleHandlingInt, not Float', function()
    local floatCalled, intCalled = false, false
    _G.SetVehicleHandlingFloat = function() floatCalled = true end
    _G.SetVehicleHandlingInt = function() intCalled = true end

    withFakeHandlingRows(
        { { owner_id = 5, field = 'nInitialDriveGears', value = 6 } },
        {},
        function()
            VehicleHandling.applyHandling(1, 5, 99)
        end
    )

    eq(floatCalled, false)
    eq(intCalled, true)
end)

--------------------------------------------------------------------------------
-- Runner
--------------------------------------------------------------------------------
print('Running VehicleHandling.applyHandling unit tests\n')
for _, t in ipairs(tests) do
    local ok, err = pcall(t.fn)
    if ok then
        passed = passed + 1
        print('  ok   - ' .. t.name)
    else
        failures[#failures + 1] = t.name
        print('  FAIL - ' .. t.name)
        print('         ' .. tostring(err):gsub('\n', '\n         '))
    end
end

print(string.format('\n%d passed, %d failed', passed, #failures))
os.exit(#failures == 0 and 0 or 1)
