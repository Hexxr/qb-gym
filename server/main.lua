local QBCore = exports['qb-core']:GetCoreObject({'Commands'})
local lastWorkoutTime = {}
local WORKOUT_COOLDOWN = 30000 -- 30 seconds cooldown between workouts
local dailyWorkoutCount = {}
local playerWorkoutHistory = {}
local pendingStatUpdates = {}

local function debugPrint(...)
    if Config.Debug then
        print('^3[QB-GYM DEBUG]^7', ...)
    end
end

local function checkRateLimit(src)
    local history = playerWorkoutHistory[src] or {}
    local now = GetGameTimer()

    debugPrint('Rate limit check for player', src, '- Workouts in last 5 min:', #history)

    --remove old entries (older than 5 mins)
    local recentWorkouts = {}
    for _, time in ipairs(history) do
        if now - time < 300000 then
            table.insert(recentWorkouts, time)
        end
    end

    --check if too many recent workouts
    if #recentWorkouts >= 10 then
        return false, "Working out too frequently! Break Time."
    end

    table.insert(recentWorkouts, now)
    playerWorkoutHistory[src] = recentWorkouts

    return true
end

RegisterServerEvent('qb-gym:buyPass', function()
    local src = source
    debugPrint('Player', src, 'attempting to buy gym pass')
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then
        debugPrint('Player not found for source:', src)
        return
    end

    local price = Config.GymPassPrice
    local item = Config.GymPassItem

    -- Add distance check to prevent remote exploitation
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local distance = #(pedCoords - Config.GymPedCoords.xyz)
    debugPrint('Purchase distance check:', distance, 'meters')

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
        debugPrint('Money removed successfully, adding gym pass item')
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
    debugPrint('Workout reward triggered - Source:', src, 'Stat:', statType)
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end

    -- Validate stat type
    if not statType or (statType ~= 'strength' and statType ~= 'stamina') then
        print('Gym Reward: Invalid stat type from client!', statType)
        DropPlayer(source, "Invalid Gym Data.")
        return
    end

    debugPrint('Stat validation passed for:', statType)

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
        debugPrint('Time since last workout:', lastWorkoutTime, 'ms')
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = ('You need to rest for %d more seconds'):format(remainingTime)
        })
        return
    end

    local allowed, message = checkRateLimit(src)
    if not allowed then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = message
        })
        return
    end

    -- Update cooldown
    lastWorkoutTime[src] = currentTime

    -- Update stats with cap
    local current = Player.PlayerData.metadata[statType] or 0
    debugPrint('Current', statType, 'level:', current)
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

    -- Track progress for batch saving
    if not pendingStatUpdates[citizenid] then
        debugPrint('Creating new pending stat tracking for', citizenid)
        pendingStatUpdates[citizenid] = {
            strength_start = Player.PlayerData.metadata.strength or 0,
            stamina_start = Player.PlayerData.metadata.stamina or 0,
            strength_current = Player.PlayerData.metadata.strength or 0,
            stamina_current = Player.PlayerData.metadata.stamina or 0
        }
    end

    -- Update current values
    pendingStatUpdates[citizenid][statType .. '_current'] = newLevel

    -- Check if we should save (every 5 levels or at milestones)
    local gainedLevels = newLevel - pendingStatUpdates[citizenid][statType .. '_start']
    debugPrint('Gained levels since last save:', gainedLevels)

    if gainedLevels >= 5 or newLevel % 10 == 0 or newLevel == maxStat then
        -- Save to database
        exports.oxmysql:insert('INSERT INTO gym_workouts (citizenid, stat_type, old_value, new_value, timestamp) VALUES (?, ?, ?, ?, ?)', {
            Player.PlayerData.citizenid,
            statType,
            pendingStatUpdates[citizenid][statType .. '_start'],
            newLevel,
            os.time()
        })

        -- Reset the starting point
        pendingStatUpdates[citizenid][statType .. '_start'] = newLevel

        -- Log milestone
        print(('[qb-gym] Milestone: %s reached %s level %d'):format(
            Player.PlayerData.name,
            statType,
            newLevel
        ))
    end

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

lib.callback.register('qb-gym:server:formatDate', function(source, timestamp)
    if not timestamp then
        return "Never"
    end

    return os.date('%m/%d/%Y', timestamp)
end)

exports('GetServerTime', function()
    return os.time()
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

QBCore.Commands.Add('testboost', 'Test a temporary stat boost', {
    {name = 'stat', help = 'strength or stamina'},
    {name = 'value', help = 'Boost amount (default: 10)'},
    {name = 'duration', help = 'Duration in seconds (default: 30)'}
}, false, function(source, args)
    local stat = args[1] or 'strength'
    local value = tonumber(args[2]) or 10
    local duration = tonumber(args[3]) or 30

    TriggerClientEvent('qb-gym:client:testBoost', source, stat, value, duration)
end, 'admin')

-- Clean up on player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    lastWorkoutTime[src] = nil
    playerWorkoutHistory[src] = nil

    local Player = exports['qb-core']:GetPlayer(source)
    if Player then
        local citizenid = Player.PlayerData.citizenid

        -- Save any pending updates before cleanup
        if pendingStatUpdates[citizenid] then
            -- Save final progress if any gains were made
            for _, statType in ipairs({'strength', 'stamina'}) do
                local gained = pendingStatUpdates[citizenid][statType .. '_current'] - pendingStatUpdates[citizenid][statType .. '_start']
                if gained > 0 then
                    exports.oxmysql:insert('INSERT INTO gym_workouts (citizenid, stat_type, old_value, new_value, timestamp) VALUES (?, ?, ?, ?, ?)', {
                        citizenid,
                        statType,
                        pendingStatUpdates[citizenid][statType .. '_start'],
                        pendingStatUpdates[citizenid][statType .. '_current'],
                        os.time()
                    })
                end
            end
            pendingStatUpdates[citizenid] = nil
        end

        dailyWorkoutCount[citizenid] = nil
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

CreateThread(function()
    while true do
        Wait(3600000) -- Every hour

        -- Only run if table has entries
        if next(dailyWorkoutCount) then
            local currentDate = os.date('%Y-%m-%d')
            local cleaned = 0

            for citizenid, data in pairs(dailyWorkoutCount) do
                if data.date ~= currentDate then
                    dailyWorkoutCount[citizenid] = nil
                    cleaned = cleaned + 1
                end
            end

            -- Log cleanup for monitoring
            if cleaned > 0 then
                print(('[qb-gym] Cleaned %d expired workout entries'):format(cleaned))
            end
        end
    end
end)