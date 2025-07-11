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
        else return "💪 Weak"
        end
    elseif stat == 'stamina' then
        if value >= 90 then return "🏃 Marathon Runner"
        elseif value >= 70 then return "🏃 Athlete"
        elseif value >= 50 then return "🏃 Active"
        elseif value >= 30 then return "🏃 Healthy"
        elseif value >= 10 then return "🏃 Average"
        else return "🏃 Out of Shape"
        end
    end
end

RegisterCommand("checkfitness", function()
    local metadata = exports['qb-core']:GetPlayerData().metadata
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
                    {label = 'Level', value = strength .. '/' .. maxStat},
                    {label = 'Progress', value = getStatBar(strength, maxStat)},
                    {label = 'Melee Bonus', value = '+' .. math.floor((strength / 10) * 10) .. '%'}
                }
            },
            {
                title = 'Stamina Level',
                description = getStatDescription('stamina', stamina),
                progress = stamina,
                colorScheme = 'blue',
                metadata = {
                    {label = 'Level', value = stamina .. '/' .. maxStat},
                    {label = 'Progress', value = getStatBar(stamina, maxStat)},
                    {label = 'Sprint Bonus', value = '+' .. math.floor((stamina / 10) * 5) .. '%'}
                }
            },
            {
                title = '',
                description = 'Visit the gym regularly to improve your stats!',
                disabled = true
            }
        }
    })

    lib.showContext('gym_stats_menu')
end)

RegisterCommand("gymmenu", function()
    local metadata = exports['qb-core']:GetPlayerData().metadata
    local strength = metadata.strength or 0
    local stamina = metadata.stamina or 0
    local hasPass = false

    -- Check for gym pass
    local items = exports['qb-core']:GetPlayerData().items
    for _, item in pairs(items or {}) do
        if item.name == Config.GymPassItem then
            hasPass = true
            break
        end
    end

    lib.registerContext({
        id = 'gym_main_menu',
        title = '💪 Muscle Beach Gym',
        options = {
            {
                title = 'Check Fitness Stats',
                description = 'View your current strength and stamina levels',
                icon = '📊',
                arrow = true,
                onSelect = function()
                    ExecuteCommand("checkfitness")
                end
            },
            {
                title = 'Gym Membership',
                description = hasPass and '✅ Active Membership' or '❌ No Membership',
                icon = '🎫',
                disabled = true,
                metadata = hasPass and {
                    {label = 'Status', value = 'Active'},
                } or {
                    {label = 'Status', value = 'Inactive'},
                    {label = 'Price', value = '$' .. Config.GymPassPrice}
                }
            },
            {
                title = 'Workout Benefits',
                description = 'Learn about stat benefits',
                icon = '📖',
                arrow = true,
                onSelect = function()
                    lib.registerContext({
                        id = 'gym_benefits_menu',
                        title = '📖 Workout Benefits',
                        menu = 'gym_main_menu',
                        options = {
                            {
                                title = '💪 Strength Benefits',
                                description = 'Increased melee damage',
                                metadata = {
                                    {label = 'Level 10+', value = '+10% damage'},
                                    {label = 'Level 25+', value = '+20% damage'},
                                    {label = 'Level 50+', value = '+35% damage'},
                                    {label = 'Level 75+', value = '+50% damage'},
                                    {label = 'Level 100', value = '+100% damage'}
                                }
                            },
                            {
                                title = '🏃 Stamina Benefits',
                                description = 'Increased sprint speed',
                                metadata = {
                                    {label = 'Level 10+', value = '+5% speed'},
                                    {label = 'Level 25+', value = '+10% speed'},
                                    {label = 'Level 50+', value = '+20% speed'},
                                    {label = 'Level 75+', value = '+35% speed'},
                                    {label = 'Level 100', value = '+49% speed'}
                                }
                            }
                        }
                    })
                    lib.showContext('gym_benefits_menu')
                end
            },
            {
                title = 'Quick Stats',
                description = ('STR: %d | STA: %d'):format(strength, stamina),
                icon = '🏆',
                disabled = true
            }
        }
    })
    lib.showContext('gym_main_menu')
end)

-- Keybind for quick stats
RegisterKeyMapping('checkfitness', 'Check Fitness Stats', 'keyboard', 'F7')

-- Auto-save notification when stats increase
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if data.metadata then
        local oldData = exports['qb-core']:GetPlayerData().metadata

        if oldData.strength and data.metadata.strength and data.metadata.strength > oldData.strength then
            lib.notify({
                title = 'Strength Increased!',
                description = ('Level %d → %d'):format(oldData.strength, data.metadata.strength),
                type = 'success',
                position = 'top',
                duration = 5000
            })
        end

        if oldData.stamina and data.metadata.stamina and data.metadata.stamina > oldData.stamina then
            lib.notify({
                title = 'Stamina Increased!',
                description = ('Level %d → %d'):format(oldData.stamina, data.metadata.stamina),
                type = 'success',
                position = 'top',
                duration = 5000
            })
        end
    end
end)