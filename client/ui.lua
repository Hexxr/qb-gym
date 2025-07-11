RegisterCommand("checkfitness", function()
    local metadata = exports['qb-core']:GetPlayerData().metadata
    local strength = metadata.strength or 0
    local stamina = metadata.stamina or 0

    lib.registerContext({
        id = 'gym_stats_menu',
        title = '🏋️ Your Gym Stats',
        options = {
            {
                title = '💪 Strength: ' .. strength,
                disabled = true
            },
            {
                title = '🏃 Stamina: ' .. stamina,
                disabled = true
            }
        }
    })

    lib.showContext('gym_stats_menu')
end)

RegisterCommand("gymmenu", function()
    lib.registerContext({
        id = 'gym_main_menu',
        title = 'Gym Menu',
        options = {
            {
                title = 'Check Fitness Stats',
                icon = '📊',
                onSelect = function()
                    ExecuteCommand("checkfitness")
                end
            }
        }
    })
    lib.showContext('gym_main_menu')
end)