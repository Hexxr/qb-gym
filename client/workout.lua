local isWorkingOut = false
local workoutCooldown = (Config.WorkoutCooldown or 30) * 1000-- Convert seconds to ms if your config is in seconds
local lastWorkoutTime = 0

local function GetWorkoutData(workoutType, key)
    local pool = Config[workoutType]
    return pool and pool[key]
end

-- Special handling for treadmill positioning
local function SetupTreadmillPosition(ped, coords, heading)
    -- Freeze the ped first
    FreezeEntityPosition(ped, true)

    -- Set position and heading
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, heading or 0.0)

    -- Small delay to ensure positioning
    Wait(100)

    -- Unfreeze for animation
    FreezeEntityPosition(ped, false)
end

RegisterNetEvent('qb-gym:startWorkout', function(workoutType, key)
    print('StartWorkout triggered for:', workoutType, key)

    local now = GetGameTimer()
    if now - lastWorkoutTime < workoutCooldown then
    print("Workout debounce: too soon")
    return
end
    lastWorkoutTime = now


    if isWorkingOut then
        print('Workout already active — blocking duplicate trigger')
        return
    end

    -- Check for gym pass
    local hasPass = exports['qb-core']:GetPlayerData().items
    local passFound = false

    for _, item in pairs(hasPass or {}) do
        if item.name == Config.GymPassItem then
            passFound = true
            break
        end
    end

    if not passFound then
        lib.notify({
            type = 'error',
            title = 'No Gym Pass',
            description = 'You need a gym pass to use the equipment!'
        })
        return
    end

    local workout = GetWorkoutData(workoutType, key)
    print('DEBUG WORKOUT DATA:', json.encode(workout))

    if not workout or type(workout.animDict) ~= 'string' or workout.animDict == '' then
        print('ERROR: Invalid or missing animDict', workout and workout.animDict)
        lib.notify({ type = 'error', description = 'Invalid workout animation' })
        return
    end

    if type(workout.anim) ~= 'string' or workout.anim == '' then
        print('ERROR: Invalid or missing animation name', workout and workout.anim)
        lib.notify({ type = 'error', description = 'Invalid workout animation' })
        return
    end

    isWorkingOut = true

    local ped = PlayerPedId()
    local propEntity

    -- Show current stats before workout
    local metadata = exports['qb-core']:GetPlayerData().metadata
    local currentStat = metadata[workout.stat] or 0
    lib.notify({
        type = 'info',
        description = ('Current %s: %d'):format(workout.stat, currentStat)
    })

    -- Skill Check with dynamic difficulty based on stat level
    local difficulty = workout.difficulty
    if currentStat >= 75 then
        difficulty = 'hard' -- Make it harder for advanced players
    elseif currentStat >= 50 then
        difficulty = 'medium'
    end

    local success = lib.skillCheck({ difficulty }, { 'w', 'a', 's', 'd' })
    if not success then
        lib.notify({ type = 'error', title = 'Workout', description = 'Failed the set. Try again!' })
        isWorkingOut = false
        return
    end

    -- Special handling for equipment positioning
    if workout.equipmentCoords then
        SetupTreadmillPosition(ped, workout.equipmentCoords, workout.equipmentHeading)
    elseif workoutType == 'Treadmills' and workout.treadmillCoords then
        SetupTreadmillPosition(ped, workout.treadmillCoords, workout.treadmillHeading)
    end

    -- Load Prop if needed
    if workout.prop then
        local propHash = joaat(workout.prop)
        lib.requestModel(propHash)
        local coords = GetEntityCoords(ped)
        propEntity = CreateObject(propHash, coords.x, coords.y, coords.z + 0.2, true, true, true)

        -- Different attachment points for different props
        local boneIndex = 28422 -- Right hand default
        local xPos, yPos, zPos = 0.0, 0.0, 0.0
        local xRot, yRot, zRot = 0.0, 0.0, 0.0

        if workout.prop == 'prop_curl_bar_01' then
            -- Dumbbell specific positioning
            boneIndex = 28422
            xPos, yPos, zPos = 0.09, 0.0, -0.02
            xRot, yRot, zRot = 90.0, 0.0, 0.0
        end

        AttachEntityToEntity(propEntity, ped, GetPedBoneIndex(ped, boneIndex),
            xPos, yPos, zPos, xRot, yRot, zRot,
            true, true, false, true, 1, true)
    end

    -- Animation
    lib.playAnim(
        ped,                -- ped
        workout.animDict,   -- animDictionary
        workout.anim,       -- animationName
        8.0,               -- blendInSpeed
        -8.0,              -- blendOutSpeed
        -1,                -- duration (-1 for continuous)
        workout.flag or 1, -- flags (use workout specific or default to 1)
        0.0,               -- startPhase
        false,             -- phaseControlled
        0,                 -- controlFlags
        false              -- overrideCloneUpdate
    )

    -- Progress with dynamic duration based on equipment
    lib.progressBar({
        duration = workout.duration or 5000,
        label = workout.label or 'Working out...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
            sprint = true
        },
    })

    -- Stop animation after progress bar
    ClearPedTasks(ped)

    -- Cleanup
    if propEntity and DoesEntityExist(propEntity) then
        DetachEntity(propEntity, true, true)
        DeleteEntity(propEntity)
    end

    --Reward Logic
    TriggerServerEvent('qb-gym:reward', workout.stat or 'strength')

    isWorkingOut = false

    local playerData = exports['qb-core']:GetPlayerData()
    local playerId = PlayerId()
    local statType = workout.stat or 'strength'

    if playerData and playerData.metadata and playerData.metadata[statType] then
        local statValue = playerData.metadata[statType]

        if statType == 'strength' then
            exports['qb-gym'].ApplyStrengthEffect(statValue, playerId)
        elseif statType == 'stamina' then
            exports['qb-gym'].ApplyStaminaEffect(statValue, playerId)
        end
    end
end)

-- Add command to check if player has gym pass
RegisterCommand('gympass', function()
    local hasPass = exports['qb-core']:GetPlayerData().items
    local passFound = false

    for _, item in pairs(hasPass or {}) do
        if item.name == Config.GymPassItem then
            passFound = true
            break
        end
    end

    if passFound then
        lib.notify({ type = 'success', description = 'You have an active gym pass!' })
    else
        lib.notify({ type = 'error', description = 'You don\'t have a gym pass. Visit the gym reception!' })
    end
end)