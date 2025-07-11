local cachedMetadata = {}

local function ApplyStatEffects()
    local player = PlayerPedId()
    local stamina = cachedMetadata.stamina or 0
    local strength = cachedMetadata.strength or 0

    -- Apply sprint boost
    local sprintMultiplier = math.min(1.0 + (stamina * 0.005), 1.49)
    SetRunSprintMultiplierForPlayer(PlayerId(), sprintMultiplier)

    -- Apply melee buff
    if strength >= 20 then
        SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.5)
    elseif strength >= 10 then
        SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.2)
    else
        SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.0)
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    cachedMetadata = exports['qb-core']:GetPlayerData().metadata
    ApplyStatEffects()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if data.metadata then
        cachedMetadata = data.metadata
        ApplyStatEffects()
    end
end)

-- Initial check if player is already loaded
CreateThread(function()
    local playerData = exports['qb-core']:GetPlayerData()
    if playerData and playerData.metadata then
        cachedMetadata = playerData.metadata
        ApplyStatEffects()
    end
end)
