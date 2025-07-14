local QBCore = exports['qb-core']:GetCoreObject({'Functions', 'Commands'})
local lastWorkoutTime = {}
local WORKOUT_COOLDOWN = 30000 -- 30 seconds cooldown between workouts
local dailyWorkoutCount = {}

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
        DropPlayer(source, "You were kicked for exploiting.")
        return
    end

    -- Check if player already has a pass
    local existingPass = Player.Functions.GetItemByName(item)
    if existingPass then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'You already have a gym pass!'
        })
        return
    end

    if Player.Functions.RemoveMoney('cash', price) then
        -- Add pass with metadata
        local info = {
            purchaseDate = os.time(),
            expires = Config.GymPassDuration and (os.time() + Config.GymPassDuration) or nil,
            citizenid = Player.PlayerData.citizenid
        }

        Player.Functions.AddItem(item, 1, false, info)
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            title = 'Purchase Complete',
            description = 'You purchased a gym pass!'
        })

        -- Log transaction
        exports.oxmysql:insert('INSERT INTO gym_transactions (citizenid, type, amount, timestamp) VALUES (?, ?, ?, ?)', {
            Player.PlayerData.citizenid,
            'membership_purchase',
            price,
            os.time()
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Not enough cash.'
        })
    end
end)

RegisterServerEvent('qb-gym:reward', function(statType)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end

    -- Validate stat type
    if not statType or (statType ~= 'strength' and statType ~= 'stamina') then
        print('Gym Reward: Invalid stat type from client!', statType)
        DropPlayer(source, "Invalid Gym Data.")
        return
    end

    -- Check for gym pass
    local hasPass = Player.Functions.GetItemByName(Config.GymPassItem)
    if not hasPass then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'You need a gym pass to workout!'
        })
        return
    end

    -- Check if pass is expired
    if hasPass.info and hasPass.info.expires and hasPass.info.expires < os.time() then
        Player.Functions.RemoveItem(Config.GymPassItem, 1)
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Your gym pass has expired!'
        })
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
    local maxStat = Config.MaxStatLevel or 100

    if current >= maxStat then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'info',
            description = ('Your %s is already at maximum level!'):format(statType)
        })
        return
    end

    -- Calculate gains (with bonuses for streaks)
    local baseGain = 1
    local totalGain = baseGain

    -- Daily workout bonus
    local today = os.date('%Y-%m-%d')
    local citizenid = Player.PlayerData.citizenid

    if not dailyWorkoutCount[citizenid] then
        dailyWorkoutCount[citizenid] = { date = today, count = 0 }
    elseif dailyWorkoutCount[citizenid].date ~= today then
        dailyWorkoutCount[citizenid] = { date = today, count = 0 }
    end

    dailyWorkoutCount[citizenid].count = dailyWorkoutCount[citizenid].count + 1

    -- Bonus for multiple workouts
    if dailyWorkoutCount[citizenid].count >= 5 then
        totalGain = totalGain + 1
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'info',
            description = 'Daily workout bonus!'
        })
    end

    local newLevel = math.min(current + totalGain, maxStat)
    Player.Functions.SetMetaData(statType, newLevel)

    -- Update workout tracking metadata
    Player.Functions.SetMetaData('lastWorkout', os.date('%Y-%m-%d %H:%M'))
    Player.Functions.SetMetaData('totalWorkouts', (Player.PlayerData.metadata.totalWorkouts or 0) + 1)

    -- Log for admin tracking
    print(('qb-gym: Player %s (%s) increased %s from %d to %d'):format(
        GetPlayerName(src),
        Player.PlayerData.citizenid,
        statType,
        current,
        newLevel
    ))

    -- Save to database
    exports.oxmysql:insert('INSERT INTO gym_workouts (citizenid, stat_type, old_value, new_value, timestamp) VALUES (?, ?, ?, ?, ?)', {
        Player.PlayerData.citizenid,
        statType,
        current,
        newLevel,
        os.time()
    })

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

-- Admin command to check player stats
QBCore.Commands.Add('checkgymstats', 'Check a player\'s gym stats', {{name = 'id', help = 'Player ID'}}, true, function(source, args)
    local target = tonumber(args[1])
    if not target then return end

    local Player = exports['qb-core']:GetPlayer(target)
    if not Player then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Player not found' })
        return
    end

    local metadata = Player.PlayerData.metadata
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'info',
        title = 'Player Gym Stats',
        description = string.format('%s - STR: %d | STA: %d',
            Player.PlayerData.name,
            metadata.strength or 0,
            metadata.stamina or 0
        )
    })
end, 'admin')

-- Admin command to set player stats
QBCore.Commands.Add('setgymstat', 'Set a player\'s gym stat', {
    {name = 'id', help = 'Player ID'},
    {name = 'stat', help = 'strength/stamina'},
    {name = 'value', help = 'Value (0-100)'}
}, true, function(source, args)
    local target = tonumber(args[1])
    local stat = args[2]
    local value = tonumber(args[3])

    if not target or not stat or not value then return end
    if stat ~= 'strength' and stat ~= 'stamina' then return end
    if value < 0 or value > 100 then return end

    local Player = exports['qb-core']:GetPlayer(target)
    if not Player then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Player not found' })
        return
    end

    Player.Functions.SetMetaData(stat, value)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = string.format('Set %s %s to %d', Player.PlayerData.name, stat, value)
    })
end, 'admin')

-- Clean up on player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    lastWorkoutTime[src] = nil

    -- Clean up daily count if needed
    local Player = exports['qb-core']:GetPlayer(source)
    if Player and dailyWorkoutCount[Player.PlayerData.citizenid] then
        -- Save to database before cleanup
        exports.oxmysql:update('UPDATE players SET last_workout = ? WHERE citizenid = ?', {
            os.time(),
            Player.PlayerData.citizenid
        })
    end
end)

-- Database tables creation (run once)
CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS gym_workouts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50),
            stat_type VARCHAR(20),
            old_value INT,
            new_value INT,
            timestamp INT,
            INDEX idx_citizenid (citizenid)
        )
    ]])

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS gym_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50),
            type VARCHAR(50),
            amount INT,
            timestamp INT,
            INDEX idx_citizenid (citizenid)
        )
    ]])
end)