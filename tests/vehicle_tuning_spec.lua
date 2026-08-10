--- Unit tests for VehicleTuningService's registry/dispatch logic and its
--- three built-in tuning handlers. Run from the repository root:
--- lua5.4 tests/vehicle_tuning_spec.lua

local scriptDir = arg[0]:match('(.*/)') or './'

dofile(scriptDir .. '../client/services/VehicleTuningService.lua')

local tests, failures, passed = {}, {}, 0
local function test(name, fn) tests[#tests + 1] = {name = name, fn = fn} end

local function eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format('%s\n     expected: %s\n     actual:   %s',
            msg or 'assertion failed', tostring(expected), tostring(actual)), 2)
    end
end

local function truthy(v, msg)
    if not v then error(msg or 'expected a truthy value', 2) end
end

test('register + apply: calls the registered handler with entity and value', function()
    local capturedEntity, capturedValue
    VehicleTuningService.register('test:key', {
        apply = function(entity, value)
            capturedEntity = entity
            capturedValue = value
        end
    })

    VehicleTuningService.apply(1234, 'test:key', { foo = 'bar' })

    eq(capturedEntity, 1234)
    eq(capturedValue.foo, 'bar')
end)

test('apply: an unregistered key warns and does not error', function()
    local ok = pcall(VehicleTuningService.apply, 1234, 'test:never-registered', {})
    truthy(ok, 'apply did not error for an unknown key')
end)

test('built-in primaryColor: calls SetVehicleCustomPrimaryColour with r/g/b', function()
    local captured
    _G.SetVehicleCustomPrimaryColour = function(entity, r, g, b) captured = {entity, r, g, b} end

    VehicleTuningService.apply(42, 'primaryColor', { r = 255, g = 0, b = 0 })

    eq(captured[1], 42)
    eq(captured[2], 255)
    eq(captured[3], 0)
    eq(captured[4], 0)
end)

test('built-in turbo: calls ToggleVehicleMod with the turbo slot index and a real boolean', function()
    local captured
    _G.ToggleVehicleMod = function(entity, modIndex, enabled) captured = {entity, modIndex, enabled} end

    VehicleTuningService.apply(42, 'turbo', true)

    eq(captured[1], 42)
    eq(captured[2], 18)
    eq(captured[3], true)
end)

test('built-in spoiler: calls SetVehicleMod with the mod type and index', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end

    VehicleTuningService.apply(42, 'spoiler', 3)

    eq(captured[1], 42)
    eq(captured[2], 3)
    eq(captured[3], 3)
    eq(captured[4], false)
end)

--------------------------------------------------------------------------------
-- Runner
--------------------------------------------------------------------------------
print('Running VehicleTuningService unit tests\n')
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
