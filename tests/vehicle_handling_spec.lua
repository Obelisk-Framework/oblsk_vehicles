--- Unit tests for VehicleHandling.mergeRows (base defaults + overrides) and
--- VehicleHandling.applyMerged (int/float native dispatch on an
--- already-merged map). Run from the repository root:
--- lua5.4 tests/vehicle_handling_spec.lua

local scriptDir = arg[0]:match('(.*/)') or './'

dofile(scriptDir .. '../shared/services/VehicleHandling.lua')

local tests, failures, passed = {}, {}, 0
local function test(name, fn) tests[#tests + 1] = {name = name, fn = fn} end

local function eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format('%s\n     expected: %s\n     actual:   %s',
            msg or 'assertion failed', tostring(expected), tostring(actual)), 2)
    end
end

test('mergeRows: a base row applies when there is no override', function()
    local merged = VehicleHandling.mergeRows(
        { { field = 'fMass', value = 1500.0 } },
        {}
    )
    eq(merged.fMass, 1500.0)
end)

test('mergeRows: an override row wins over the base default', function()
    local merged = VehicleHandling.mergeRows(
        { { field = 'fMass', value = 1500.0 } },
        { { field = 'fMass', value = 2000.0 } }
    )
    eq(merged.fMass, 2000.0)
end)

test('mergeRows: an empty base and empty override merge to an empty table', function()
    local merged = VehicleHandling.mergeRows({}, {})
    eq(next(merged), nil)
end)

test('applyMerged: a float-typed field calls SetVehicleHandlingFloat', function()
    local captured
    _G.SetVehicleHandlingFloat = function(entity, class, field, value) captured = {entity, class, field, value} end
    _G.SetVehicleHandlingInt = function() error('should not be called for a float field') end

    VehicleHandling.applyMerged(1, { fMass = 1500.0 })

    eq(captured[1], 1)
    eq(captured[3], 'fMass')
    eq(captured[4], 1500.0)
end)

test('applyMerged: an int-typed field calls SetVehicleHandlingInt, not Float', function()
    local floatCalled, intCalled = false, false
    _G.SetVehicleHandlingFloat = function() floatCalled = true end
    _G.SetVehicleHandlingInt = function() intCalled = true end

    VehicleHandling.applyMerged(1, { nInitialDriveGears = 6 })

    eq(floatCalled, false)
    eq(intCalled, true)
end)

test('applyMerged: an empty map calls no natives', function()
    local called = false
    _G.SetVehicleHandlingFloat = function() called = true end
    _G.SetVehicleHandlingInt = function() called = true end

    VehicleHandling.applyMerged(1, {})

    eq(called, false)
end)

print('Running VehicleHandling unit tests\n')
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
