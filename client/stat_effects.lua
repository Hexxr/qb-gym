StatEffects = {}

local function GetStatEffect(stat, value, effectsTable)
    if not effectsTable then return nil end

    local effect = nil
    for threshold, data in pairs(effectsTable) do
        if value >= threshold and (not effect or threshold > effect.threshold) then
            effect = { threshold = threshold, data = data }
        end
    end
    return effect and effect.data or nil
end

local function ApplyStaminaEffect(stamina, playerId)
    local staminaEffect = GetStatEffect('stamina', stamina, Config.StaminaEffects)
    if staminaEffect then
        SetRunSprintMultiplierForPlayer(playerId, staminaEffect.sprintMultiplier)
        if staminaEffect.staminaRegen then
            RestorePlayerStamina(playerId, staminaEffect.staminaRegen)
        end
    else
        SetRunSprintMultiplierForPlayer(playerId, 1.0)
    end
end

local function ApplyStrengthEffect(strength, playerId)
    local strengthEffect = GetStatEffect('strength', strength, Config.StrengthEffects)
    if strengthEffect then
        SetPlayerMeleeWeaponDamageModifier(playerId, strengthEffect.meleeDamage)

        if strengthEffect.punchForce then
            CreateThread(function()
                local duration = strengthEffect.duration or 5000
                local interval = 500 -- check every half second
                local endTime = GetGameTimer() + duration
                while GetGameTimer() < endTime do
                    SetWeaponDamageModifierThisFrame(joaat(`WEAPON_UNARMED`), strengthEffect.punchForce)
                    Wait(interval)
                end
            end)
        end
    else
        SetPlayerMeleeWeaponDamageModifier(playerId, 1.0)
    end
end

exports('GetStatEffect', GetStatEffect)
exports('ApplyStrengthEffect', ApplyStrengthEffect)
exports('ApplyStaminaEffect', ApplyStaminaEffect)
