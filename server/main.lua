local lastWorkoutTime = {}
local WORKOUT_COOLDOWN = 30000 -- 30 seconds cooldown between workouts

RegisterServerEvent('qb-gym:buyPass', function()
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end

    local price = Config.GymPassPrice
    local item = Config.GymPassItem

    -- Add distance check to prevent remote exploitation
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local distance = #(pedCoords - Config.GymPedCoords.xyz)
    
    if distance > 5.0 then
        print(('qb-gym: Player %s attempted to buy gym pass from distance %.2f'):format(src, distance))
        return
    end

    if Player.Functions.RemoveMoney('cash', price) then
        Player.Functions.AddItem(item, 1)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'You purchased a gym pass!' })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough cash.' })
    end
end)

RegisterServerEvent('qb-gym:reward', function(statType)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end

    -- Validate stat type
    if not statType or (statType ~= 'strength' and statType ~= 'stamina') then
        print('Gym Reward: Invalid stat type from client!', statType)
        return
    end

    -- Check for gym pass
    local hasPass = Player.Functions.GetItemByName(Config.GymPassItem)
    if not hasPass then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need a gym pass to workout!' })
        return
    end

    -- Cooldown check
    local currentTime = GetGameTimer()
    if lastWorkoutTime[src] and (currentTime - lastWorkoutTime[src]) < WORKOUT_COOLDOWN then
        local remainingTime = math.ceil((WORKOUT_COOLDOWN - (currentTime - lastWorkoutTime[src])) / 1000)
        TriggerClientEvent('ox_lib:notify', src, { 
            type = 'error', 
            description = ('You need to rest for %d more seconds'):format(remainingTime) 
        })
        return
    end

    -- Update cooldown
    lastWorkoutTime[src] = currentTime

    -- Update stats with cap
    local current = Player.PlayerData.metadata[statType] or 0
    local maxStat = 100 -- Maximum stat level
    
    if current >= maxStat then
        TriggerClientEvent('ox_lib:notify', src, { 
            type = 'info', 
            description = ('Your %s is already at maximum level!'):format(statType) 
        })
        return
    end

    local newLevel = math.min(current + 1, maxStat)
    Player.Functions.SetMetaData(statType, newLevel)
    
    -- Log for admin tracking
    print(('qb-gym: Player %s (%s) increased %s from %d to %d'):format(
        GetPlayerName(src), 
        Player.PlayerData.citizenid, 
        statType, 
        current, 
        newLevel
    ))
    
    -- Give different messages based on level
    local message = 'You feel stronger!'
    if newLevel >= 90 then
        message = 'You\'re reaching peak physical condition!'
    elseif newLevel >= 50 then
        message = 'You\'re getting really fit!'
    elseif newLevel >= 25 then
        message = 'You\'re making good progress!'
    end
    
    TriggerClientEvent('ox_lib:notify', src, { 
        type = 'success', 
        title = 'Workout Complete', 
        description = message 
    })
end)

-- Clean up on player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    lastWorkoutTime[src] = nil
end)