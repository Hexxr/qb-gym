local function createWorkoutZone(typeKey, workout, workoutType)
    exports['qb-target']:AddBoxZone("gym_station_" .. typeKey, workout.coords, 1.5, 1.5, {
        name = "gym_station_" .. typeKey,
        heading = 0,
        debugPoly = false,
        minZ = workout.coords.z - 1,
        maxZ = workout.coords.z + 1,
    }, {
        options = {
            {
                icon = "fas fa-dumbbell",
                label = workout.label,
                action = function()
                    TriggerEvent('qb-gym:startWorkout', workoutType, typeKey)
                end
            }
        },
        distance = 2.0
    })
end

CreateThread(function()
    for key, data in pairs(Config.Treadmills) do
        createWorkoutZone(key, data, 'Treadmills')
    end

    for key, data in pairs(Config.Dumbbells) do
        createWorkoutZone(key, data, 'Dumbbells')
    end

    for key, data in pairs(Config.Chinups) do
        createWorkoutZone(key, data, 'Chinups')
    end

    for key, data in pairs(Config.BenchPress) do
        createWorkoutZone(key, data, 'BenchPress')
    end
end)