local isWorkingOut = false

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

    if isWorkingOut then
        print('Workout already active — blocking duplicate trigger')
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

    -- Skill Check
    local success = lib.skillCheck({ workout.difficulty or 'easy' }, { 'w', 'a', 's', 'd' })
    if not success then
        lib.notify({ type = 'error', title = 'Workout', description = 'Failed the set.' })
        isWorkingOut = false
        return
    end

    -- Special handling for treadmill
    if workoutType == 'Treadmills' and workout.treadmillCoords then
        SetupTreadmillPosition(ped, workout.treadmillCoords, workout.treadmillHeading)
    end

    print('REQUESTING ANIM:', workout.animDict, 'TYPE:', type(workout.animDict))

    -- Load Prop if needed
    if workout.prop then
        local propHash = joaat(workout.prop)
        lib.requestModel(propHash)
        local coords = GetEntityCoords(ped)
        propEntity = CreateObject(propHash, coords.x, coords.y, coords.z + 0.2, true, true, true)
        AttachEntityToEntity(propEntity, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
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

    -- Progress
    lib.progressBar({
        duration = workout.duration or 5000,
        label = workout.label or 'Working out...',
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, car = true, combat = true },
    })

    -- Stop animation after progress bar
    ClearPedTasks(ped)

    -- Cleanup
    if propEntity and DoesEntityExist(propEntity) then
        DetachEntity(propEntity, true, true)
        DeleteEntity(propEntity)
    end

    -- Reward logic
    TriggerServerEvent('qb-gym:reward', workout.stat or 'strength')
    lib.notify({ type = 'success', title = 'Workout', description = 'You feel stronger!' })

    isWorkingOut = false
end)