local workoutZones = {}

local function createWorkoutZone(typeKey, workout, workoutType)
    local zoneName = "gym_station_" .. workoutType .. "_" .. typeKey

    exports['qb-target']:AddBoxZone(zoneName, workout.coords, 1.5, 1.5, {
        name = zoneName,
        heading = workout.heading or 0,
        debugPoly = false,
        minZ = workout.coords.z - 1,
        maxZ = workout.coords.z + 2,
    }, {
        options = {
            {
                icon = "fas fa-dumbbell",
                label = workout.label,
                canInteract = function()
                    -- Check if player has gym pass
                    local items = exports['qb-core']:GetPlayerData().items
                    for _, item in pairs(items or {}) do
                        if item.name == Config.GymPassItem then
                            return true
                        end
                    end
                    return false
                end,
                action = function()
                    TriggerEvent('qb-gym:startWorkout', workoutType, typeKey)
                end
            },
            {
                icon = "fas fa-info-circle",
                label = "Equipment Info",
                action = function()
                    local metadata = exports['qb-core']:GetPlayerData().metadata
                    local currentStat = metadata[workout.stat] or 0

                    lib.notify({
                        title = workout.label,
                        description = string.format(
                            'Trains: %s | Difficulty: %s | Your %s: %d',
                            workout.stat:gsub("^%l", string.upper),
                            workout.difficulty:gsub("^%l", string.upper),
                            workout.stat,
                            currentStat
                        ),
                        type = 'info',
                        duration = 5000
                    })
                end
            }
        },
        distance = 2.0
    })

    -- Store zone reference
    workoutZones[zoneName] = {
        type = workoutType,
        key = typeKey,
        coords = workout.coords
    }
end

CreateThread(function()
    -- Wait for config to load
    while not Config do
        Wait(100)
    end

    -- Create zones for all equipment types
    local equipmentTypes = {
        'Treadmills',
        'Dumbbells',
        'Chinups',
        'BenchPress'
    }

    for _, equipType in ipairs(equipmentTypes) do
        if Config[equipType] then
            for key, data in pairs(Config[equipType]) do
                createWorkoutZone(key, data, equipType)
            end
        end
    end

    print(('qb-gym: Created %d workout zones'):format(#workoutZones))
end)

-- Debug command to show all zones
RegisterCommand('gymzones', function()
    local count = 0
    for zoneName, data in pairs(workoutZones) do
        count = count + 1
        print(string.format('Zone %d: %s at %s', count, zoneName, data.coords))
    end
    lib.notify({
        type = 'info',
        description = ('Found %d gym equipment zones'):format(count)
    })
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Remove all workout zones
    for zoneName, _ in pairs(workoutZones) do
        exports['qb-target']:RemoveZone(zoneName)
    end
end)