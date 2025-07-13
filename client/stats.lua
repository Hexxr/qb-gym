local cachedMetadata = {}
local statsApplied = false
local statModifiers = {} -- Track temporary modifiers

-- Localize frequently used functions for performance
local PlayerPedId = PlayerPedId
local PlayerId = PlayerId
local SetRunSprintMultiplierForPlayer = SetRunSprintMultiplierForPlayer
local SetPlayerMeleeWeaponDamageModifier = SetPlayerMeleeWeaponDamageModifier
local StatSetInt = StatSetInt
local Wait = Wait

local function ApplyStatEffects()
    local playerId = PlayerId()

    local stamina = cachedMetadata.stamina or 0
    local strength = cachedMetadata.strength or 0

    stamina = stamina + (statModifiers.stamina or 0)
    strength = strength + (statModifiers.strength or 0)

    stamina = math.max(0, math.min(stamina, Config.MaxStatLevel or 100))
    strength = math.max(0, math.min(strength, Config.MaxStatLevel or 100))

    -- exports for modifiers
    exports['qb-gym']:ApplyStaminaEffect(stamina, playerId)
    exports['qb-gym']:ApplyStrengthEffect(strength, playerId)

    -- GTA stat bars
    StatSetInt(`MP0_STAMINA`, math.floor(stamina), true)
    StatSetInt(`MP0_STRENGTH`, math.floor(strength), true)
    StatSetInt(`MP0_LUNG_CAPACITY`, math.floor(stamina), true)

    statsApplied = true

    TriggerEvent('gym:client:statsUpdated', {
        strength = strength,
        stamina = stamina,
        modifiers = statModifiers
    })
end


local function DebouncedApplyEffects()
    CreateThread(function()
        for _ = 1, 5 do
            Wait(1000)
            if cachedMetadata then
                ApplyStatEffects()
                break
            end
        end
    end)
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
        DebouncedApplyEffects()
    end
end

-- Temporary stat modifiers (for consumables, etc.)
local function ApplyTemporaryModifier(stat, value, duration)
    if not stat or not value then return end

    statModifiers[stat] = (statModifiers[stat] or 0) + value
    DebouncedApplyEffects()

    if duration and duration > 0 then
        SetTimeout(duration * 1000, function()
            statModifiers[stat] = (statModifiers[stat] or 0) - value
            DebouncedApplyEffects()

            lib.notify({
                type = 'info',
                description = string.format('%s boost expired', stat:gsub("^%l", string.upper)),
                icon = 'clock'
            })
        end)
    end
end

-- Export for other resources
exports('ApplyTemporaryModifier', ApplyTemporaryModifier)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local playerData = exports['qb-core']:GetPlayerData()
    if playerData and playerData.metadata then
        cachedMetadata = playerData.metadata
        DebouncedApplyEffects()
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if data.metadata then
        OnStatsUpdate(data.metadata)
        DebouncedApplyEffects()
    end
end)

-- Initial check with delay
CreateThread(function()
    Wait(1000) -- Wait for everything to initialize

    local playerData = exports['qb-core']:GetPlayerData()
    if playerData and playerData.metadata then
        cachedMetadata = playerData.metadata
        DebouncedApplyEffects()
    end
end)

-- Ensure stats persist through respawn
AddEventHandler('playerSpawned', function()
    if statsApplied and cachedMetadata then
        Wait(500) -- Small delay for spawn
        DebouncedApplyEffects()
    end
end)

-- Handle stat degradation over time
if Config.EnableStatDegradation then
    CreateThread(function()
        while true do
            Wait(Config.DegradationInterval or 3600000) -- Default 1 hour

            if cachedMetadata.strength and cachedMetadata.strength > 0 then
                local newStrength = math.max(0, cachedMetadata.strength - (Config.StrengthDegradation or 1))
                TriggerServerEvent('gym:server:updateStat', 'strength', newStrength)
            end

            if cachedMetadata.stamina and cachedMetadata.stamina > 0 then
                local newStamina = math.max(0, cachedMetadata.stamina - (Config.StaminaDegradation or 1))
                TriggerServerEvent('gym:server:updateStat', 'stamina', newStamina)
            end
        end
    end)
end

-- Visual feedback for high stats
CreateThread(function()
    while true do
        local sleep = 1000

        if cachedMetadata.strength and cachedMetadata.strength >= 50 then
            sleep = 500
            -- Add subtle muscle definition effect
            if IsPedRunning(PlayerPedId()) or IsPedSprinting(PlayerPedId()) then
                -- will add particle effects or other visual feedback here
            end
        end

        Wait(sleep)
    end
end)

-- Debug commands
RegisterCommand('mystats', function()
    print('=== Current Gym Stats ===')
    print('Strength:', cachedMetadata.strength or 0)
    print('Stamina:', cachedMetadata.stamina or 0)
    print('Active Modifiers:', json.encode(statModifiers))

    local strengthEffect = exports['qb-gym']:GetStatEffect('strength', cachedMetadata.strength or 0, Config.StrengthEffects)
    local staminaEffect = exports['qb-gym']:GetStatEffect('stamina', cachedMetadata.stamina or 0, Config.StaminaEffects)

    lib.notify({
        type = 'info',
        title = 'Gym Stats',
        description = string.format('STR: %d | STA: %d',
            cachedMetadata.strength or 0,
            cachedMetadata.stamina or 0
        ),
        duration = 5000,
        position = 'top-right'
    })

    if strengthEffect or staminaEffect then
        Wait(100)
        lib.notify({
            type = 'info',
            title = 'Active Effects',
            description = string.format('Melee: +%d%% | Sprint: +%d%%',
                strengthEffect and math.floor((strengthEffect.meleeDamage - 1) * 100) or 0,
                staminaEffect and math.floor((staminaEffect.sprintMultiplier - 1) * 100) or 0
            ),
            duration = 5000,
            position = 'top-right'
        })
    end
end)

-- Test modifier command (for development)
RegisterCommand('testboost', function(source, args)
    local stat = args[1] or 'strength'
    local value = tonumber(args[2]) or 10
    local duration = tonumber(args[3]) or 30

    ApplyTemporaryModifier(stat, value, duration)

    lib.notify({
        type = 'success',
        description = string.format('+%d %s boost for %d seconds', value, stat, duration),
        icon = 'bolt'
    })
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Reset all stat modifiers
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.0)
end)
RegisterCommand('refreshstats', function()
    local playerData = exports['qb-core']:GetPlayerData()
    if playerData and playerData.metadata then
        cachedMetadata = playerData.metadata
        DebouncedApplyEffects()
        print("Stats manually refreshed")
    end
end)