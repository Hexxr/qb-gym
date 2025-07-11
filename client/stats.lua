local cachedMetadata = {}
local statsApplied = false

local function GetStatEffect(stat, value, effectsTable)
    local effect = nil
    for threshold, data in pairs(effectsTable) do
        if value >= threshold and (not effect or threshold > effect.threshold) then
            effect = { threshold = threshold, data = data }
        end
    end
    return effect and effect.data or nil
end

local function ApplyStatEffects()
    local player = PlayerPedId()
    local playerId = PlayerId()
    local stamina = cachedMetadata.stamina or 0
    local strength = cachedMetadata.strength or 0

    -- Apply stamina effects
    local staminaEffect = GetStatEffect('stamina', stamina, Config.StaminaEffects)
    if staminaEffect then
        SetRunSprintMultiplierForPlayer(playerId, staminaEffect.sprintMultiplier)
    else
        SetRunSprintMultiplierForPlayer(playerId, 1.0)
    end

    -- Apply strength effects
    local strengthEffect = GetStatEffect('strength', strength, Config.StrengthEffects)
    if strengthEffect then
        SetPlayerMeleeWeaponDamageModifier(playerId, strengthEffect.meleeDamage)
    else
        SetPlayerMeleeWeaponDamageModifier(playerId, 1.0)
    end

    statsApplied = true
end

-- Optimized stat update detection
local function OnStatsUpdate(newMetadata)
    local needsUpdate = false

    -- Check if stamina changed
    if newMetadata.stamina ~= cachedMetadata.stamina then
        needsUpdate = true
    end

    -- Check if strength changed
    if newMetadata.strength ~= cachedMetadata.strength then
        needsUpdate = true
    end

    if needsUpdate then
        cachedMetadata = newMetadata
        ApplyStatEffects()
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local playerData = exports['qb-core']:GetPlayerData()
    if playerData and playerData.metadata then
        cachedMetadata = playerData.metadata
        ApplyStatEffects()
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if data.metadata then
        OnStatsUpdate(data.metadata)
    end
end)

-- Initial check with delay
CreateThread(function()
    Wait(1000) -- Wait for everything to initialize

    local playerData = exports['qb-core']:GetPlayerData()
    if playerData and playerData.metadata then
        cachedMetadata = playerData.metadata
        ApplyStatEffects()
    end
end)

-- Ensure stats persist through respawn
AddEventHandler('playerSpawned', function()
    if statsApplied and cachedMetadata then
        Wait(500) -- Small delay for spawn
        ApplyStatEffects()
    end
end)

-- Debug command
RegisterCommand('mystats', function()
    print('Current Gym Stats:')
    print('Strength:', cachedMetadata.strength or 0)
    print('Stamina:', cachedMetadata.stamina or 0)

    lib.notify({
        type = 'info',
        description = string.format('STR: %d | STA: %d',
            cachedMetadata.strength or 0,
            cachedMetadata.stamina or 0
        )
    })
end)