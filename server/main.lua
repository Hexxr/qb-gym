RegisterServerEvent('qb-gym:buyPass', function()
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end

    local price = Config.GymPassPrice
    local item = Config.GymPassItem

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

    if not statType or (statType ~= 'strength' and statType ~= 'stamina') then
        print('Gym Reward: Invalid stat type from client!', statType)
        return
    end

    local current = Player.PlayerData.metadata[statType] or 0
    local newLevel = current + 1

    Player.Functions.SetMetaData(statType, newLevel)
    -- Optional: Add external logic for boosts when reaching level thresholds
end)