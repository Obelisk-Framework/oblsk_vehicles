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

test('built-in spoiler: now uses mod type 0, not 3', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end

    VehicleTuningService.apply(42, 'spoiler', 5)

    eq(captured[2], 0, 'spoiler must use GTA mod type 0')
    eq(captured[3], 5)
end)

test('built-in secondaryColor: calls SetVehicleCustomSecondaryColour with r/g/b', function()
    local captured
    _G.SetVehicleCustomSecondaryColour = function(entity, r, g, b) captured = {entity, r, g, b} end

    VehicleTuningService.apply(42, 'secondaryColor', { r = 10, g = 20, b = 30 })

    eq(captured[1], 42)
    eq(captured[2], 10)
    eq(captured[3], 20)
    eq(captured[4], 30)
end)

test('built-in pearlescent: calls SetVehicleExtraColours with pearlescentId/wheelId', function()
    local captured
    _G.SetVehicleExtraColours = function(entity, pearlescentId, wheelId) captured = {entity, pearlescentId, wheelId} end

    VehicleTuningService.apply(42, 'pearlescent', { pearlescentId = 12, wheelId = 156 })

    eq(captured[2], 12)
    eq(captured[3], 156)
end)

test('built-in bumperF: calls SetVehicleMod with mod type 1', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end
    VehicleTuningService.apply(42, 'bumperF', 2)
    eq(captured[2], 1)
    eq(captured[3], 2)
end)

test('built-in bumperR: calls SetVehicleMod with mod type 2', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end
    VehicleTuningService.apply(42, 'bumperR', 1)
    eq(captured[2], 2)
end)

test('built-in skirt: calls SetVehicleMod with mod type 3', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end
    VehicleTuningService.apply(42, 'skirt', 1)
    eq(captured[2], 3)
end)

test('built-in exhaust: calls SetVehicleMod with mod type 4', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end
    VehicleTuningService.apply(42, 'exhaust', 1)
    eq(captured[2], 4)
end)

test('built-in hood: calls SetVehicleMod with mod type 7', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end
    VehicleTuningService.apply(42, 'hood', 1)
    eq(captured[2], 7)
end)

test('built-in roof: calls SetVehicleMod with mod type 10', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end
    VehicleTuningService.apply(42, 'roof', 1)
    eq(captured[2], 10)
end)

test('built-in engine: calls SetVehicleMod with mod type 11', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end
    VehicleTuningService.apply(42, 'engine', 3)
    eq(captured[2], 11)
end)

test('built-in brakes: calls SetVehicleMod with mod type 12', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end
    VehicleTuningService.apply(42, 'brakes', 1)
    eq(captured[2], 12)
end)

test('built-in suspension: calls SetVehicleMod with mod type 15', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end
    VehicleTuningService.apply(42, 'suspension', 1)
    eq(captured[2], 15)
end)

test('built-in horn: calls SetVehicleMod with mod type 14', function()
    local captured
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) captured = {entity, modType, modIndex, customTires} end
    VehicleTuningService.apply(42, 'horn', 4)
    eq(captured[2], 14)
end)

test('built-in wheels: calls SetVehicleWheelType then SetVehicleMod with mod type 23', function()
    local wheelTypeCaptured, modCaptured
    _G.SetVehicleWheelType = function(entity, wheelType) wheelTypeCaptured = {entity, wheelType} end
    _G.SetVehicleMod = function(entity, modType, modIndex, customTires) modCaptured = {entity, modType, modIndex, customTires} end

    VehicleTuningService.apply(42, 'wheels', { wheelType = 6, index = 9 })

    eq(wheelTypeCaptured[2], 6)
    eq(modCaptured[2], 23)
    eq(modCaptured[3], 9)
end)

test('built-in window: calls SetVehicleWindowTint with the index', function()
    local captured
    _G.SetVehicleWindowTint = function(entity, index) captured = {entity, index} end
    VehicleTuningService.apply(42, 'window', 3)
    eq(captured[2], 3)
end)

test('built-in neon: colours all four corners and enables them', function()
    local colourCaptured
    local enabledCalls = {}
    _G.SetVehicleNeonLightsColour = function(entity, r, g, b) colourCaptured = {entity, r, g, b} end
    _G.SetVehicleNeonLightEnabled = function(entity, i, on) enabledCalls[#enabledCalls + 1] = {entity, i, on} end

    VehicleTuningService.apply(42, 'neon', { r = 1, g = 2, b = 3 })

    eq(colourCaptured[2], 1)
    eq(colourCaptured[3], 2)
    eq(colourCaptured[4], 3)
    eq(#enabledCalls, 4)
    eq(enabledCalls[1][3], true)
end)

test('built-in livery: calls SetVehicleLivery with the index', function()
    local captured
    _G.SetVehicleLivery = function(entity, index) captured = {entity, index} end
    VehicleTuningService.apply(42, 'livery', 2)
    eq(captured[2], 2)
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
