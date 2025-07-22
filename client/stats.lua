local cachedMetadata = {}
local statsApplied = false
local statModifiers = {} -- Track temporary modifiers
local activeTimeouts = {} -- Track active timeouts for cleanup

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
    StatSetInt(GetHashKey('MP0_STAMINA'), math.floor(stamina), true)
    StatSetInt(GetHashKey('MP0_STRENGTH'), math.floor(strength), true)
    StatSetInt(GetHashKey('MP0_LUNG_CAPACITY'), math.floor(stamina), true)

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
    if newMetadata.stamina ~= cachedMetadata.stamina or
       newMetadata.strength ~= cachedMetadata.strength then
        cachedMetadata = newMetadata
        DebouncedApplyEffects()
    end
end

-- Temporary stat modifiers
local function ApplyTemporaryModifier(stat, value, duration)
    if not stat or not value then return end

    -- Cancel existing timeout for this stat
    if activeTimeouts[stat] then
        activeTimeouts[stat].cancelled = true  -- Flag as cancelled
    end

    statModifiers[stat] = (statModifiers[stat] or 0) + value
    DebouncedApplyEffects()

    if duration and duration > 0 then
        local timeoutData = { cancelled = false }
        activeTimeouts[stat] = timeoutData

        SetTimeout(duration * 1000, function()
            if not timeoutData.cancelled then  -- Check if cancelled
                statModifiers[stat] = (statModifiers[stat] or 0) - value
                activeTimeouts[stat] = nil
                DebouncedApplyEffects()

                lib.notify({
                    type = 'info',
                    description = string.format('%s boost expired', stat:gsub("^%l", string.upper)),
                    icon = 'clock'
                })
            end
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
local function getTier(level)
    if level >= 90 then return 3
    elseif level >= 70 then return 2
    elseif level >= 50 then return 1
    else return 0 end
end

local currentTier = 0
local lastStaminaTier = 0

CreateThread(function()
    while true do
        local sleep = 2000
        local ped = PlayerPedId()
        local strength = (cachedMetadata and cachedMetadata.strength) or 0
        local stamina = (cachedMetadata and cachedMetadata.stamina) or 0

        local newTier = getTier(strength)
        local tierChanged = newTier ~= currentTier

        if tierChanged then
            local oldTier = currentTier  -- Store old tier for comparison
            currentTier = newTier

            -- Load clipsets before using them
            if newTier > 0 then
                local clipset = nil
                if newTier == 1 then
                    clipset = 'move_m@brave'
                elseif newTier == 2 then
                    clipset = 'move_m@muscle@a'
                elseif newTier == 3 then
                    clipset = 'move_m@muscle@a'
                end

                if clipset then
                    lib.requestAnimSet(clipset)
                    SetPedMovementClipset(ped, clipset, 0.25)
                end

                SetPedConfigFlag(ped, 187, true)
            else
                -- Tier 0 - reset to default
                ResetPedMovementClipset(ped, 0.5)
                SetPedConfigFlag(ped, 187, false)
            end

            -- Visual notification of change
            if newTier > oldTier then
                lib.notify({
                    title = 'Physical Prowess',
                    description = 'You feel stronger!',
                    type = 'success',
                    icon = 'dumbbell',
                    duration = 3000
                })
            end
        end

        -- Enhanced stamina effects
        local staminaTier = getTier(stamina)
        if staminaTier ~= lastStaminaTier then
            lastStaminaTier = staminaTier

            if staminaTier >= 3 then
                -- Elite athlete breathing
                StatSetInt(GetHashKey('MP0_STAMINA'), 100, true)
                StatSetInt(GetHashKey('MP0_LUNG_CAPACITY'), 100, true)
            elseif staminaTier >= 2 then
                StatSetInt(GetHashKey('MP0_LUNG_CAPACITY'), 80, true)
            end
        end

        -- Dynamic stamina regen based on tier
        if stamina >= 90 and IsPedSprinting(ped) then
            RestorePlayerStamina(PlayerId(), 1.0)
            sleep = 500 -- Check more often during sprint
        elseif stamina >= 70 then
            RestorePlayerStamina(PlayerId(), 0.5)
        end

        Wait(sleep)
    end
end)

-- Cleanup on player unload or resource stop
local function cleanup()
    currentTier = 0
    lastStaminaTier = 0
    local ped = PlayerPedId()
    ResetPedMovementClipset(ped, 0.5)
    SetPedConfigFlag(ped, 187, false)
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', cleanup)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Cancel all active timeouts
    for _, timeoutData in pairs(activeTimeouts) do
        if timeoutData then
            timeoutData.cancelled = true
        end
    end
    activeTimeouts = {}

    -- Reset visual effects
    cleanup()

    -- Reset stat modifiers
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.0)
end)