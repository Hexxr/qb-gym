local function getPlayerMetadata()
    local player = cachedPlayerData or exports['qb-core']:GetPlayerData()
    return player and player.metadata or {}
end

local function getPlayerData()
    return exports['qb-core']:GetPlayerData() or {}
end

local function getStatBar(value, maxValue)
    local percentage = (value / maxValue) * 100
    local filled = math.floor(percentage / 10)
    local empty = 10 - filled
    return string.rep("█", filled) .. string.rep("░", empty)
end

local function getStatDescription(stat, value)
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
end

-- Cache player data to avoid repeated exports calls
local cachedPlayerData = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    cachedPlayerData = exports['qb-core']:GetPlayerData()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    local oldData = cachedPlayerData
    cachedPlayerData = data
    
    -- Check for stat increases
    if not data.metadata or not oldData or not oldData.metadata then return end
    
    if data.metadata.strength and data.metadata.strength > (oldData.metadata.strength or 0) then
        lib.notify({
            title = 'Strength Increased!',
            description = ('Level %d → %d'):format(oldData.metadata.strength or 0, data.metadata.strength),
            type = 'success',
            position = 'top',
            duration = 5000,
            icon = 'dumbbell'
        })
        
        -- Play sound effect
        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
    end
    
    if data.metadata.stamina and data.metadata.stamina > (oldData.metadata.stamina or 0) then
        lib.notify({
            title = 'Stamina Increased!',
            description = ('Level %d → %d'):format(oldData.metadata.stamina or 0, data.metadata.stamina),
            type = 'success',
            position = 'top',
            duration = 5000,
            icon = 'running'
        })
        
        -- Play sound effect
        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
    end
end)

RegisterCommand("checkfitness", function()
    local metadata = getPlayerMetadata()
    if not metadata then
        return lib.notify({ 
            type = 'error', 
            description = 'Player data not available',
            icon = 'triangle-exclamation' 
        })
    end

    local strength = metadata.strength or 0
    local stamina = metadata.stamina or 0
    local maxStat = Config.MaxStatLevel or 100

    lib.registerContext({
        id = 'gym_stats_menu',
        title = '🏋️ Fitness Statistics',
        options = {
            {
                title = 'Strength Level',
                description = getStatDescription('strength', strength),
                progress = strength,
                colorScheme = 'red',
                metadata = {
                    { label = 'Level', value = strength .. '/' .. maxStat },
                    { label = 'Progress', value = getStatBar(strength, maxStat) },
                    { label = 'Melee Bonus', value = '+' .. math.floor((strength / 10) * 10) .. '%' }
                }
            },
            {
                title = 'Stamina Level',
                description = getStatDescription('stamina', stamina),
                progress = stamina,
                colorScheme = 'blue',
                metadata = {
                    { label = 'Level', value = stamina .. '/' .. maxStat },
                    { label = 'Progress', value = getStatBar(stamina, maxStat) },
                    { label = 'Sprint Bonus', value = '+' .. math.floor((stamina / 10) * 5) .. '%' }
                }
            },
            {
                title = 'Workout Streak',
                description = '🔥 Keep up the momentum!',
                metadata = {
                    { label = 'Last Workout', value = metadata.lastWorkout or 'Never' },
                    { label = 'Total Sessions', value = metadata.totalWorkouts or 0 }
                }
            },
            {
                title = '',
                description = '🏃 Visit the gym to improve your stats!',
                disabled = true
            }
        }
    })

    lib.showContext('gym_stats_menu')
end)

RegisterCommand("gymmenu", function()
    local player = cachedPlayerData or exports['qb-core']:GetPlayerData()
    if not player then return end

    local metadata = getPlayerMetadata()
    local items = getPlayerData().items or {}
    local strength = metadata.strength or 0
    local stamina = metadata.stamina or 0
    local hasPass = false
    local passInfo = nil

    for _, item in pairs(items) do
        if item.name == Config.GymPassItem then
            hasPass = true
            passInfo = item.info or {}
            break
        end
    end

    lib.registerContext({
        id = 'gym_main_menu',
        title = '💪 Muscle Beach Gym',
        options = {
            {
                title = '📊 Check Fitness Stats',
                description = 'View your current progress',
                icon = 'chart-bar',
                arrow = true,
                onSelect = function() ExecuteCommand("checkfitness") end
            },
            {
                title = '🎫 Gym Membership',
                description = hasPass and '✅ Active Membership' or '❌ No Membership',
                icon = 'id-card',
                disabled = true,
                metadata = hasPass and {
                    { label = 'Status', value = 'Active' },
                    { label = 'Expires', value = passInfo.expires and os.date('%m/%d/%Y', passInfo.expires) or 'Never' }
                } or {
                    { label = 'Status', value = 'Inactive' },
                    { label = 'Price', value = '$' .. Config.GymPassPrice }
                }
            },
            {
                title = '📖 Workout Benefits',
                description = 'Learn about stat bonuses',
                icon = 'info-circle',
                arrow = true,
                onSelect = function()
                    lib.registerContext({
                        id = 'gym_benefits_menu',
                        title = '📖 Workout Benefits',
                        menu = 'gym_main_menu',
                        options = {
                            {
                                title = '💪 Strength Benefits',
                                description = 'More melee power',
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
                                description = 'Longer sprint duration',
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
                                    { label = 'Tip 3', value = 'Rest between workouts (30s cooldown)' }
                                }
                            }
                        }
                    })
                    lib.showContext('gym_benefits_menu')
                end
            },
            {
                title = '🏆 Quick Stats',
                description = ('STR: %d | STA: %d'):format(strength, stamina),
                icon = 'trophy',
                disabled = true
            },
            {
                title = '🎮 Controls',
                description = 'Keyboard shortcuts',
                icon = 'keyboard',
                metadata = {
                    { label = 'Stats Menu', value = 'F7' },
                    { label = 'Gym Menu', value = '/gymmenu' }
                }
            }
        }
    })

    lib.showContext('gym_main_menu')
end)

-- Keybind for quick stats
RegisterKeyMapping('checkfitness', 'Check Fitness Stats', 'keyboard', 'F7')

-- Add a command alias for convenience
RegisterCommand('fitness', function()
    ExecuteCommand('checkfitness')
end)

RegisterCommand('gym', function()
    ExecuteCommand('gymmenu')
end)

-- Initial data cache on resource start
CreateThread(function()
    Wait(1000) -- Wait for framework to initialize
    cachedPlayerData = exports['qb-core']:GetPlayerData()
end)