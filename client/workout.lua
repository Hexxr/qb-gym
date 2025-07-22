local isWorkingOut = false
local workoutCooldown = (Config.WorkoutCooldown or 10) * 1000
local lastWorkoutTime = 0
local cachedPlayerData = nil
local spawnedEquipment = nil

-- Update cache when player data changes
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    cachedPlayerData = data
end)

-- Initialize cache when player loads
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    cachedPlayerData = exports['qb-core']:GetPlayerData()
end)

-- Get fresh data if cache is empty
local function GetPlayerData()
    if not cachedPlayerData then
        cachedPlayerData = exports['qb-core']:GetPlayerData()
    end
    return cachedPlayerData
end

local function HasGymPass()
    -- Get fresh item data every time (items change frequently)
    local items = exports['qb-core']:GetPlayerData().items or {}
    for _, item in pairs(items) do
        if item.name == Config.GymPassItem then
            return true
        end
    end
    return false
end

local function GetWorkoutData(workoutType, key)
    local pool = Config[workoutType]
    return pool and pool[key]
end

local function SetupEquipmentPosition(ped, coords, heading)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, heading or 0.0)
    Wait(100)
    FreezeEntityPosition(ped, false)
end

local function GetEquipmentPosition(workoutType, workout)
    if workoutType == 'Treadmills' and workout.treadmillCoords then
        return workout.treadmillCoords, workout.treadmillHeading
    elseif workoutType == 'Chinups' and workout.chinupCoords then
        return workout.chinupCoords, workout.chinupHeading
    elseif workout.equipmentCoords then
        return workout.equipmentCoords, workout.equipmentHeading
    end
    return nil, nil
end

local function CleanupWorkout(ped, prop, animDict, anim)
    -- Clear animations thoroughly
    ClearPedTasks(ped)
    Wait(100)
    if animDict and anim and IsEntityPlayingAnim(ped, animDict, anim, 3) then
        ClearPedTasksImmediately(ped)
    end

    if spawnedEquipment then
        DetachEntity(ped, true, true)
    end

    if spawnedEquipment and DoesEntityExist(spawnedEquipment) then
    DeleteEntity(spawnedEquipment)
    spawnedEquipment = nil
end

    -- Clean up prop
    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        DeleteEntity(prop)
    end
end

RegisterNetEvent('qb-gym:startWorkout', function(workoutType, key)
    if isWorkingOut then
        lib.notify({ type = 'error', description = 'Already working out!' })
        return
    end

    if IsEntityDead(PlayerPedId()) then
        lib.notify({ type = 'error', description = 'You cannot workout while dead.' })
        return
    end

    local now = GetGameTimer()
    if now - lastWorkoutTime < workoutCooldown then
        local remaining = math.ceil((workoutCooldown - (now - lastWorkoutTime)) / 1000)
        lib.notify({
            type = 'error',
            description = ('Rest for %d more seconds'):format(remaining)
        })
        return
    end

    if not HasGymPass() then
        lib.notify({
            type = 'error',
            title = 'No Gym Pass',
            description = 'You need a gym pass to use the equipment!'
        })
        return
    end

    local workout = GetWorkoutData(workoutType, key)
    if not workout then
        lib.notify({ type = 'error', description = 'Invalid workout!' })
        return
    end

    if not workout.animDict or workout.animDict == '' or not workout.anim or workout.anim == '' then
        lib.notify({ type = 'error', description = 'Invalid workout animation!' })
        return
    end

    local playerData = GetPlayerData()
    if not playerData.metadata then
        lib.notify({ type = 'error', description = 'Player data not loaded!' })
        return
    end

    isWorkingOut = true
    lastWorkoutTime = now

    local ped = PlayerPedId()
    local propEntity = nil
    local statType = workout.stat or 'strength'
    local currentStat = playerData.metadata[statType] or 0

    lib.notify({
        type = 'info',
        description = ('Current %s: %d'):format(statType, currentStat)
    })

    local difficulty = workout.difficulty or 'easy'
    if currentStat >= 75 then
        difficulty = 'hard'
    elseif currentStat >= 50 then
        difficulty = 'medium'
    end

    local success = lib.skillCheck({ difficulty }, { 'w', 'a', 's', 'd' })
    if not success then
        lib.notify({
            type = 'error',
            title = 'Workout Failed',
            description = 'Better luck next time!'
        })
        isWorkingOut = false
        return
    end

    local coords, heading = GetEquipmentPosition(workoutType, workout)
    if coords then
        SetupEquipmentPosition(ped, coords, heading)
    end

    if workout.equipment then
    print("DEBUG - workout.equipment value:", workout.equipment, "Type:", type(workout.equipment))

    if type(workout.equipment) == "string" then
        lib.requestModel(workout.equipment)
    end

    local pedCoords = GetEntityCoords(ped)

    local modelToUse = type(workout.equipment) == "string" and joaat(workout.equipment) or workout.equipment

    spawnedEquipment = CreateObject(modelToUse,
        pedCoords.x,
        pedCoords.y,
        pedCoords.z,
        true, true, true)

    SetEntityHeading(spawnedEquipment, GetEntityHeading(ped))
    PlaceObjectOnGroundProperly(spawnedEquipment)
    FreezeEntityPosition(spawnedEquipment, true)

    Wait(100)
    local benchCoords = GetEntityCoords(spawnedEquipment)
    local benchHeading = GetEntityHeading(spawnedEquipment)

    AttachEntityToEntity(ped, spawnedEquipment, -1, 0.0, 0.0, 0.6, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
end

    if workout.prop then
        local propHash = joaat(workout.prop)
        lib.requestModel(propHash)

        local pedCoords = GetEntityCoords(ped)
        propEntity = CreateObject(propHash, pedCoords.x, pedCoords.y, pedCoords.z + 0.2, true, true, true)

        local boneIndex = 28422
        local xPos, yPos, zPos = 0.0, 0.0, 0.0
        local xRot, yRot, zRot = 0.0, 0.0, 0.0

        if workout.prop == 'prop_curl_bar_01' then
            xPos, yPos, zPos = 0.09, 0.0, -0.02
            xRot, yRot, zRot = 90.0, 0.0, 0.0
        end

        AttachEntityToEntity(propEntity, ped, GetPedBoneIndex(ped, boneIndex),
            xPos, yPos, zPos, xRot, yRot, zRot,
            true, true, false, true, 1, true)
    end

    lib.playAnim(ped, workout.animDict, workout.anim, 8.0, -8.0, -1, workout.flag or 1, 0.0, false, 0, false)

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

    CleanupWorkout(ped, propEntity, workout.animDict, workout.anim)

    TriggerServerEvent('qb-gym:reward', statType)

    local newStatValue = math.min(currentStat + 1, Config.MaxStatLevel or 100)
    if statType == 'strength' then
        exports['qb-gym']:ApplyStrengthEffect(newStatValue, PlayerId())
    elseif statType == 'stamina' then
        exports['qb-gym']:ApplyStaminaEffect(newStatValue, PlayerId())
    end

    lib.notify({
        type = 'success',
        title = 'Workout Complete',
        description = 'Great set!'
    })

    isWorkingOut = false
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    cachedPlayerData = nil
    isWorkingOut = false
end)

CreateThread(function()
    Wait(1000)
    cachedPlayerData = exports['qb-core']:GetPlayerData()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    local ped = PlayerPedId()
    CleanupWorkout(ped, nil, nil, nil)
    isWorkingOut = false
end)