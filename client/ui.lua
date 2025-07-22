local cachedPlayerData = nil
local maxLevel = Config.MaxStatLevel or 100
local lastUsed = 0

if not lib then
    print("^1[UI] ox_lib not found! Check dependencies.")
    return
end

local function getPlayerMetadata()
    local player = cachedPlayerData or exports['qb-core']:GetPlayerData()
    if not player then return {} end
    return player.metadata or {}
end

local function getPlayerData()
    return exports['qb-core']:GetPlayerData() or {}
end

local function getStatBar(value, maxValue)
    value = tonumber(value) or 0
    maxValue = tonumber(maxValue) or 100
    value = math.max(0, math.min(value, maxValue))

    local percentage = (value / maxValue) * 100
    local filled = math.floor(percentage / 10)
    local empty = 10 - filled

    return string.rep("█", filled) .. string.rep("░", empty)
end

local function getStatDescription(stat, value)
    value = tonumber(value) or 0

    if stat == 'strength' then
        if value >= 90 then return "💪 Hercules"
        elseif value >= 70 then return "💪 Bodybuilder"
        elseif value >= 50 then return "💪 Athletic"
        elseif value >= 30 then return "💪 Fit"
        elseif value >= 10 then return "💪 Average"
        else return "💪 Weak" end
    elseif stat == 'stamina' then
        if value >= 90 then return "🏃 Marathon Runner"
        elseif value >= 70 then return "🏃 Athlete"
        elseif value >= 50 then return "🏃 Sprinter"
        elseif value >= 30 then return "🏃 Jogger"
        elseif value >= 10 then return "🏃 Average"
        else return "🏃 Winded" end
    end

    return "Unknown"
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    cachedPlayerData = exports['qb-core']:GetPlayerData()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    local oldData = cachedPlayerData
    cachedPlayerData = data

    if not data.metadata or not oldData or not oldData.metadata then return end

    local function notifyIfIncreased(stat)
        local oldVal = oldData.metadata[stat] or 0
        local newVal = data.metadata[stat] or 0
        if newVal > oldVal then
            lib.notify({
                title = stat:gsub("^%l", string.upper) .. ' Increased!',
                description = ('Level %d → %d'):format(oldVal, newVal),
                type = 'success',
                icon = stat == 'strength' and 'dumbbell' or 'running',
                position = 'top',
                duration = 5000
            })
            PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
        end
    end

    notifyIfIncreased('strength')
    notifyIfIncreased('stamina')
end)

local function openGymMenu()
    local player = cachedPlayerData or exports['qb-core']:GetPlayerData()
    if not player then
        lib.notify({ type = 'error', description = 'Unable to load player data' })
        return
    end

    local metadata = getPlayerMetadata()
    local items = getPlayerData().items or {}

    local strength = math.min(tonumber(metadata.strength) or 0, maxLevel)
    local stamina = math.min(tonumber(metadata.stamina) or 0, maxLevel)
    local hasPass, passInfo = false, {}

    for _, item in pairs(items) do
        if item and item.name == Config.GymPassItem then
            hasPass = true
            passInfo = item.info or {}
            break
        end
    end

    local membershipMetadata = {}
    if hasPass then
        table.insert(membershipMetadata, { label = 'Status', value = 'Active' })

        -- Get formatted dates from server
        if passInfo.expires then
            local expiresDate = lib.callback.await('qb-gym:server:formatDate', false, passInfo.expires)
            table.insert(membershipMetadata, { label = 'Expires', value = expiresDate })
        else
            table.insert(membershipMetadata, { label = 'Expires', value = 'Never' })
        end

        if passInfo.purchaseDate then
            local purchaseDate = lib.callback.await('qb-gym:server:formatDate', false, passInfo.purchaseDate)
            table.insert(membershipMetadata, { label = 'Member Since', value = purchaseDate })
        end
    else
        table.insert(membershipMetadata, { label = 'Status', value = 'Inactive' })
        table.insert(membershipMetadata, { label = 'Price', value = '$' .. tostring(Config.GymPassPrice or 1250) })
        table.insert(membershipMetadata, { label = 'Benefits', value = 'Access to all equipment' })
    end

    lib.registerContext({
        id = 'gym_main_menu',
        title = '💪 Pump and GO',
        options = {
            { title = '━━━ FITNESS STATISTICS ━━━', disabled = true },
            {
                title = 'Strength: ' .. getStatDescription('strength', strength),
                description = 'Level: ' .. strength .. '/' .. (Config.MaxStatLevel or 100),
                progress = strength,
                colorScheme = 'red',
                metadata = {
                    { label = 'Progress', value = getStatBar(strength, Config.MaxStatLevel or 100) },
                    { label = 'Melee Bonus', value = '+' .. math.floor((strength / 10) * 10) .. '%' }
                }
            },
            {
                title = 'Stamina: ' .. getStatDescription('stamina', stamina),
                description = 'Level: ' .. stamina .. '/' .. (Config.MaxStatLevel or 100),
                progress = stamina,
                colorScheme = 'blue',
                metadata = {
                    { label = 'Progress', value = getStatBar(stamina, Config.MaxStatLevel or 100) },
                    { label = 'Sprint Bonus', value = '+' .. math.floor((stamina / 10) * 5) .. '%' }
                }
            },
            {
                title = '🔥 Workout History',
                description = 'Track your progress',
                metadata = {
                    { label = 'Last Workout', value = tostring(metadata.lastWorkout or 'Never') },
                    { label = 'Total Sessions', value = tostring(metadata.totalWorkouts or 0) },
                    { label = 'Workout Streak', value = tostring(metadata.workoutStreak or 0) .. ' days' }
                }
            },
            { title = '━━━ MEMBERSHIP INFO ━━━', disabled = true },
            {
                title = '🎫 Membership Status',
                description = hasPass and '✅ Active Membership' or '❌ No Membership',
                icon = 'id-card',
                metadata = membershipMetadata
            },
            { title = '━━━ INFORMATION ━━━', disabled = true },
            {
                title = '📖 Workout Benefits',
                description = 'Learn about stat bonuses',
                icon = 'info-circle',
                arrow = true,
                onSelect = function()
                    lib.showContext('gym_benefits_menu')
                end
            },
            {
                title = '🏋️ Equipment Guide',
                description = 'Learn about gym equipment',
                icon = 'dumbbell',
                arrow = true,
                onSelect = function()
                    lib.showContext('gym_equipment_menu')
                end
            },
            {
                title = '🎮 Controls & Commands',
                description = 'Keyboard shortcuts',
                icon = 'keyboard',
                metadata = {
                    { label = 'Open Gym Menu', value = 'F7 or /gym' },
                    { label = 'Check Pass', value = '/gympass' },
                    { label = 'Quick Stats', value = '/mystats' }
                }
            }
        }
    })

    lib.registerContext({
        id = 'gym_benefits_menu',
        title = '📖 Workout Benefits',
        menu = 'gym_main_menu',
        options = {
            {
                title = '💪 Strength Benefits',
                description = 'Increased melee damage',
                icon = 'fist-raised',
                metadata = {
                    { label = 'Level 10+', value = '+10% damage' },
                    { label = 'Level 25+', value = '+20% damage' },
                    { label = 'Level 50+', value = '+35% damage' },
                    { label = 'Level 75+', value = '+50% damage' },
                    { label = 'Level 100', value = '+100% damage' }
                }
            },
            {
                title = '🏃 Stamina Benefits',
                description = 'Enhanced sprint capabilities',
                icon = 'running',
                metadata = {
                    { label = 'Level 10+', value = '+5% speed' },
                    { label = 'Level 25+', value = '+10% speed' },
                    { label = 'Level 50+', value = '+20% speed' },
                    { label = 'Level 75+', value = '+35% speed' },
                    { label = 'Level 100', value = '+49% speed' }
                }
            },
            {
                title = '🎯 Training Tips',
                description = 'Maximize your gains',
                icon = 'lightbulb',
                metadata = {
                    { label = 'Tip 1', value = 'Complete skill checks for bonus gains' },
                    { label = 'Tip 2', value = 'Harder exercises = more progress' },
                    { label = 'Tip 3', value = 'Rest between workouts (30s cooldown)' },
                    { label = 'Tip 4', value = 'Daily workouts increase gains' }
                }
            }
        }
    })

    lib.registerContext({
        id = 'gym_equipment_menu',
        title = '🏋️ Equipment Guide',
        menu = 'gym_main_menu',
        options = {
            {
                title = '🏃 Treadmill',
                description = 'Cardio equipment for stamina',
                metadata = {
                    { label = 'Trains', value = 'Stamina' },
                    { label = 'Difficulty', value = 'Easy' },
                    { label = 'Duration', value = '15 seconds' }
                }
            },
            {
                title = '💪 Dumbbells',
                description = 'Free weights for strength',
                metadata = {
                    { label = 'Trains', value = 'Strength' },
                    { label = 'Difficulty', value = 'Medium' },
                    { label = 'Duration', value = '8 seconds' }
                }
            },
            {
                title = '🤸 Chin-ups',
                description = 'Bodyweight exercise',
                metadata = {
                    { label = 'Trains', value = 'Strength' },
                    { label = 'Difficulty', value = 'Hard' },
                    { label = 'Duration', value = '10 seconds' }
                }
            },
            {
                title = '🏋️ Bench Press',
                description = 'Compound strength exercise',
                metadata = {
                    { label = 'Trains', value = 'Strength' },
                    { label = 'Difficulty', value = 'Medium' },
                    { label = 'Duration', value = '8 seconds' }
                }
            }
        }
    })

    lib.showContext('gym_main_menu')
end

RegisterNetEvent('qb-gym:client:testBoost', function(stat, value, duration)
    -- Validate stat type
    if stat ~= 'strength' and stat ~= 'stamina' then
        lib.notify({ type = 'error', description = 'Invalid stat. Use strength or stamina' })
        return
    end

    -- Validate value
    if value < 0 or value > 100 then
        lib.notify({ type = 'error', description = 'Value must be between 0 and 100' })
        return
    end

    exports['qb-gym']:ApplyTemporaryModifier(stat, value, duration)

    lib.notify({
        type = 'success',
        description = string.format('+%d %s boost for %d seconds', value, stat, duration),
        icon = 'bolt'
    })
end)

RegisterCommand('gym', function()
    if GetGameTimer() - lastUsed < 1000 then return end
    lastUsed = GetGameTimer()
    openGymMenu()
end)

RegisterKeyMapping('gym', 'Open Gym Menu', 'keyboard', 'F7')

RegisterCommand('mystats', function()
    local metadata = getPlayerMetadata()
    local strength = metadata.strength or 0
    local stamina = metadata.stamina or 0

    lib.notify({
        type = 'info',
        title = 'Your Gym Stats',
        description = string.format('Strength: %d | Stamina: %d', strength, stamina),
        duration = 5000,
        position = 'top-right'
    })
end)

RegisterCommand('gympass', function()
    local playerData = getPlayerData()
    if not playerData then return end

    -- Get fresh items once
    local items = exports['qb-core']:GetPlayerData().items or {}
    local passItem = nil

    for _, item in pairs(items) do
        if item.name == Config.GymPassItem then
            passItem = item
            break
        end
    end

    if passItem then
        -- Show pass info
        if passItem.info and passItem.info.expires then
            local now = exports['qb-gym']:GetServerTime()
            local timeLeft = passItem.info.expires - now
            if timeLeft > 0 then
                local days = math.floor(timeLeft / 86400)
                local hours = math.floor((timeLeft % 86400) / 3600)
                lib.notify({
                    type = 'success',
                    description = ('Gym pass active! Expires in %d days, %d hours'):format(days, hours)
                })
            else
                lib.notify({
                    type = 'warning',
                    description = 'Your gym pass has expired!'
                })
            end
        else
            lib.notify({
                type = 'success',
                description = 'You have an active gym pass!'
            })
        end

        -- Show stats
        local strength = playerData.metadata.strength or 0
        local stamina = playerData.metadata.stamina or 0
        lib.notify({
            type = 'info',
            description = ('Strength: %d | Stamina: %d'):format(strength, stamina)
        })
    else
        lib.notify({
            type = 'error',
            description = 'No gym pass. Visit the gym reception!'
        })
    end
end)

CreateThread(function()
    Wait(1000)
    cachedPlayerData = exports['qb-core']:GetPlayerData()
end)