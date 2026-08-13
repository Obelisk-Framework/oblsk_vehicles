-- modules/oblsk_vehicles/tests/vehicle_service_find_by_net_id_spec.lua
-- Run from the repository root: lua5.4 modules/oblsk_vehicles/tests/vehicle_service_find_by_net_id_spec.lua
local scriptDir = arg[0]:match('(.*/)') or './'

QueryBuilder = { new = function() error('not used by this test') end }
dofile(scriptDir .. '../server/services/VehicleService.lua')

local tests, failures, passed = {}, {}, 0
local function test(name, fn) tests[#tests + 1] = {name = name, fn = fn} end
local function eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format('%s\n     expected: %s\n     actual:   %s',
            msg or 'assertion failed', tostring(expected), tostring(actual)), 2)
    end
end

test('findVehicleIdByNetId: finds the vehicleId for a known netId', function()
    VehicleService.activeNetIds = { [7] = 501, [8] = 502 }
    eq(VehicleService.findVehicleIdByNetId(502), 8)
end)

test('findVehicleIdByNetId: returns nil for an unknown netId', function()
    VehicleService.activeNetIds = { [7] = 501 }
    eq(VehicleService.findVehicleIdByNetId(999), nil)
end)

print('Running VehicleService.findVehicleIdByNetId tests\n')
for _, t in ipairs(tests) do
    local ok, err = pcall(t.fn)
    if ok then passed = passed + 1; print('  ok   - ' .. t.name)
    else failures[#failures + 1] = t.name; print('  FAIL - ' .. t.name .. '\n         ' .. tostring(err)) end
end
print(string.format('\n%d passed, %d failed', passed, #failures))
os.exit(#failures == 0 and 0 or 1)
